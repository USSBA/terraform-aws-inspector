variable "assessment_duration" {
  type        = string
  description = "The duration of the Inspector assessment run"
  default     = "3600" # 1 hour
}

variable "enable_scheduled_event" {
  type        = bool
  description = "Enable Cloudwatch Events to schedule an assessment"
  default     = true
}
variable "enabled" {
  default     = true
  description = "Set to false to disable all resources in this module.  A workaround for terraform<=0.12 having no mechanism for disabling modules between workspaces."
}
variable "name_prefix" {
  type        = string
  description = "Prefix for resource names that terraform will create"
}
variable "ruleset_cis" {
  type        = bool
  description = "Enable CIS Operating System Security Configuration Benchmarks Ruleset"
  default     = true
}
variable "ruleset_cve" {
  type        = bool
  description = "Enable Common Vulnerabilities and Exposures Ruleset"
  default     = true
}
variable "ruleset_network_reachability" {
  type        = bool
  description = "Enable AWS Network Reachability Ruleset"
  default     = true
}
variable "ruleset_security_best_practices" {
  type        = bool
  description = "Enable AWS Security Best Practices Ruleset"
  default     = true
}
variable "schedule_expression" {
  type        = string
  description = "AWS Schedule Expression: https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html"
  default     = "cron(0 14 ? * THU *)" # Run every Thursday at 2PM UTC/9AM EST/10AM EDT
}

variable "lambda_file_name" {
  type        = string
  description = "The name of lambda file which contain python code"
  default     = "finding_processor"
}

variable "report_email_target" {
  type        = list(string)
  description = "Email address to which the AWS Inspector report will be sent via findingprocessor lambda function"
}

variable "lambda_env_variables" {
  type        = map
  description = "Map of lambda environment variables"
}

variable "lambda_runtime" {
  type        = string
  description = "Lambda runtime type and version"
  default     = "python3.6"
}

variable "lambda_timeout" {
  type        = number
  description = "Lambda timeout in seconds"
  default     = 10
}

variable "lambda_memory_size" {
  type        = number
  description = "Lambda memory size in MB"
  default     = 128
}