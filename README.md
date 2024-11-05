# Up Down scheduler

This Terraform module automates the scheduling of AWS Auto Scaling Group (ASG) scaling events and the start/stop scheduling of EC2 instances using AWS Lambda and Amazon CloudWatch Events. The module is designed to optimize resource management by automatically adjusting ASG capacities and controlling EC2 instance states based on predefined schedules.

## Remark
The EC2 stop function without ASG will not run on days that are previous of `patching_dates`. This ensures that instances are not stopped during a patching process. For EC2 instances with ASG, there are no such restrictions. `patching_dates` is optional.

## Usage

You can use the module two ways:

```hcl
module "ec2_start_stop_app_with_asg" {
  source        = "github.com/tx-pts-dai/terraform-aws-up-down-scheduler"
  version       = "~> 1.0"
  asg_scheduler = {
    downscale_cron_expression  = "0 17 * * MON-FRI"
    downscale_desired_capacity = 1
    upscale_cron_expression    = "0 8 * * MON-FRI"
    upscale_desired_capacity   = 2
    asg_name                   = "My-ASG-APP"
  }
}

module "ec2_start_stop_app_without_asg" {
  source              = "github.com/tx-pts-dai/terraform-aws-up-down-scheduler"
  version             = "~> 1.0"
  ec2_stop_scheduler  = {
    cron_expression = "0 17 * * MON-FRI"
    instance_ids    = ["i-xxxxxxxxxxxxx"]
    patching_dates  = ["2024-02-01", "2024-02-04", "2024-07-02", "2024-10-01"]
  }
  ec2_start_scheduler = {
    cron_expression = "0 8 * * MON-FRI"
    instance_ids    = ["i-xxxxxxxxxxxxx"]
  }
}
```

## Explanation and description of interesting use-cases

## Save money !
Don't spend useless money when your workloads are not used or are in stand by anyway. A good use case is stopping dev services during the night or scale less instances on internal applications that are accessed only during the day anyway.

### Pre-Commit

Installation: [install pre-commit](https://pre-commit.com/) and execute `pre-commit install`. This will generate pre-commit hooks according to the config in `.pre-commit-config.yaml`

Before submitting a PR be sure to have used the pre-commit hooks or run: `pre-commit run -a`

The `pre-commit` command will run:

- Terraform fmt
- Terraform validate
- Terraform docs
- Terraform validate with tflint
- check for merge conflicts
- fix end of files

as described in the `.pre-commit-config.yaml` file

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | ~> 2.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | ~> 2.0 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.asg_downscale_scheduler_event](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_rule.asg_upscale_scheduler_event](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_rule.ec2_start_scheduler_event](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_rule.ec2_stop_scheduler_event](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.asg_downscale_scheduler_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_event_target.asg_upscale_scheduler_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_event_target.ec2_start_scheduler_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_event_target.ec2_stop_scheduler_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_log_group.lambda_asg_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.lambda_ec2_start_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.lambda_ec2_stop_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_policy.ec2_scheduler_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.lambda_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.lambda_asg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_function.lambda_ec2_start](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_function.lambda_ec2_stop](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.allow_asg_downscale](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.allow_asg_upscale](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.allow_ec2_start](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.allow_ec2_stop](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [random_id.this](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [archive_file.lambda_asg](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [archive_file.lambda_ec2_start](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [archive_file.lambda_ec2_stop](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_iam_policy_document.ec2_scheduler_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_asg_scheduler"></a> [asg\_scheduler](#input\_asg\_scheduler) | The scheduler for updating ASG desired capacity | <pre>object({<br/>    downscale_cron_expression  = string<br/>    downscale_desired_capacity = number<br/>    upscale_cron_expression    = string<br/>    upscale_desired_capacity   = number<br/>    asg_name                   = string<br/>    description                = optional(string, "")<br/>  })</pre> | `null` | no |
| <a name="input_ec2_start_scheduler"></a> [ec2\_start\_scheduler](#input\_ec2\_start\_scheduler) | The scheduler for starting the EC2 instances | <pre>object({<br/>    cron_expression = string<br/>    instance_ids    = list(string)<br/>    description     = optional(string, "")<br/>  })</pre> | `null` | no |
| <a name="input_ec2_stop_scheduler"></a> [ec2\_stop\_scheduler](#input\_ec2\_stop\_scheduler) | The scheduler for stopping the EC2 instances | <pre>object({<br/>    cron_expression = string<br/>    instance_ids    = list(string)<br/>    description     = optional(string, "")<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_debug_ec2_scheduler"></a> [debug\_ec2\_scheduler](#output\_debug\_ec2\_scheduler) | scheduler ec2 |
<!-- END_TF_DOCS -->

## Authors

Module is maintained by [Alfredo Gottardo](https://github.com/AlfGot), [David Beauvererd](https://github.com/Davidoutz), [Davide Cammarata](https://github.com/DCamma), [Demetrio Carrara](https://github.com/sgametrio) and [Roland Bapst](https://github.com/rbapst-tamedia)

## License

Apache 2 Licensed. See [LICENSE](< link to license file >) for full details.
