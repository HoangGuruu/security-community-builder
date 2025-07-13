variable "lambda_remediation_arn" {
  description = "ARN of the security remediation Lambda function"
  type        = string
}

variable "threat_updater_arn" {
  description = "ARN of the threat intelligence updater Lambda function"
  type        = string
}