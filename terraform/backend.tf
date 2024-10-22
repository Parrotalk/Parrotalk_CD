# backend.tf
# 
# 첫 구성시 backend_infra.tf로 저장소 먼저 생성되어야함 
# 1. terraform init -backend=false
# 2. 리소스 생성 확인 
# 3. terraform init 
# 4. 리소스에 tfstate 파일 생성되었는지 확인

# 
terraform {
  backend "s3" {
    bucket         = "ptk-terraform-state-bucket"
    key            = "terraform.tfstate"
    region         = "ap-northeast-2"  # 서울 리전
    encrypt        = true
    dynamodb_table = "ptk-terraform-lock-table"
  }
}
