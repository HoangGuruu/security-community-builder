output "bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.demo_data.id
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.demo_data.arn
}

output "table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.demo_data.name
}

output "table_arn" {
  description = "DynamoDB table ARN"
  value       = aws_dynamodb_table.demo_data.arn
}