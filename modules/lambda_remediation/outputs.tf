output "function_arn" {
  description = "Security remediation Lambda function ARN"
  value       = aws_lambda_function.remediation.arn
}

output "function_name" {
  description = "Security remediation Lambda function name"
  value       = aws_lambda_function.remediation.function_name
}