terraform {
  backend "s3" {
    bucket         = "ptk-terraform-state-bucket-test"
    key            = "dev/terraform.tfstate"
    region         = "ap-northeast-2"  # 서울 리전
    encrypt        = true
    dynamodb_table = "ptk-terraform-lock-table-test"
  }
}