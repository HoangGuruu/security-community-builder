output "log_group_names" {
  description = "CloudWatch log group names"
  value = [
    aws_cloudwatch_log_group.security_simulation.name,
    aws_cloudwatch_log_group.guardduty_findings.name,
    aws_cloudwatch_log_group.inspector_findings.name
  ]
}

output "dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.security_simulation.dashboard_name}"
}