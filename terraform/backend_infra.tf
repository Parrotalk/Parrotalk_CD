# terraform state 공유하는 s3, dynamoDB 생성코드

# Lock 걸린 경우 해제 필요! AWS CLI 명령어 (참고용)
# aws dynamodb scan --table-name ptk-terraform-lock-table
# aws dynamodb delete-item --table-name ptk-terraform-lock-table --key '{"LockID": {"S": "ptk-terraform-state-bucket/terraform.tfstate"}}'

# Create the S3 bucket
resource "aws_s3_bucket" "terraform_state" {
  bucket = "ptk-terraform-state-bucket"
  
  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# Create the DynamoDB bucket
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "ptk-terraform-lock-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}