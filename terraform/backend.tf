# backend.tf
# 
# 변수사용하려면 config 있어야하는데 복잡해져서 뺌
# terraform init -migrate-state


# AWS CLI 명령어 (참고용)
# aws dynamodb scan --table-name ptk-terraform-lock-table
# aws dynamodb delete-item --table-name ptk-terraform-lock-table --key '{"LockID": {"S": "ptk-terraform-state-bucket/terraform.tfstate"}}'

terraform {
  backend "s3" {
    bucket         = "ptk-terraform-state-bucket-test"
    key            = "terraform.tfstate"
    region         = "ap-northeast-2"  # 서울 리전
    encrypt        = true
    dynamodb_table = "ptk-terraform-lock-table-test"
  }
}

# S3 버킷 생성
resource "aws_s3_bucket" "terraform_state" {
  bucket = "ptk-terraform-state-bucket-test"

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

# DynamoDB 테이블 생성
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "ptk-terraform-lock-table-test"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}