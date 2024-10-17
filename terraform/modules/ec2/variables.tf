variable "service_name" {
  type        = string
  description = "Name of the service"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
}

variable "key_name" {
  type        = string
  description = "Name of the key pair to use for the instance"
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet to launch the instance into"
}

variable "security_group_ids" {
  type        = list(string)
  description = "List of security group IDs to associate with"
}

variable "associate_public_ip_address" {
  type        = bool
  description = "Whether to associate a public IP address with the instance"
  default     = false
}

variable "iam_instance_profile" {
  description = "The IAM Instance Profile to launch the instance with"
  type        = string
  default     = null
}

variable "volume_size" {
  type        = number
  description = "Size of the root volume in gigabytes"
  default     = 8

  validation {
    condition     = var.volume_size >= 8 && var.volume_size <= 16384
    error_message = "Volume size must be between 8 and 16384 GB."
  }
}

variable "volume_type" {
  type        = string
  description = "Type of root volume"
  default     = "gp3"
}

variable "encrypted" {
  type        = bool
  description = "Whether to encrypt the root volume"
  default     = true
}

variable "user_data" {
  type        = string
  description = "User data to provide when launching the instance"
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to add to all resources"
  default     = {}
}