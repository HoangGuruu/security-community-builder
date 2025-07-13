# IAM role for remediation Lambda
resource "aws_iam_role" "remediation_role" {
  name = "SecurityRemediationRole"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "remediation_policy" {
  name        = "SecurityRemediationPolicy"
  description = "Policy for security remediation Lambda"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = var.sns_topic_arn
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:CreateTags",
          "ec2:StopInstances",
          "iam:AttachUserPolicy",
          "iam:DetachUserPolicy",
          "iam:ListUserPolicies"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "remediation_policy" {
  role       = aws_iam_role.remediation_role.name
  policy_arn = aws_iam_policy.remediation_policy.arn
}

# Lambda function code
resource "local_file" "remediation_code" {
  filename = "${path.module}/remediation.py"
  content  = <<EOF
import json
import boto3
import logging
from datetime import datetime

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """Handle security findings and perform automated remediation"""
    
    sns_client = boto3.client('sns')
    ec2_client = boto3.client('ec2')
    iam_client = boto3.client('iam')
    
    try:
        # Parse the event
        if 'Records' in event:
            # CloudWatch Events
            for record in event['Records']:
                if 'Sns' in record:
                    message = json.loads(record['Sns']['Message'])
                    process_finding(message, sns_client, ec2_client, iam_client)
        else:
            # Direct invocation
            process_finding(event, sns_client, ec2_client, iam_client)
            
        return {
            'statusCode': 200,
            'body': json.dumps('Remediation completed successfully')
        }
        
    except Exception as e:
        logger.error(f"Error in remediation: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error: {str(e)}')
        }

def process_finding(finding, sns_client, ec2_client, iam_client):
    """Process individual security finding"""
    
    finding_type = finding.get('type', 'Unknown')
    severity = finding.get('severity', 'Unknown')
    
    logger.info(f"Processing finding: {finding_type} with severity: {severity}")
    
    # Create alert message
    alert_message = f"""
Security Alert - Automated Remediation

Finding Type: {finding_type}
Severity: {severity}
Time: {datetime.utcnow().isoformat()}
Account: {finding.get('accountId', 'Unknown')}
Region: {finding.get('region', 'Unknown')}

Details: {json.dumps(finding, indent=2)}

Automated Actions Taken:
- Alert sent to security team
- Finding logged for investigation
- Remediation actions initiated based on severity
"""
    
    # Send SNS notification
    sns_client.publish(
        TopicArn='${var.sns_topic_arn}',
        Subject=f'Security Alert: {finding_type}',
        Message=alert_message
    )
    
    # Perform remediation based on finding type
    if 'GuardDuty' in finding_type:
        handle_guardduty_finding(finding, ec2_client, iam_client)
    elif 'Inspector' in finding_type:
        handle_inspector_finding(finding, ec2_client)
    
    logger.info("Remediation actions completed")

def handle_guardduty_finding(finding, ec2_client, iam_client):
    """Handle GuardDuty specific findings"""
    
    finding_type = finding.get('type', '')
    
    if 'Recon:EC2/PortProbeUnprotectedPort' in finding_type:
        # Tag instances involved in port scanning
        instance_id = finding.get('service', {}).get('resourceRole', {}).get('instanceDetails', {}).get('instanceId')
        if instance_id:
            ec2_client.create_tags(
                Resources=[instance_id],
                Tags=[
                    {'Key': 'SecurityAlert', 'Value': 'PortScanning'},
                    {'Key': 'AlertTime', 'Value': datetime.utcnow().isoformat()}
                ]
            )
            logger.info(f"Tagged instance {instance_id} for port scanning activity")
    
    elif 'UnauthorizedAPICall' in finding_type:
        # Handle unauthorized API calls
        logger.info("Detected unauthorized API call - monitoring for further activity")

def handle_inspector_finding(finding, ec2_client):
    """Handle Inspector specific findings"""
    
    severity = finding.get('severity', 'UNKNOWN')
    
    if severity in ['HIGH', 'CRITICAL']:
        # Tag resources with high/critical vulnerabilities
        resource_id = finding.get('resources', [{}])[0].get('id', '')
        if resource_id:
            logger.info(f"High/Critical vulnerability found in resource: {resource_id}")
EOF
}

# Create deployment package
data "archive_file" "remediation_zip" {
  type        = "zip"
  source_file = local_file.remediation_code.filename
  output_path = "${path.module}/remediation.zip"
  depends_on  = [local_file.remediation_code]
}

# Lambda function
resource "aws_lambda_function" "remediation" {
  filename         = data.archive_file.remediation_zip.output_path
  function_name    = "SecurityRemediation"
  role            = aws_iam_role.remediation_role.arn
  handler         = "remediation.lambda_handler"
  runtime         = "python3.9"
  timeout         = 300
  
  source_code_hash = data.archive_file.remediation_zip.output_base64sha256
  
  environment {
    variables = {
      SNS_TOPIC_ARN = var.sns_topic_arn
    }
  }
  
  tags = {
    Purpose = "SecuritySimulation"
  }
}

# Lambda permission for CloudWatch Events
resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.remediation.function_name
  principal     = "events.amazonaws.com"
}