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
