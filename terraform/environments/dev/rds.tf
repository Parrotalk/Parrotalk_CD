# DB 보안 그룹
module "rds_sg" {
  source  = "../../modules/security_group"
  sg_name = "${local.service_name}-rds-sg"
  vpc_id  = data.aws_vpc.main.id

  ingress_rules = [
    { from_port = 3306, to_port = 3306, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "Allow Mysql from anywhere" },
    { from_port = 3306, to_port = 3306, protocol = "tcp", cidr_blocks = ["10.0.0.0/16"], description = "MySQL Access" },
  ]

  tags = merge(local.tags, {
    Name = "${local.service_name}-rds-sg",
  })
}

# DB 서브넷 그룹
resource "aws_db_subnet_group" "main" {
  name       = "${local.service_name}-subnet-group"
  subnet_ids = [
    data.aws_subnet.public_a.id,
    data.aws_subnet.public_c.id
  ]

  tags = merge(local.tags, {
    Name = "${local.service_name}-subnet-group"
  })
}

# RDS 인스턴스
resource "aws_db_instance" "main" {
  identifier = "${local.service_name}-db"
  
  # 프리티어 스펙
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  storage_type         = "gp2"
  
  # 데이터베이스 설정
  db_name             = "ptkdb"
  username            = "admin"
  password            = var.db_password
  
  # 네트워크 설정
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [module.rds_sg.security_group_id]
  publicly_accessible    = true
  
  # 비용 절감을 위한 설정
  multi_az               = false
  skip_final_snapshot    = true
  
  # 백업 설정
  backup_retention_period = 0  # 백업 비활성화
  backup_window          = "03:00-04:00"
  maintenance_window     = "Mon:04:00-Mon:05:00"

  # 모니터링 비활성화
  monitoring_interval    = 0
  
  tags = merge(local.tags, {
    Name = "${local.service_name}-db"
  })
}

# 출력
output "db_endpoint" {
  value = aws_db_instance.main.endpoint
}

output "db_name" {
  value = aws_db_instance.main.db_name
}

output "db_username" {
  value = aws_db_instance.main.username
}