#!/bin/bash

# Security Incident Simulation Environment Deployment Script

set -e

echo "🚀 Starting Security Incident Simulation Environment Deployment"
echo "=============================================================="

# Check prerequisites
echo "📋 Checking prerequisites..."

if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install Terraform first."
    exit 1
fi

if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install AWS CLI first."
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured. Please run 'aws configure' first."
    exit 1
fi

echo "✅ Prerequisites check passed"

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo "📝 Creating terraform.tfvars from example..."
    cp terraform.tfvars.example terraform.tfvars
    echo "⚠️  Please edit terraform.tfvars with your settings before continuing."
    echo "   Especially set your notification_email and aws_region."
    read -p "Press Enter to continue after editing terraform.tfvars..."
fi

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

# Validate configuration
echo "✅ Validating Terraform configuration..."
terraform validate

# Plan deployment
echo "📋 Creating deployment plan..."
terraform plan -out=tfplan

# Confirm deployment
echo ""
echo "🚨 IMPORTANT: This will create AWS resources that may incur costs."
echo "   The simulation will generate intentional security findings."
echo "   Only deploy in a test/development environment."
echo ""
read -p "Do you want to proceed with deployment? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Deployment cancelled."
    exit 0
fi

# Apply Terraform
echo "🚀 Deploying infrastructure..."
terraform apply tfplan

# Get outputs
echo "📊 Deployment completed! Here are the important outputs:"
echo "======================================================="
terraform output

# Build and push Docker image
echo ""
echo "🐳 Building and pushing vulnerable Docker image to ECR..."
cd modules/ecr

# Make build script executable if not already
chmod +x build_and_push.sh

# Run build script
if ./build_and_push.sh; then
    echo "✅ Docker image built and pushed successfully!"
else
    echo "⚠️  Docker image build failed. You can run it manually later:"
    echo "   cd modules/ecr && ./build_and_push.sh"
fi

cd ../..

echo ""
echo "🎉 Security Incident Simulation Environment Deployed Successfully!"
echo "=================================================================="
echo ""
echo "📋 Next Steps:"
echo "1. Wait 5-15 minutes for GuardDuty findings to appear"
echo "2. Check Inspector findings in 15-30 minutes"
echo "3. Monitor CloudWatch dashboard for alerts"
echo "4. Check your email for SNS notifications (if configured)"
echo ""
echo "🔍 Monitoring URLs:"
echo "• GuardDuty Console: https://console.aws.amazon.com/guardduty/"
echo "• Inspector Console: https://console.aws.amazon.com/inspector/v2/"
echo "• CloudWatch Dashboard: https://console.aws.amazon.com/cloudwatch/home#dashboards:name=SecuritySimulationDashboard"
echo ""
echo "⚠️  Remember to run 'terraform destroy' when you're done testing!"
echo ""