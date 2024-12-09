locals {
  redis_name_prefix = "${local.service_name}-redis"
}

module "redis_sg" {
  source  = "../../modules/security_group"
  sg_name = "${local.redis_name_prefix}-sg"
  vpc_id  = data.aws_vpc.main.id

  ingress_rules = [
    { from_port = 6379, to_port = 6379, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "Allow Redis from anywhere" },
    { from_port = 6379, to_port = 6379, protocol = "tcp", cidr_blocks = ["10.0.0.0/16"], description = "Allow Redis" },
  ]

  tags = merge(local.tags, {
    Name = "${local.redis_name_prefix}-sg",
  })
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = "${local.redis_name_prefix}-subnet-group"
  subnet_ids = [
    data.aws_subnet.public_a.id,
    data.aws_subnet.public_c.id
  ]

  tags = merge(local.tags, {
    Name = "${local.redis_name_prefix}-subnet-group",
  })
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = local.redis_name_prefix
  engine               = "redis"
  engine_version       = "7.0"
  node_type            = "cache.t4g.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  security_group_ids   = [module.redis_sg.security_group_id]

  snapshot_retention_limit    = 0
  auto_minor_version_upgrade  = false

  tags = merge(
    local.tags,
    {
      Name = local.redis_name_prefix
    }
  )
}