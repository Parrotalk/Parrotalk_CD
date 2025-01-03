resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.service_name}-vpc"
    "kubernetes.io/cluster/${var.service_name}" = "shared"  # 클러스터 태그 추가
  }
}

# Public Subnet A
resource "aws_subnet" "public_a" {
  vpc_id     = aws_vpc.this.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.service_name}-subnet-public-a"
    "kubernetes.io/cluster/${var.service_name}" = "shared"
    "kubernetes.io/role/elb" = "1"  # 외부 로드밸런서용 태그
  }
}

# Public Subnet C
resource "aws_subnet" "public_c" {
  vpc_id     = aws_vpc.this.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-northeast-2c"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.service_name}-subnet-public-c"
    "kubernetes.io/cluster/${var.service_name}" = "shared"
    "kubernetes.io/role/elb" = "1"  # 외부 로드밸런서용 태그
  }
}

# Private Subnet A
resource "aws_subnet" "private_a" {
  vpc_id     = aws_vpc.this.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "${var.service_name}-subnet-private-a"
    "kubernetes.io/cluster/${var.service_name}" = "shared"
    "kubernetes.io/role/internal-elb" = "1"  # 내부 로드밸런서용 태그
  }
}

# Private Subnet C
resource "aws_subnet" "private_c" {
  vpc_id     = aws_vpc.this.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "${var.service_name}-subnet-private-c"
    "kubernetes.io/cluster/${var.service_name}" = "shared"
    "kubernetes.io/role/internal-elb" = "1"  # 내부 로드밸런서용 태그
  }
}

# Internet Gateway for Public Subnets
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.service_name}-igw"
  }
}

# Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.service_name}-rt-public"
    "kubernetes.io/cluster/${var.service_name}" = "shared"
  }
}

# Associate Route Table with Public Subnet A
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

# Associate Route Table with Public Subnet C
resource "aws_route_table_association" "public_c" {
  subnet_id      = aws_subnet.public_c.id
  route_table_id = aws_route_table.public.id
}

## output ##

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "public_subnet_a_id" {
  description = "ID of the Public Subnet A"
  value       = aws_subnet.public_a.id
}

output "public_subnet_c_id" {
  description = "ID of the Public Subnet C"
  value       = aws_subnet.public_c.id
}

output "private_subnet_a_id" {
  description = "ID of the Private Subnet A"
  value       = aws_subnet.private_a.id
}

output "private_subnet_c_id" {
  description = "ID of the Private Subnet C"
  value       = aws_subnet.private_c.id
}