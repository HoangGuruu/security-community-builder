output "username" {
  description = "IAM attacker username"
  value       = aws_iam_user.demo_attacker.name
}

output "access_key" {
  description = "IAM attacker access key"
  value       = aws_iam_access_key.demo_attacker.id
  sensitive   = true
}

output "secret_key" {
  description = "IAM attacker secret key"
  value       = aws_iam_access_key.demo_attacker.secret
  sensitive   = true
}