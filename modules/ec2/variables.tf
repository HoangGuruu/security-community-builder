variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID"
  type        = string
}

variable "security_group_id" {
  description = "Security Group ID"
  type        = string
}

variable "attacker_access_key" {
  description = "Attacker IAM access key"
  type        = string
  sensitive   = true
}

variable "attacker_secret_key" {
  description = "Attacker IAM secret key"
  type        = string
  sensitive   = true
}

variable "s3_bucket_name" {
  description = "S3 bucket name for demo data"
  type        = string
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name for demo data"
  type        = string
}