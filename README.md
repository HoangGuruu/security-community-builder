# Security Incident Simulation Environment

This Terraform project creates a comprehensive security incident simulation environment on AWS that automatically triggers findings in Amazon GuardDuty and Amazon Inspector.

## 🎯 Objective

Simulate realistic security violations to test incident response workflows in a controlled environment.

## 🏗️ Architecture

The infrastructure includes:

- **EC2 Simulation Nodes**: Two instances performing malicious activities
- **Amazon GuardDuty**: Enabled with threat intelligence sets
- **Amazon Inspector**: Enabled for ECR and EC2 vulnerability scanning
- **ECR Repository**: Contains vulnerable Docker images
- **Lambda Functions**: Automated remediation and threat intelligence updates
- **CloudWatch**: Event rules, log groups, and monitoring dashboard
- **IAM Simulation**: Demo attacker user with limited permissions
- **S3 & DynamoDB**: Demo resources with sensitive data

## 🚀 Quick Start

### Prerequisites

1. AWS CLI configured with appropriate permissions
2. Terraform >= 1.0 installed
3. Docker installed (for ECR image building)

### Deployment

1. **Clone and navigate to the project:**
   ```bash
   cd terraform/security
   ```

2. **Copy and customize variables:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your settings
   ```

3. **Initialize and deploy:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Build and push vulnerable Docker image:**
   ```bash
   # After terraform apply completes
   cd modules/ecr
   ./build_and_push.sh
   ```

### Configuration

Edit `terraform.tfvars`:

```hcl
aws_region = "us-east-1"
notification_email = "your-email@example.com"
key_pair_name = "your-key-pair"
```

## 🔍 What Gets Simulated

### GuardDuty Findings

- **Port Scanning**: Automated nmap scans from scanner node
- **Malicious IP Communication**: Connections to known bad IPs
- **Unauthorized API Calls**: IAM user attempting restricted actions
- **Suspicious DNS Queries**: Queries to malicious domains

### Inspector Findings

- **Vulnerable Docker Images**: Images with known CVEs in ECR
- **EC2 Vulnerabilities**: OS-level security issues

### Automated Activities

The EC2 instances automatically perform:

1. **Command Node**:
   - Connects to malicious IPs every 5 minutes
   - Attempts unauthorized S3/DynamoDB access
   - Generates suspicious API calls

2. **Scanner Node**:
   - Port scans external targets every 10 minutes
   - Network reconnaissance activities
   - Banner grabbing attempts

## 📊 Monitoring & Alerts

### CloudWatch Dashboard
Access the security simulation dashboard:
```
https://console.aws.amazon.com/cloudwatch/home#dashboards:name=SecuritySimulationDashboard
```

### SNS Notifications
Configure email notifications by setting `notification_email` in `terraform.tfvars`.

### Log Groups
- `/aws/security-simulation/main` - General simulation logs
- `/aws/security-simulation/guardduty` - GuardDuty findings
- `/aws/security-simulation/inspector` - Inspector findings

## 🛠️ Outputs

After deployment, you'll get:

```bash
terraform output
```

Key outputs include:
- EC2 instance public IPs
- ECR repository URL
- SNS topic ARN
- GuardDuty detector ID
- CloudWatch log group names

## 🔧 Customization

### Adding More Malicious Activities

Edit the user data scripts in `modules/ec2/`:
- `user_data_command.sh` - Command node activities
- `user_data_scanner.sh` - Scanner node activities

### Custom Threat Intelligence

Update threat lists in `modules/guardduty/main.tf` or use the Lambda function to fetch from external sources.

### Remediation Actions

Customize automated responses in `modules/lambda_remediation/remediation.py`.

## 🧹 Cleanup

```bash
terraform destroy
```

**Note**: Manually delete any ECR images before destroying if needed.

## ⚠️ Important Notes

### Security Considerations

1. **Test Environment Only**: This creates intentionally vulnerable resources
2. **Network Isolation**: Consider using private subnets in production testing
3. **Access Control**: Limit access to simulation resources
4. **Cost Management**: Monitor costs, especially for GuardDuty and Inspector

### Expected Timeline

- **GuardDuty Findings**: 5-15 minutes after deployment
- **Inspector Findings**: 15-30 minutes for ECR scans
- **Lambda Alerts**: Immediate when findings are generated

### Troubleshooting

1. **No GuardDuty Findings**: Check if activities are running on EC2 instances
2. **Inspector Not Scanning**: Ensure ECR images are pushed successfully
3. **Lambda Errors**: Check CloudWatch logs for detailed error messages

## 📋 Module Structure

```
modules/
├── ec2/                 # EC2 simulation instances
├── guardduty/          # GuardDuty configuration
├── inspector/          # Inspector enablement
├── lambda_remediation/ # Automated response functions
├── threat_intel/       # Threat intelligence updates
├── iam_attacker/       # Demo attacker IAM user
├── ecr/               # Vulnerable container images
├── cloudwatch/        # Monitoring and alerting
└── s3_dynamodb/       # Demo data resources
```

## 🤝 Contributing

1. Test changes in isolated AWS account
2. Update documentation for new features
3. Follow Terraform best practices
4. Ensure security simulation remains realistic

## 📄 License

This project is for educational and testing purposes only. Use responsibly in controlled environments.