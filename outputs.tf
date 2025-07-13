output "ec2_command_node_ip" {
  description = "Public IP of the command node EC2 instance"
  value       = module.ec2.command_node_ip
}

output "ec2_scanner_node_ip" {
  description = "Public IP of the scanner node EC2 instance"
  value       = module.ec2.scanner_node_ip
}

output "ecr_repository_url" {
  description = "ECR repository URL for vulnerable images"
  value       = module.ecr.repository_url
}

output "sns_topic_arn" {
  description = "SNS topic ARN for security alerts"
  value       = aws_sns_topic.security_alerts.arn
}

output "s3_bucket_name" {
  description = "S3 bucket name for demo data"
  value       = module.s3_dynamodb.bucket_name
}

output "dynamodb_table_name" {
  description = "DynamoDB table name for demo data"
  value       = module.s3_dynamodb.table_name
}

output "guardduty_detector_id" {
  description = "GuardDuty detector ID"
  value       = module.guardduty.detector_id
}

output "attacker_iam_user" {
  description = "IAM attacker user name"
  value       = module.iam_attacker.username
}

output "cloudwatch_log_groups" {
  description = "CloudWatch log group names"
  value       = module.cloudwatch.log_group_names
}