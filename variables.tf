variable "asg_scheduler" {
  description = "The scheduler for updating ASG desired capacity"
  type = object({
    downscale_cron_expression  = string
    downscale_desired_capacity = number
    upscale_cron_expression    = string
    upscale_desired_capacity   = number
    asg_name                   = string
    description                = optional(string, "")
  })
  default = null
}

variable "ec2_stop_scheduler" {
  description = "The scheduler for stopping the EC2 instances"
  type = object({
    cron_expression = string
    instance_ids    = list(string)
    description     = optional(string, "")
    exception_dates = optional(list(string), [])
  })
  default = null
}

variable "ec2_start_scheduler" {
  description = "The scheduler for starting the EC2 instances"
  type = object({
    cron_expression = string
    instance_ids    = list(string)
    description     = optional(string, "")
  })
  default = null
}
