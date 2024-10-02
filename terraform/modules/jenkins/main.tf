# modules/jenkins 
# 빌드용 젠킨스 서버 생성 스크립트
# vpc, igw, key-pair, elastic ip 생성되어있다는 가정

# 기존 vpc 사용
data "aws_vpc" "existing_vpc" {
  id = "vpc-0e6c1d7326b749bc8"
}

# 기존 게이트웨이 사용
data "aws_internet_gateway" "existing_gw" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.existing_vpc.id]
  }
}

# 서브넷 생성
resource "aws_subnet" "rb_dev_subnet_public_jenkins" {
  vpc_id                  = data.aws_vpc.existing_vpc.id
  cidr_block              = "192.168.90.0/24" # 새 서브넷의 CIDR 블록 (기존 VPC 범위 내에서 설정)
  availability_zone       = "ap-northeast-2a" # 사용하려는 가용 영역으로 변경
  map_public_ip_on_launch = true
  tags = {
    Name = "rb-dev-subnet-public-jenkins"
  }
}

# 라우팅 테이블 생성, 인터넷 게이트웨이 연결 
resource "aws_route_table" "rb_dev_rt_jenkins" {
  vpc_id = data.aws_vpc.existing_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.existing_gw.id
  }

  tags = {
    Name = "rb-dev-rt-jenkins"
  }
}

# 서브넷-라우팅테이블 연결
resource "aws_route_table_association" "rb_dev_subnet_public_jenkins_association" {
  subnet_id      = aws_subnet.rb_dev_subnet_public_jenkins.id
  route_table_id = aws_route_table.rb_dev_rt_jenkins.id
}

# 보안그룹 생성
resource "aws_security_group" "rb_dev_sg_jenkins" {
  name   = "rb-dev-sg-jenkins"
  vpc_id = data.aws_vpc.existing_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8090
    to_port     = 8090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rb-dev-sg-jenkins"
  }
}

# 기존 탄력적 ip 가져오기 
data "aws_eip" "by_public_ip" {
  public_ip = "13.124.218.141"
}

# 서버 생성
resource "aws_instance" "rb_dev_jenkins_server" {
  ami           = "ami-062cf18d655c0b1e8" # Ubuntu 24.04 AMI ID (리전에 따라 다를 수 있음)
  instance_type = "t2.medium"
  subnet_id     = aws_subnet.rb_dev_subnet_public_jenkins.id
  vpc_security_group_ids = [
    aws_security_group.rb_dev_sg_jenkins.id
  ]

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
  }

  # ip 자동생성 끔 (탄력적 ip 있음)
  associate_public_ip_address = false

  # 기존 생성한 키페어 사용
  key_name                    = "rb-dev-jenkins-key"

  # 설치 후 스크립트 
  user_data = <<-EOF
    #!/bin/bash
    # Update the package list
    sudo apt-get update -y
  EOF
    
  tags = {
    Name = "rb-dev-jenkins-server"
  }
}

# 탄력적 IP를 EC2 인스턴스와 연결
resource "aws_eip_association" "jenkins_eip_assoc" {
  instance_id   = aws_instance.rb_dev_jenkins_server.id
  allocation_id = data.aws_eip.by_public_ip.id
}

output "jenkins_server_public_ip" {
  description = "Public IP of the Jenkins server"
  value       = aws_instance.rb_dev_jenkins_server.public_ip
}