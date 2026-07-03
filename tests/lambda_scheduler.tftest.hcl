# Contract/smoke tests for the up/down scheduler module.
#
# AWS and random are mocked so the tests run offline with no credentials.
# The `archive` provider is intentionally NOT mocked so the real
# `archive_file` data sources zip the `lambda/` sources and
# `filebase64sha256(...)` computes a real hash — the same path a real plan
# takes.
#
# NOTE: these tests do not reproduce the working-directory `filename` drift
# fixed in FUM-4170. That drift only appears when Terraform is invoked from
# different data dirs (local checkout vs Atlantis `/tmp/terraform-data-dir/`),
# which `terraform test` cannot vary, so an idempotency check would pass with
# or without the `ignore_changes = [filename]` fix. These are contract tests
# that assert the module wires the Lambda functions up correctly.

# The mocked aws provider generates random strings for computed `arn`
# attributes, which fail the provider's ARN-format validation when they are
# fed into `role` / `policy_arn`. Provide valid mock ARNs for the IAM
# resources so the graph applies.
mock_provider "aws" {
  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/mock-role"
    }
  }
  mock_resource "aws_iam_policy" {
    defaults = {
      arn = "arn:aws:iam::123456789012:policy/mock-policy"
    }
  }
  mock_resource "aws_lambda_function" {
    defaults = {
      arn = "arn:aws:lambda:eu-central-1:123456789012:function:mock-fn"
    }
  }
}
mock_provider "random" {}

# The mocked aws provider also stubs the `aws_iam_policy_document` data
# sources, which would return empty `json` and fail the IAM policy JSON
# validation. Override them with valid (representative) policy JSON.
override_data {
  target = data.aws_iam_policy_document.lambda_role_policy
  values = {
    json = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect    = "Allow"
        Action    = "sts:AssumeRole"
        Principal = { Service = "lambda.amazonaws.com" }
      }]
    })
  }
}

override_data {
  target = data.aws_iam_policy_document.ec2_scheduler_policy
  values = {
    json = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect   = "Allow"
        Action   = ["ec2:StartInstances", "ec2:StopInstances"]
        Resource = "*"
      }]
    })
  }
}

# All three schedulers enabled -> all three Lambda functions exist and are
# configured with the expected runtime/handler and a real source_code_hash.
run "all_schedulers_enabled" {
  command = apply

  variables {
    asg_scheduler = {
      downscale_cron_expression  = "cron(0 19 * * ? *)"
      downscale_desired_capacity = 0
      upscale_cron_expression    = "cron(0 7 * * ? *)"
      upscale_desired_capacity   = 2
      asg_name                   = "my-asg"
      description                = "test asg scheduler"
    }
    ec2_stop_scheduler = {
      cron_expression = "cron(0 19 * * ? *)"
      instance_ids    = ["i-0123456789abcdef0"]
      description     = "test stop scheduler"
    }
    ec2_start_scheduler = {
      cron_expression = "cron(0 7 * * ? *)"
      instance_ids    = ["i-0123456789abcdef0"]
      description     = "test start scheduler"
    }
  }

  assert {
    condition     = length(aws_lambda_function.lambda_asg) == 1
    error_message = "asg Lambda should be created when asg_scheduler is set"
  }

  assert {
    condition     = length(aws_lambda_function.lambda_ec2_stop) == 1
    error_message = "ec2 stop Lambda should be created when ec2_stop_scheduler is set"
  }

  assert {
    condition     = length(aws_lambda_function.lambda_ec2_start) == 1
    error_message = "ec2 start Lambda should be created when ec2_start_scheduler is set"
  }

  assert {
    condition = alltrue([
      aws_lambda_function.lambda_asg[0].runtime == "python3.12",
      aws_lambda_function.lambda_ec2_stop[0].runtime == "python3.12",
      aws_lambda_function.lambda_ec2_start[0].runtime == "python3.12",
    ])
    error_message = "all Lambdas should use the python3.12 runtime"
  }

  assert {
    condition = alltrue([
      aws_lambda_function.lambda_asg[0].handler == "main.lambda_handler",
      aws_lambda_function.lambda_ec2_stop[0].handler == "main.lambda_handler",
      aws_lambda_function.lambda_ec2_start[0].handler == "main.lambda_handler",
    ])
    error_message = "all Lambdas should use the main.lambda_handler entrypoint"
  }

  # source_code_hash is what actually detects real code changes; it must be
  # populated from the archived package for every Lambda.
  assert {
    condition = alltrue([
      aws_lambda_function.lambda_asg[0].source_code_hash != "",
      aws_lambda_function.lambda_ec2_stop[0].source_code_hash != "",
      aws_lambda_function.lambda_ec2_start[0].source_code_hash != "",
    ])
    error_message = "all Lambdas should have a non-empty source_code_hash"
  }
}

# Only the ec2 stop scheduler enabled -> only that Lambda exists; the asg and
# start Lambdas are not created.
run "only_ec2_stop_enabled" {
  command = apply

  variables {
    ec2_stop_scheduler = {
      cron_expression = "cron(0 19 * * ? *)"
      instance_ids    = ["i-0123456789abcdef0"]
    }
  }

  assert {
    condition     = length(aws_lambda_function.lambda_ec2_stop) == 1
    error_message = "ec2 stop Lambda should be created when ec2_stop_scheduler is set"
  }

  assert {
    condition = alltrue([
      length(aws_lambda_function.lambda_asg) == 0,
      length(aws_lambda_function.lambda_ec2_start) == 0,
    ])
    error_message = "only the ec2 stop Lambda should exist when only ec2_stop_scheduler is set"
  }
}
