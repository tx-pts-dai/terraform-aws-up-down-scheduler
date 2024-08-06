variable "asg_scheduler" {
  description = "The scheduler for updating ASG desired capacity"
  type = object({
    downscale_cron_expression  = string
    downscale_desired_capacity = number
    upscale_cron_expression    = string
    upscale_desired_capacity   = number
    asg_name                   = string
  })
  default = {
    asg_name                   = ""
    downscale_cron_expression  = ""
    downscale_desired_capacity = 1
    upscale_cron_expression    = ""
    upscale_desired_capacity   = 2
  }
}

variable "ec2_stop_scheduler" {
  description = "The scheduler for stopping the EC2 instances"
  type = object({
    cron_expression = string
    instance_ids    = list(string)
  })
  default = {
    cron_expression = ""
    instance_ids    = []
  }
}

variable "ec2_start_scheduler" {
  description = "The scheduler for starting the EC2 instances"
  type = object({
    cron_expression = string
    instance_ids    = list(string)
  })
  default = {
    cron_expression = ""
    instance_ids    = []
  }
}
