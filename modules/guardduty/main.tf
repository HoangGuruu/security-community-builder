# Enable GuardDuty
resource "aws_guardduty_detector" "main" {
  enable = true
  
  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }
  
  tags = {
    Name = "SecuritySimulationDetector"
  }
}

# Create custom threat intelligence set
resource "aws_s3_bucket" "threat_intel" {
  bucket = "guardduty-threat-intel-${random_id.threat_suffix.hex}"
}

resource "random_id" "threat_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_versioning" "threat_intel" {
  bucket = aws_s3_bucket.threat_intel.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Upload threat intelligence list
resource "aws_s3_object" "threat_list" {
  bucket = aws_s3_bucket.threat_intel.id
  key    = "threat-list.txt"
  content = <<EOF
198.51.100.1
203.0.113.1
192.0.2.1
EOF
}

# Create ThreatIntelSet
resource "aws_guardduty_threatintelset" "main" {
  activate    = true
  detector_id = aws_guardduty_detector.main.id
  format      = "TXT"
  location    = "s3://${aws_s3_bucket.threat_intel.id}/${aws_s3_object.threat_list.key}"
  name        = "SecuritySimulationThreatIntel"
  
  depends_on = [aws_s3_object.threat_list]
}

# Create IPSet for known malicious IPs
resource "aws_s3_object" "ip_set" {
  bucket = aws_s3_bucket.threat_intel.id
  key    = "malicious-ips.txt"
  content = <<EOF
198.51.100.0/24
203.0.113.0/24
192.0.2.0/24
EOF
}

resource "aws_guardduty_ipset" "main" {
  activate    = true
  detector_id = aws_guardduty_detector.main.id
  format      = "TXT"
  location    = "s3://${aws_s3_bucket.threat_intel.id}/${aws_s3_object.ip_set.key}"
  name        = "SecuritySimulationIPSet"
  
  depends_on = [aws_s3_object.ip_set]
}