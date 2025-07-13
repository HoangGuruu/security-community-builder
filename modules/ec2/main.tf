data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# IAM role for EC2 instances
resource "aws_iam_role" "ec2_simulation_role" {
  name = "EC2SecuritySimulationRole"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "ec2_simulation_policy" {
  name        = "EC2SecuritySimulationPolicy"
  description = "Policy for EC2 security simulation instances"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_simulation_policy" {
  role       = aws_iam_role.ec2_simulation_role.name
  policy_arn = aws_iam_policy.ec2_simulation_policy.arn
}

resource "aws_iam_instance_profile" "ec2_simulation_profile" {
  name = "EC2SecuritySimulationProfile"
  role = aws_iam_role.ec2_simulation_role.name
}

# Command Node - performs malicious activities
resource "aws_instance" "command_node" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_simulation_profile.name
  
  user_data = base64encode(templatefile("${path.module}/user_data_command.sh", {
    attacker_access_key = var.attacker_access_key
    attacker_secret_key = var.attacker_secret_key
    s3_bucket_name      = var.s3_bucket_name
    dynamodb_table_name = var.dynamodb_table_name
  }))
  
  tags = {
    Name    = "SecuritySim-CommandNode"
    Purpose = "SecuritySimulation"
  }
}

# Scanner Node - performs port scanning and network reconnaissance
resource "aws_instance" "scanner_node" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_simulation_profile.name
  
  user_data = base64encode(file("${path.module}/user_data_scanner.sh"))
  
  tags = {
    Name    = "SecuritySim-ScannerNode"
    Purpose = "SecuritySimulation"
  }
}