terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

locals {
  create_basic_resources = var.ec2_start_scheduler != null || var.ec2_stop_scheduler != null || var.asg_scheduler != null
}

data "archive_file" "lambda_asg" {
  count       = var.asg_scheduler != null ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda/ec2_asg/update_capacity"
  output_path = "${path.module}/lambda/ec2_asg/update_capacity/package.zip"
}

resource "aws_lambda_function" "lambda_asg" {
  count            = var.asg_scheduler != null ? 1 : 0
  function_name    = "ec2-asg-scheduler-${random_id.this[0].id}"
  filename         = data.archive_file.lambda_asg[0].output_path
  source_code_hash = filebase64sha256(data.archive_file.lambda_asg[0].output_path)
  handler          = "main.lambda_handler"
  runtime          = "python3.8"
  role             = aws_iam_role.lambda_role[0].arn
  timeout          = 15
}


resource "aws_cloudwatch_event_rule" "asg_downscale_scheduler_event" {
  count               = var.asg_scheduler != null ? 1 : 0
  name                = "asg-scheduler-downscale-event-${random_id.this[0].id}"
  description         = "Event rule for ASG downscale scheduler"
  schedule_expression = var.asg_scheduler.downscale_cron_expression
}

resource "aws_cloudwatch_event_target" "asg_downscale_scheduler_target" {
  count     = var.asg_scheduler != null ? 1 : 0
  rule      = aws_cloudwatch_event_rule.asg_downscale_scheduler_event[0].name
  target_id = aws_lambda_function.lambda_asg[0].function_name
  arn       = aws_lambda_function.lambda_asg[0].arn
  input = jsonencode({
    asg_name         = var.asg_scheduler.asg_name
    desired_capacity = var.asg_scheduler.downscale_desired_capacity
  })
}

resource "aws_cloudwatch_event_rule" "asg_upscale_scheduler_event" {
  count               = var.asg_scheduler != null ? 1 : 0
  name                = "asg-scheduler-upscale-event-${random_id.this[0].id}"
  description         = "Event rule for ASG upscale scheduler"
  schedule_expression = var.asg_scheduler.upscale_cron_expression
}

resource "aws_cloudwatch_event_target" "asg_upscale_scheduler_target" {
  count     = var.asg_scheduler != null ? 1 : 0
  rule      = aws_cloudwatch_event_rule.asg_upscale_scheduler_event[0].name
  target_id = aws_lambda_function.lambda_asg[0].function_name
  arn       = aws_lambda_function.lambda_asg[0].arn
  input = jsonencode({
    asg_name         = var.asg_scheduler.asg_name
    desired_capacity = var.asg_scheduler.upscale_desired_capacity
  })
}

data "archive_file" "lambda_ec2_stop" {
  count       = var.ec2_stop_scheduler != null ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda/ec2_simple/stop"
  output_path = "${path.module}/lambda/ec2_simple/stop/package.zip"
}

resource "aws_lambda_function" "lambda_ec2_stop" {
  count            = var.ec2_stop_scheduler != null ? 1 : 0
  function_name    = "ec2-stop-scheduler-${random_id.this[0].id}"
  filename         = data.archive_file.lambda_ec2_stop[0].output_path
  source_code_hash = filebase64sha256(data.archive_file.lambda_ec2_stop[0].output_path)
  handler          = "main.lambda_handler"
  runtime          = "python3.8"
  role             = aws_iam_role.lambda_role[0].arn
  timeout          = 15
}

resource "aws_cloudwatch_event_rule" "ec2_stop_scheduler_event" {
  count               = var.ec2_stop_scheduler != null ? 1 : 0
  name                = "ec2-stop-scheduler-event-${random_id.this[0].id}"
  description         = "Event rule for EC2 stop scheduler"
  schedule_expression = var.ec2_stop_scheduler.cron_expression
}

resource "aws_cloudwatch_event_target" "ec2_stop_scheduler_target" {
  count     = var.ec2_stop_scheduler != null ? 1 : 0
  rule      = aws_cloudwatch_event_rule.ec2_stop_scheduler_event[0].name
  target_id = aws_lambda_function.lambda_ec2_stop[0].function_name
  arn       = aws_lambda_function.lambda_ec2_stop[0].arn
  input = jsonencode({
    instance_ids = var.ec2_stop_scheduler.instance_ids
  })
}

data "archive_file" "lambda_ec2_start" {
  count       = var.ec2_start_scheduler != null ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda/ec2_simple/start"
  output_path = "${path.module}/lambda/ec2_simple/start/package.zip"
}

resource "aws_lambda_function" "lambda_ec2_start" {
  count            = var.ec2_start_scheduler != null ? 1 : 0
  function_name    = "ec2-start-scheduler-${random_id.this[0].id}"
  filename         = data.archive_file.lambda_ec2_start[0].output_path
  source_code_hash = filebase64sha256(data.archive_file.lambda_ec2_start[0].output_path)
  handler          = "main.lambda_handler"
  runtime          = "python3.8"
  role             = aws_iam_role.lambda_role[0].arn
  timeout          = 15
}

resource "aws_cloudwatch_event_rule" "ec2_start_scheduler_event" {
  count               = var.ec2_start_scheduler != null ? 1 : 0
  name                = "ec2-start-scheduler-event-${random_id.this[0].id}"
  description         = "Event rule for EC2 start scheduler"
  schedule_expression = var.ec2_start_scheduler.cron_expression
}

resource "aws_cloudwatch_event_target" "ec2_start_scheduler_target" {
  count     = var.ec2_start_scheduler != null ? 1 : 0
  rule      = aws_cloudwatch_event_rule.ec2_start_scheduler_event[0].name
  target_id = aws_lambda_function.lambda_ec2_start[0].function_name
  arn       = aws_lambda_function.lambda_ec2_start[0].arn
  input = jsonencode({
    instance_ids = var.ec2_start_scheduler.instance_ids
  })
}

resource "random_id" "this" {
  count       = local.create_basic_resources ? 1 : 0
  byte_length = 4
}

resource "aws_iam_role" "lambda_role" {
  count              = local.create_basic_resources ? 1 : 0
  name               = "ec2-scheduler-role-${random_id.this[0].id}"
  assume_role_policy = data.aws_iam_policy_document.lambda_role_policy.json
}

data "aws_iam_policy_document" "lambda_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ec2_scheduler_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "ec2:DescribeInstances",
      "ec2:StartInstances",
      "ec2:StopInstances",
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:UpdateAutoScalingGroup",
      "autoscaling:DescribeAutoScalingInstances",
    ]
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "ec2_scheduler_policy" {
  count  = local.create_basic_resources ? 1 : 0
  name   = "ec2-scheduler-${random_id.this[0].id}"
  policy = data.aws_iam_policy_document.ec2_scheduler_policy.json
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  count      = local.create_basic_resources ? 1 : 0
  role       = aws_iam_role.lambda_role[0].name
  policy_arn = aws_iam_policy.ec2_scheduler_policy[0].arn
}

resource "aws_cloudwatch_log_group" "lambda_asg_log_group" {
  count = var.asg_scheduler != null ? 1 : 0
  name  = "/aws/lambda/ec2-asg-scheduler-${random_id.this[0].id}"
  retention_in_days = 14  
}

resource "aws_cloudwatch_log_group" "lambda_ec2_stop_log_group" {
  count = var.ec2_stop_scheduler != null ? 1 : 0
  name  = "/aws/lambda/ec2-stop-scheduler-${random_id.this[0].id}"
  retention_in_days = 14  
}

resource "aws_cloudwatch_log_group" "lambda_ec2_start_log_group" {
  count = var.ec2_start_scheduler != null ? 1 : 0
  name  = "/aws/lambda/ec2-start-scheduler-${random_id.this[0].id}"
  retention_in_days = 14  
}
