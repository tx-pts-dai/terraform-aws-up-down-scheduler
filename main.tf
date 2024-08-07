terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "2.5.0"
    }
  }
}

data "archive_file" "lambda_asg" {
  count       = var.asg_scheduler != {} ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda/ec2_asg/update_capacity"
  output_path = "${path.module}/lambda/ec2_asg/update_capacity/package.zip"
}

resource "aws_lambda_function" "lambda_asg" {
  count            = var.asg_scheduler.asg_name != "" ? 1 : 0
  function_name    = "ec2-asg-scheduler-${random_integer.random_number.result}"
  filename         = data.archive_file.lambda_asg[0].output_path
  source_code_hash = filebase64sha256(data.archive_file.lambda_asg[0].output_path)
  handler          = "main.lambda_handler"
  runtime          = "python3.8"
  role             = aws_iam_role.lambda_role.arn
}


resource "aws_cloudwatch_event_rule" "asg_downscale_scheduler_event" {
  count               = var.asg_scheduler.asg_name != "" ? 1 : 0
  name                = "asg-scheduler-downscale-event-${random_integer.random_number.result}"
  description         = "Event rule for ASG downscale scheduler"
  schedule_expression = var.asg_scheduler.downscale_cron_expression
}

resource "aws_cloudwatch_event_target" "asg_downscale_scheduler_target" {
  count     = var.asg_scheduler.asg_name != "" ? 1 : 0
  rule      = aws_cloudwatch_event_rule.asg_downscale_scheduler_event[0].name
  target_id = aws_lambda_function.lambda_asg[0].function_name
  arn       = aws_lambda_function.lambda_asg[0].arn
  input = jsonencode({
    asg_name         = var.asg_scheduler.asg_name
    desired_capacity = var.asg_scheduler.downscale_desired_capacity
  })
}

resource "aws_cloudwatch_event_rule" "asg_upscale_scheduler_event" {
  count               = var.asg_scheduler.asg_name != "" ? 1 : 0
  name                = "asg-scheduler-upsacale-event-${random_integer.random_number.result}"
  description         = "Event rule for ASG upscale scheduler"
  schedule_expression = var.asg_scheduler.upscale_cron_expression
}

resource "aws_cloudwatch_event_target" "asg_upscale_scheduler_target" {
  count     = var.asg_scheduler.asg_name != "" ? 1 : 0
  rule      = aws_cloudwatch_event_rule.asg_upscale_scheduler_event[0].name
  target_id = aws_lambda_function.lambda_asg[0].function_name
  arn       = aws_lambda_function.lambda_asg[0].arn
  input = jsonencode({
    asg_name         = var.asg_scheduler.asg_name
    desired_capacity = var.asg_scheduler.upscale_desired_capacity
  })
}

data "archive_file" "lambda_ec2_stop" {
  count       = var.ec2_stop_scheduler.cron_expression != "" ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda/ec2_simple/stop"
  output_path = "${path.module}/lambda/ec2_simple/stop/package.zip"
}

resource "aws_lambda_function" "lambda_ec2_stop" {
  count            = var.ec2_stop_scheduler.cron_expression != "" ? 1 : 0
  function_name    = "ec2-stop-scheduler-${random_integer.random_number.result}"
  filename         = data.archive_file.lambda_ec2_stop[0].output_path
  source_code_hash = filebase64sha256(data.archive_file.lambda_ec2_stop[0].output_path)
  handler          = "main.lambda_handler"
  runtime          = "python3.8"
  role             = aws_iam_role.lambda_role.arn
}

resource "aws_cloudwatch_event_rule" "ec2_stop_scheduler_event" {
  count               = var.ec2_stop_scheduler.cron_expression != "" ? 1 : 0
  name                = "ec2-start-scheduler-event-${random_integer.random_number.result}"
  description         = "Event rule for EC2 stop scheduler"
  schedule_expression = var.ec2_stop_scheduler.cron_expression
}

resource "aws_cloudwatch_event_target" "ec2_stop_scheduler_target" {
  count     = var.ec2_stop_scheduler.cron_expression != "" ? 1 : 0
  rule      = aws_cloudwatch_event_rule.ec2_stop_scheduler_event[0].name
  target_id = aws_lambda_function.lambda_ec2_stop[0].function_name
  arn       = aws_lambda_function.lambda_ec2_stop[0].arn
  input = jsonencode({
    instance_ids = var.ec2_stop_scheduler.instance_ids
  })
}

data "archive_file" "lambda_ec2_start" {
  count       = var.ec2_start_scheduler.cron_expression != "" ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda/ec2_simple/start"
  output_path = "${path.module}/lambda/ec2_simple/start/package.zip"
}

resource "aws_lambda_function" "lambda_ec2_start" {
  count            = var.ec2_start_scheduler.cron_expression != "" ? 1 : 0
  function_name    = "ec2-start-scheduler-${random_integer.random_number.result}"
  filename         = data.archive_file.lambda_ec2_start[0].output_path
  source_code_hash = filebase64sha256(data.archive_file.lambda_ec2_start[0].output_path)
  handler          = "main.lambda_handler"
  runtime          = "python3.8"
  role             = aws_iam_role.lambda_role.arn
}

resource "aws_cloudwatch_event_rule" "ec2_start_scheduler_event" {
  count               = var.ec2_start_scheduler.cron_expression != "" ? 1 : 0
  name                = "ec2-start-scheduler-event-${random_integer.random_number.result}"
  description         = "Event rule for EC2 start scheduler"
  schedule_expression = var.ec2_start_scheduler.cron_expression
}

resource "aws_cloudwatch_event_target" "ec2_start_scheduler_target" {
  count     = var.ec2_start_scheduler.cron_expression != "" ? 1 : 0
  rule      = aws_cloudwatch_event_rule.ec2_start_scheduler_event[0].name
  target_id = aws_lambda_function.lambda_ec2_start[0].function_name
  arn       = aws_lambda_function.lambda_ec2_start[0].arn
  input = jsonencode({
    instance_ids = var.ec2_start_scheduler.instance_ids
  })
}

resource "random_integer" "random_number" {
  min = 1000
  max = 9999
}

resource "aws_iam_role" "lambda_role" {
  name               = "ec2-scheduler-role-${random_integer.random_number.result}"
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
  name   = "ec2-scheduler-${random_integer.random_number.result}"
  policy = data.aws_iam_policy_document.ec2_scheduler_policy.json
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.ec2_scheduler_policy.arn
}
