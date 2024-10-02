# modules/networking/outputs.tf
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}

output "subnet_public_a_id" {
  description = "The ID of the public subnet A"
  value       = aws_subnet.public_a.id
}

output "subnet_public_c_id" {
  description = "The ID of the public subnet C"
  value       = aws_subnet.public_c.id
}