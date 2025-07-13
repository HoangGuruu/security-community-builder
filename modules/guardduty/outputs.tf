output "detector_id" {
  description = "GuardDuty detector ID"
  value       = aws_guardduty_detector.main.id
}

output "threat_intel_bucket" {
  description = "Threat intelligence S3 bucket"
  value       = aws_s3_bucket.threat_intel.id
}