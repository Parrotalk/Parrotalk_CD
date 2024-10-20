resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "${var.service_name}-vpc"
  }
}

# Public Subnet A
resource "aws_subnet" "public_a" {
  vpc_id     = aws_vpc.this.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "${var.service_name}-subnet-public-a"
  }
}

# Public Subnet C
resource "aws_subnet" "public_c" {
  vpc_id     = aws_vpc.this.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "${var.service_name}-subnet-public-c"
  }
}

# Private Subnet A
resource "aws_subnet" "private_a" {
  vpc_id     = aws_vpc.this.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "${var.service_name}-subnet-private-a"
  }
}

# Private Subnet C
resource "aws_subnet" "private_c" {
  vpc_id     = aws_vpc.this.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "${var.service_name}-subnet-private-c"
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