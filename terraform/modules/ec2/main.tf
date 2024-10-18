resource "aws_instance" "this" {
  ami           = "ami-040c33c6a51fd5d96" # ubuntu 24.04고정
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  associate_public_ip_address = var.associate_public_ip_address
  iam_instance_profile = var.iam_instance_profile
  
  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp3"
  }

  user_data = var.user_data
  user_data_replace_on_change = true

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.volume_size >= 8
      error_message = "The volume_size must be at least 8 GB."
    }
  }
}

output "instance_id" {
  description = "ID of created EC2 instance"
  value       = aws_instance.this.id
}

output "private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.this.private_ip
}

output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.this.public_ip
}