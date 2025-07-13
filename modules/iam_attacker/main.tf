# IAM User for simulation
resource "aws_iam_user" "demo_attacker" {
  name = "demo-attacker"
  path = "/"
  
  tags = {
    Purpose = "SecuritySimulation"
  }
}

resource "aws_iam_access_key" "demo_attacker" {
  user = aws_iam_user.demo_attacker.name
}

# Limited policy for attacker simulation
resource "aws_iam_policy" "attacker_policy" {
  name        = "AttackerSimulationPolicy"
  description = "Limited permissions for security simulation"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = "*"
      },
      {
        Effect = "Deny"
        Action = [
          "s3:DeleteObject",
          "s3:PutObject",
          "dynamodb:DeleteItem",
          "dynamodb:PutItem"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "attacker_policy" {
  user       = aws_iam_user.demo_attacker.name
  policy_arn = aws_iam_policy.attacker_policy.arn
}