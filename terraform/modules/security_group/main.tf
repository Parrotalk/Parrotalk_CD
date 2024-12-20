# modules/security_group/main.tf
resource "aws_security_group" "this" {
  name        = "${var.sg_name}"
  description = "Security group for ${var.sg_name} environment"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 보안그룹은 새 그룹 먼저 생성 후 기존꺼삭제
  lifecycle {
    create_before_destroy = true
  }
  
  tags = var.tags
}

# output
output "security_group_id" {
  value = aws_security_group.this.id
}