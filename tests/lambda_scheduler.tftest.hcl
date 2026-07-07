# aws/random are mocked so the suite runs offline; archive is left real so
# archive_file zips the lambda sources and source_code_hash is computed.

# Mock ARNs so the provider's ARN-format validation passes on role/policy_arn.
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

# Valid policy JSON so IAM policy validation passes (mocked docs return empty).
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

  assert {
    condition = alltrue([
      aws_lambda_function.lambda_asg[0].source_code_hash != "",
      aws_lambda_function.lambda_ec2_stop[0].source_code_hash != "",
      aws_lambda_function.lambda_ec2_start[0].source_code_hash != "",
    ])
    error_message = "all Lambdas should have a non-empty source_code_hash"
  }
}

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
