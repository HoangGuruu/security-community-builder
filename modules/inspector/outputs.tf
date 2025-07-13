output "ecr_enabler_status" {
  description = "Inspector ECR enabler status"
  value       = aws_inspector2_enabler.ecr
}

output "ec2_enabler_status" {
  description = "Inspector EC2 enabler status"
  value       = aws_inspector2_enabler.ec2
}