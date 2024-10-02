# 공통 리전 설정
provider "aws" {
  region = var.region
}

# 네트워킹 설정 (VPC 등 네트워크 관련 설정)
module "networking" {
  source      = "./modules/networking"
  name_prefix = var.service_name
}

# 테스트서버 - 보안 그룹 설정 (보안 그룹을 네트워크 모듈과 연결)
module "test_sg" {
  source      = "./modules/security_group"
  vpc_id      = module.networking.vpc_id  # 네트워크 모듈에서 생성된 VPC ID를 참조
  
  service_name = var.service_name
  environment = "test"

  ingress_rules = [
    { from_port = 22,    to_port = 22,    protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "Allow SSH" },
    { from_port = 80,    to_port = 80,    protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "Allow HTTP" },
    { from_port = 443,   to_port = 443,   protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "Allow HTTPS" },
    { from_port = 8080,  to_port = 8080,  protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "Allow Tomcat" },
    { from_port = 8443,  to_port = 8443,  protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "Allow AWS Transcribe" },
    { from_port = 8444,  to_port = 8444,  protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "Allow AWS TTS" },
    { from_port = 8445,  to_port = 8445,  protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "Allow AWS STT" },
    { from_port = 6379,  to_port = 6379,  protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "Allow Redis" },
    { from_port = 27017, to_port = 27017, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "Allow MongoDB" },
    { from_port = 3306,  to_port = 3306,  protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "Allow MysqlDB" },
    { from_port = 3478,  to_port = 3478,  protocol = "udp", cidr_blocks = ["0.0.0.0/0"], description = "Allow WebRTC" }
  ]

  tags = {
    Environment = "Test"
    ManagedBy   = "Terraform"
  }
}

# 테스트서버 - EC2 인스턴스 설정 (보안 그룹과 연결) 
module "test_ec2" {
  source = "./modules/ec2" 

  service_name = var.service_name
  environment = "test"

  vpc_id       = module.networking.vpc_id
  subnet_ids   = [ module.networking.subnet_public_a_id ]
  instance_type = "t2.micro"
  instance_count = 1
  ami_id        = "ami-040c33c6a51fd5d96"
  key_name      = "ptk-test-key"
  volume_size   = 15
  associate_public_ip_address = true
  user_data     = <<-EOF
                  #!/bin/bash
                  apt update -y
                  EOF
  security_group_ids = [module.test_sg.security_group_id]
  tags = {
    Environment = "Test"
    ManagedBy   = "Terraform"
  }
}

module "test_transcribe" {
  source = "./modules/test_transcribe"
  service_name = var.service_name
  environment = "test"
}