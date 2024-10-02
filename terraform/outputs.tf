# modules/networking/outputs.tf
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.networking.vpc_id
}

output "subnet_public_a_id" {
  description = "The ID of the public subnet A"
  value       = module.networking.subnet_public_a_id
}

output "subnet_public_c_id" {
  description = "The ID of the public subnet C"
  value       = module.networking.subnet_public_c_id
}
