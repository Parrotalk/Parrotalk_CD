# terraform validate

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "service_name" {
  description = "Name of the service"
  type        = string
  default     = "ptk"
}

variable "environment" {
  type        = string
  description = "환경 (dev, prod 등)"
}

variable "tags" {
  description = "Tags to be applied to resources"
  type        = map(string)  # tags는 보통 key-value 형태로 전달되므로 map으로 설정
  default     = {}  # 기본적으로 비어있는 태그를 설정
}

variable "key_name" {
  description = "Name of the key pair"
  type        = string
}

variable "master_instance_type" {
  description = "Instance type for master node"
  type        = string
}

variable "master_volume_size" {
  description = "master_volume_size for master node"
  type        = string
}

variable "master_use_public_ip" {
  description = "master_use_public_ip for master node"
  type        = string
}

variable "user_data_file" {
  description = "The user data to provide when launching the instance"
  type        = string
  default     = "./modules/ec2/user_data.sh"
}

variable "node_groups" {
  description = "Map of worker node groups"
  type = map(object({
    instance_type    = string
    volume_size      = number
    use_public_ip    = bool
    subnet_tag_name  = optional(string)
  }))
  default = {}
}