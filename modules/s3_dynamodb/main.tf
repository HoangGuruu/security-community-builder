resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 Bucket for demo data
resource "aws_s3_bucket" "demo_data" {
  bucket = "security-sim-demo-${random_id.bucket_suffix.hex}"
}

resource "aws_s3_bucket_versioning" "demo_data" {
  bucket = aws_s3_bucket.demo_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "demo_data" {
  bucket = aws_s3_bucket.demo_data.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Upload sensitive demo files
resource "aws_s3_object" "confidential" {
  bucket = aws_s3_bucket.demo_data.id
  key    = "confidential.txt"
  content = "This is confidential data for security simulation purposes."
}

resource "aws_s3_object" "credentials" {
  bucket = aws_s3_bucket.demo_data.id
  key    = "fake-credentials.json"
  content = jsonencode({
    username = "admin"
    password = "supersecret123"
    api_key  = "fake-api-key-12345"
  })
}

# DynamoDB table for demo data
resource "aws_dynamodb_table" "demo_data" {
  name           = "security-sim-demo-data"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  
  attribute {
    name = "id"
    type = "S"
  }
  
  tags = {
    Purpose = "SecuritySimulation"
  }
}

# Add demo items to DynamoDB
resource "aws_dynamodb_table_item" "demo_item1" {
  table_name = aws_dynamodb_table.demo_data.name
  hash_key   = aws_dynamodb_table.demo_data.hash_key
  
  item = jsonencode({
    id = {
      S = "user-001"
    }
    name = {
      S = "John Doe"
    }
    ssn = {
      S = "123-45-6789"
    }
    credit_card = {
      S = "4111-1111-1111-1111"
    }
  })
}

resource "aws_dynamodb_table_item" "demo_item2" {
  table_name = aws_dynamodb_table.demo_data.name
  hash_key   = aws_dynamodb_table.demo_data.hash_key
  
  item = jsonencode({
    id = {
      S = "user-002"
    }
    name = {
      S = "Jane Smith"
    }
    ssn = {
      S = "987-65-4321"
    }
    credit_card = {
      S = "5555-5555-5555-4444"
    }
  })
}