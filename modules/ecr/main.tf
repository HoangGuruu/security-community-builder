# ECR Repository for vulnerable images
resource "aws_ecr_repository" "vulnerable_app" {
  name                 = "security-sim-vulnerable-app"
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }
  
  tags = {
    Purpose = "SecuritySimulation"
  }
}

resource "aws_ecr_lifecycle_policy" "vulnerable_app" {
  repository = aws_ecr_repository.vulnerable_app.name
  
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 images"
        selection = {
          tagStatus = "any"
          countType = "imageCountMoreThan"
          countNumber = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Create Dockerfile for vulnerable image
resource "local_file" "dockerfile" {
  filename = "${path.module}/Dockerfile"
  content  = <<EOF
FROM ubuntu:18.04

# Install vulnerable packages
RUN apt-get update && apt-get install -y \
    openssl=1.1.1-1ubuntu2.1~18.04.23 \
    curl \
    wget \
    apache2 \
    php7.2 \
    mysql-client \
    && rm -rf /var/lib/apt/lists/*

# Add vulnerable application files
COPY app/ /var/www/html/

# Expose port
EXPOSE 80

# Start Apache
CMD ["apache2ctl", "-D", "FOREGROUND"]
EOF
}

# Create vulnerable app files
resource "local_file" "vulnerable_php" {
  filename = "${path.module}/app/index.php"
  content  = <<EOF
<?php
// Vulnerable PHP application for security simulation
if (isset($_GET['cmd'])) {
    // Command injection vulnerability
    system($_GET['cmd']);
}

if (isset($_POST['sql'])) {
    // SQL injection vulnerability
    $conn = new mysqli("localhost", "root", "", "testdb");
    $query = "SELECT * FROM users WHERE id = " . $_POST['sql'];
    $result = $conn->query($query);
}

// XSS vulnerability
if (isset($_GET['name'])) {
    echo "Hello " . $_GET['name'];
}
?>
<html>
<body>
<h1>Vulnerable Test Application</h1>
<p>This application contains intentional vulnerabilities for security testing.</p>
</body>
</html>
EOF
}

# Build script for the Docker image
resource "local_file" "build_script" {
  filename = "${path.module}/build_and_push.sh"
  content  = <<EOF
#!/bin/bash
set -e

# Get ECR login token
aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${aws_ecr_repository.vulnerable_app.repository_url}

# Build the image
docker build -t ${aws_ecr_repository.vulnerable_app.name} ${path.module}

# Tag the image
docker tag ${aws_ecr_repository.vulnerable_app.name}:latest ${aws_ecr_repository.vulnerable_app.repository_url}:latest
docker tag ${aws_ecr_repository.vulnerable_app.name}:latest ${aws_ecr_repository.vulnerable_app.repository_url}:vulnerable-v1.0

# Push the image
docker push ${aws_ecr_repository.vulnerable_app.repository_url}:latest
docker push ${aws_ecr_repository.vulnerable_app.repository_url}:vulnerable-v1.0

echo "Vulnerable image pushed to ECR successfully!"
EOF
}

data "aws_region" "current" {}

# Make build script executable
resource "null_resource" "make_executable" {
  provisioner "local-exec" {
    command = "chmod +x ${local_file.build_script.filename}"
  }
  
  depends_on = [local_file.build_script]
}