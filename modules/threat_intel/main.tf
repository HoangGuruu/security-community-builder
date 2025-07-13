# Lambda function to update threat intelligence
resource "aws_iam_role" "threat_updater_role" {
  name = "ThreatIntelUpdaterRole"
  
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

resource "aws_iam_policy" "threat_updater_policy" {
  name        = "ThreatIntelUpdaterPolicy"
  description = "Policy for threat intelligence updater Lambda"
  
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
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::${var.s3_bucket}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "guardduty:UpdateThreatIntelSet",
          "guardduty:GetThreatIntelSet"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "threat_updater_policy" {
  role       = aws_iam_role.threat_updater_role.name
  policy_arn = aws_iam_policy.threat_updater_policy.arn
}

# Lambda function code
resource "local_file" "threat_updater_code" {
  filename = "${path.module}/threat_updater.py"
  content  = <<EOF
import json
import boto3
import urllib3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """Update GuardDuty threat intelligence with latest malicious IPs"""
    
    s3_client = boto3.client('s3')
    
    # Sample threat IPs (in production, fetch from threat intelligence feeds)
    threat_ips = [
        "198.51.100.1",
        "203.0.113.1", 
        "192.0.2.1",
        "10.0.0.1",
        "172.16.0.1"
    ]
    
    # Create threat list content
    threat_content = "\n".join(threat_ips)
    
    try:
        # Upload updated threat list to S3
        bucket_name = "${var.s3_bucket}"
        key = "threat-list-updated.txt"
        
        s3_client.put_object(
            Bucket=bucket_name,
            Key=key,
            Body=threat_content,
            ContentType='text/plain'
        )
        
        logger.info(f"Updated threat intelligence list with {len(threat_ips)} IPs")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Successfully updated threat intelligence with {len(threat_ips)} IPs',
                'location': f's3://{bucket_name}/{key}'
            })
        }
        
    except Exception as e:
        logger.error(f"Error updating threat intelligence: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        }
EOF
}

# Create deployment package
data "archive_file" "threat_updater_zip" {
  type        = "zip"
  source_file = local_file.threat_updater_code.filename
  output_path = "${path.module}/threat_updater.zip"
  depends_on  = [local_file.threat_updater_code]
}

# Lambda function
resource "aws_lambda_function" "threat_updater" {
  filename         = data.archive_file.threat_updater_zip.output_path
  function_name    = "ThreatIntelUpdater"
  role            = aws_iam_role.threat_updater_role.arn
  handler         = "threat_updater.lambda_handler"
  runtime         = "python3.9"
  timeout         = 60
  
  source_code_hash = data.archive_file.threat_updater_zip.output_base64sha256
  
  environment {
    variables = {
      S3_BUCKET = var.s3_bucket
    }
  }
  
  tags = {
    Purpose = "SecuritySimulation"
  }
}