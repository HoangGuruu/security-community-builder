# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "security_simulation" {
  name              = "/aws/security-simulation/main"
  retention_in_days = 7
  
  tags = {
    Purpose = "SecuritySimulation"
  }
}

resource "aws_cloudwatch_log_group" "guardduty_findings" {
  name              = "/aws/security-simulation/guardduty"
  retention_in_days = 30
  
  tags = {
    Purpose = "SecuritySimulation"
  }
}

resource "aws_cloudwatch_log_group" "inspector_findings" {
  name              = "/aws/security-simulation/inspector"
  retention_in_days = 30
  
  tags = {
    Purpose = "SecuritySimulation"
  }
}

# CloudWatch Event Rules for GuardDuty
resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name        = "guardduty-findings-rule"
  description = "Capture GuardDuty findings"
  
  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
  })
}

resource "aws_cloudwatch_event_target" "guardduty_lambda" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "GuardDutyLambdaTarget"
  arn       = var.lambda_remediation_arn
}

# CloudWatch Event Rules for Inspector
resource "aws_cloudwatch_event_rule" "inspector_findings" {
  name        = "inspector-findings-rule"
  description = "Capture Inspector findings"
  
  event_pattern = jsonencode({
    source      = ["aws.inspector2"]
    detail-type = ["Inspector2 Finding"]
  })
}

resource "aws_cloudwatch_event_target" "inspector_lambda" {
  rule      = aws_cloudwatch_event_rule.inspector_findings.name
  target_id = "InspectorLambdaTarget"
  arn       = var.lambda_remediation_arn
}

# Scheduled rule for threat intelligence updates
resource "aws_cloudwatch_event_rule" "threat_intel_update" {
  name                = "threat-intel-update-rule"
  description         = "Trigger threat intelligence updates"
  schedule_expression = "rate(6 hours)"
}

resource "aws_cloudwatch_event_target" "threat_intel_lambda" {
  rule      = aws_cloudwatch_event_rule.threat_intel_update.name
  target_id = "ThreatIntelLambdaTarget"
  arn       = var.threat_updater_arn
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "security_simulation" {
  dashboard_name = "SecuritySimulationDashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        
        properties = {
          metrics = [
            ["AWS/GuardDuty", "FindingCount"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "GuardDuty Findings"
          period  = 300
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 6
        width  = 24
        height = 6
        
        properties = {
          query   = "SOURCE '${aws_cloudwatch_log_group.security_simulation.name}' | fields @timestamp, @message | sort @timestamp desc | limit 100"
          region  = data.aws_region.current.name
          title   = "Security Simulation Logs"
        }
      }
    ]
  })
}

data "aws_region" "current" {}