locals {
  name_prefix = "${var.service_name}-${var.environment}"
}

resource "aws_instance" "this" {
  for_each = { for i, subnet_id in var.subnet_ids : i => subnet_id }

  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = each.value

  vpc_security_group_ids = var.security_group_ids

  associate_public_ip_address = var.associate_public_ip_address

  root_block_device {
    volume_size = var.volume_size
  }

  user_data = var.user_data

  tags = merge(
    var.tags,
    {
      Name = "${local.name_prefix}-ec2-${each.key + 1}"
    }
  )
}

output "instance_ids" {
  description = "IDs of created EC2 instances"
  value       = [for instance in aws_instance.this : instance.id]
}
