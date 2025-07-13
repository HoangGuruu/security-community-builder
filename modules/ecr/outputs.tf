output "repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.vulnerable_app.repository_url
}

output "repository_name" {
  description = "ECR repository name"
  value       = aws_ecr_repository.vulnerable_app.name
}

output "build_script_path" {
  description = "Path to Docker build script"
  value       = local_file.build_script.filename
}