terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# VPC and Networking
resource "aws_vpc" "security_sim" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "security-simulation-vpc"
  }
}

resource "aws_internet_gateway" "security_sim" {
  vpc_id = aws_vpc.security_sim.id
  
  tags = {
    Name = "security-simulation-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.security_sim.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "security-simulation-public-subnet"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.security_sim.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.security_sim.id
  }
  
  tags = {
    Name = "security-simulation-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Security Group
resource "aws_security_group" "simulation" {
  name        = "security-simulation-sg"
  description = "Security simulation security group"
  vpc_id      = aws_vpc.security_sim.id
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "security-simulation-sg"
  }
}

# SNS Topic for alerts
resource "aws_sns_topic" "security_alerts" {
  name = "security-simulation-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.notification_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# Modules
module "iam_attacker" {
  source = "./modules/iam_attacker"
}

module "s3_dynamodb" {
  source = "./modules/s3_dynamodb"
}

module "ec2" {
  source            = "./modules/ec2"
  vpc_id            = aws_vpc.security_sim.id
  subnet_id         = aws_subnet.public.id
  security_group_id = aws_security_group.simulation.id
  attacker_access_key = module.iam_attacker.access_key
  attacker_secret_key = module.iam_attacker.secret_key
  s3_bucket_name    = module.s3_dynamodb.bucket_name
  dynamodb_table_name = module.s3_dynamodb.table_name
}

module "guardduty" {
  source = "./modules/guardduty"
}

module "inspector" {
  source = "./modules/inspector"
}

module "ecr" {
  source = "./modules/ecr"
}

module "threat_intel" {
  source     = "./modules/threat_intel"
  s3_bucket  = module.s3_dynamodb.bucket_name
}

module "lambda_remediation" {
  source        = "./modules/lambda_remediation"
  sns_topic_arn = aws_sns_topic.security_alerts.arn
}

module "cloudwatch" {
  source                    = "./modules/cloudwatch"
  lambda_remediation_arn    = module.lambda_remediation.function_arn
  threat_updater_arn        = module.threat_intel.function_arn
}