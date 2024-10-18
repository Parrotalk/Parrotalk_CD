locals {
  service_name  = "ptk"
  environment   = "dev"
  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

# root main.tf 먼저 실행할 것

# ec2 생성시 서브넷ID 대신 태그명으로 검색하기위함
data "aws_subnets" "main" {
  filter {
    name   = "tag:Name"
    values = ["${local.service_name}-subnet-*"]
  }
}

# VPC를 태그로 불러오기
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["${local.service_name}-vpc"]  # VPC 태그 이름으로 검색
  }
}

data "aws_subnet" "public_a" {
  filter {
    name   = "tag:Name"
    values = ["${local.service_name}-subnet-public-a"]
  }
}

data "aws_subnet" "public_c" {
  filter {
    name   = "tag:Name"
    values = ["${local.service_name}-subnet-public-c"]
  }
}
