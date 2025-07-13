#!/bin/bash

# Security Simulation Environment Validation Script

set -e

echo "🔍 Validating Security Incident Simulation Environment"
echo "====================================================="

# Get AWS account and region info
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region)

echo "📋 Environment Info:"
echo "   AWS Account: $ACCOUNT_ID"
echo "   Region: $REGION"
echo ""

# Check GuardDuty
echo "🛡️  Checking GuardDuty..."
DETECTOR_ID=$(aws guardduty list-detectors --query 'DetectorIds[0]' --output text)
if [ "$DETECTOR_ID" != "None" ] && [ "$DETECTOR_ID" != "" ]; then
    echo "✅ GuardDuty detector found: $DETECTOR_ID"
    
    # Check for findings
    FINDINGS_COUNT=$(aws guardduty get-findings-statistics --detector-id $DETECTOR_ID --query 'FindingStatistics.CountBySeverity.High' --output text 2>/dev/null || echo "0")
    echo "   Current findings count: $FINDINGS_COUNT"
else
    echo "❌ GuardDuty detector not found"
fi

# Check Inspector
echo ""
echo "🔍 Checking Inspector..."
INSPECTOR_STATUS=$(aws inspector2 batch-get-account-status --account-ids $ACCOUNT_ID --query 'accounts[0].status' --output text 2>/dev/null || echo "DISABLED")
echo "   Inspector status: $INSPECTOR_STATUS"

# Check EC2 instances
echo ""
echo "🖥️  Checking EC2 instances..."
INSTANCES=$(aws ec2 describe-instances --filters "Name=tag:Purpose,Values=SecuritySimulation" "Name=instance-state-name,Values=running" --query 'Reservations[].Instances[].{ID:InstanceId,Name:Tags[?Key==`Name`].Value|[0],IP:PublicIpAddress}' --output table)
if [ -n "$INSTANCES" ]; then
    echo "✅ Security simulation instances found:"
    echo "$INSTANCES"
else
    echo "❌ No running security simulation instances found"
fi

# Check S3 buckets
echo ""
echo "🪣 Checking S3 resources..."
BUCKETS=$(aws s3api list-buckets --query 'Buckets[?contains(Name, `security-sim`)].Name' --output text)
if [ -n "$BUCKETS" ]; then
    echo "✅ Security simulation S3 buckets found:"
    for bucket in $BUCKETS; do
        echo "   - $bucket"
    done
else
    echo "❌ No security simulation S3 buckets found"
fi

# Check ECR repositories
echo ""
echo "🐳 Checking ECR repositories..."
ECR_REPOS=$(aws ecr describe-repositories --query 'repositories[?contains(repositoryName, `security-sim`)].repositoryName' --output text 2>/dev/null || echo "")
if [ -n "$ECR_REPOS" ]; then
    echo "✅ Security simulation ECR repositories found:"
    for repo in $ECR_REPOS; do
        echo "   - $repo"
        # Check for images
        IMAGE_COUNT=$(aws ecr list-images --repository-name $repo --query 'length(imageIds)' --output text 2>/dev/null || echo "0")
        echo "     Images: $IMAGE_COUNT"
    done
else
    echo "❌ No security simulation ECR repositories found"
fi

# Check Lambda functions
echo ""
echo "⚡ Checking Lambda functions..."
LAMBDA_FUNCTIONS=$(aws lambda list-functions --query 'Functions[?contains(FunctionName, `Security`) || contains(FunctionName, `Threat`)].FunctionName' --output text)
if [ -n "$LAMBDA_FUNCTIONS" ]; then
    echo "✅ Security simulation Lambda functions found:"
    for func in $LAMBDA_FUNCTIONS; do
        echo "   - $func"
    done
else
    echo "❌ No security simulation Lambda functions found"
fi

# Check CloudWatch log groups
echo ""
echo "📊 Checking CloudWatch log groups..."
LOG_GROUPS=$(aws logs describe-log-groups --log-group-name-prefix "/aws/security-simulation" --query 'logGroups[].logGroupName' --output text)
if [ -n "$LOG_GROUPS" ]; then
    echo "✅ Security simulation log groups found:"
    for group in $LOG_GROUPS; do
        echo "   - $group"
    done
else
    echo "❌ No security simulation log groups found"
fi

# Check SNS topics
echo ""
echo "📧 Checking SNS topics..."
SNS_TOPICS=$(aws sns list-topics --query 'Topics[?contains(TopicArn, `security-simulation`)].TopicArn' --output text)
if [ -n "$SNS_TOPICS" ]; then
    echo "✅ Security simulation SNS topics found:"
    for topic in $SNS_TOPICS; do
        echo "   - $topic"
    done
else
    echo "❌ No security simulation SNS topics found"
fi

echo ""
echo "🎯 Validation Summary"
echo "===================="
echo "If all components show ✅, your environment is ready for security simulation."
echo "If any components show ❌, check the Terraform deployment."
echo ""
echo "📋 To monitor findings:"
echo "• GuardDuty: https://console.aws.amazon.com/guardduty/"
echo "• Inspector: https://console.aws.amazon.com/inspector/v2/"
echo "• CloudWatch: https://console.aws.amazon.com/cloudwatch/"
echo ""
echo "⏰ Expected timeline:"
echo "• GuardDuty findings: 5-15 minutes"
echo "• Inspector findings: 15-30 minutes"
echo "• Lambda alerts: Immediate when findings occur"
echo ""