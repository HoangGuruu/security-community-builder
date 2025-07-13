output "function_arn" {
  description = "Threat intelligence updater Lambda function ARN"
  value       = aws_lambda_function.threat_updater.arn
}

output "function_name" {
  description = "Threat intelligence updater Lambda function name"
  value       = aws_lambda_function.threat_updater.function_name
}