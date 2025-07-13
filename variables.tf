variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "notification_email" {
  description = "Email address for security alerts"
  type        = string
  default     = ""
}

variable "key_pair_name" {
  description = "EC2 Key Pair name for SSH access"
  type        = string
  default     = "security-sim-key"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "security-simulation"
}

variable "malicious_ips" {
  description = "List of malicious IPs for simulation"
  type        = list(string)
  default = [
    "198.51.100.1",
    "203.0.113.1",
    "192.0.2.1"
  ]
}