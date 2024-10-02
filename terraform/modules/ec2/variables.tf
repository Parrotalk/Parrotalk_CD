# modules/ec2/variables.tf

variable "service_name" {
  description = "Name of the service"
  type        = string
}

variable "environment" {
  description = "environment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the instances will be launched"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where the instances will be launched"
  type        = list(string)
}

variable "instance_type" {
  description = "Type of the EC2 instance"
  type        = string
}

variable "instance_count" {
  description = "Number of EC2 instances to create"
  type        = number
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "key_name" {
  description = "Key name to use for the EC2 instance"
  type        = string
}

variable "volume_size" {
  description = "Size of the root volume"
  type        = number
}

variable "associate_public_ip_address" {
  description = "Associate a public IP address with the instance"
  type        = bool
}

variable "user_data" {
  description = "User data script to configure the instance"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to associate with the EC2 instance"
  type        = map(string)
}

variable "security_group_ids" {
  description = "List of security group IDs to associate with the instance"
  type        = list(string)
}
