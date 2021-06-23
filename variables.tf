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
variable "ruleset_cve_arn" {
  type        = string
  description = "ARN for Common Vulnerabilities and Exposures Ruleset: https://docs.aws.amazon.com/inspector/latest/userguide/inspector_rules-arns.html"
  default     = "arn:aws:inspector:us-east-1:316112463485:rulespackage/0-gEjTy7T7"
}
variable "ruleset_cis_arn" {
  type        = string
  description = "ARN for CIS Operating System Security Configuration Benchmarks Ruleset: https://docs.aws.amazon.com/inspector/latest/userguide/inspector_rules-arns.html"
  default     = "arn:aws:inspector:us-east-1:316112463485:rulespackage/0-rExsr2X8"
}
variable "ruleset_network_reachability_arn" {
  type        = string
  description = "ARN for AWS Network Reachability Ruleset: https://docs.aws.amazon.com/inspector/latest/userguide/inspector_rules-arns.html"
  default     = "arn:aws:inspector:us-east-1:316112463485:rulespackage/0-PmNV0Tcd"
}
variable "ruleset_security_best_practices_arn" {
  type        = string
  description = "ARN for AWS Security Best Practices Ruleset: https://docs.aws.amazon.com/inspector/latest/userguide/inspector_rules-arns.html"
  default     = "arn:aws:inspector:us-east-1:316112463485:rulespackage/0-R01qwB5Q"
}
variable "schedule_expression" {
  type        = string
  description = "AWS Schedule Expression: https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html"
  default     = "rate(7 days)"
}
