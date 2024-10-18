# 공통 리전 설정
provider "aws" {
  region = "ap-northeast-2"
}

# terraform validate
# terraform plan -var-file="environments/test.tfvars"
# terraform apply -var-file=environments/test.tfvars  
# terraform workspace new test
# terraform workspace select test