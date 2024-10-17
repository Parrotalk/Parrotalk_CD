variable "role_name" {
  description = "Name of the IAM Role"
  type        = string
}

variable "policy_name" {
  description = "Name of the IAM Policy"
  type        = string
}

variable "assume_role_service" {
  description = "Service that will assume the role"
  type        = string
  default     = "ec2.amazonaws.com"
}

variable "policy_description" {
  description = "Description of the IAM Policy"
  type        = string
}

variable "policy_actions" {
  description = "Actions allowed in the IAM Policy"
  type        = list(string)
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to add to all resources"
  default     = {}
}

resource "aws_iam_role" "role" {
  name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = var.assume_role_service
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_policy" "policy" {
  name        = var.policy_name
  description = var.policy_description

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action   = var.policy_actions
      Effect   = "Allow"
      Resource = "*"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "role_policy_attachment" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}

resource "aws_iam_instance_profile" "profile" {
  name = "${var.role_name}-profile"
  role = aws_iam_role.role.name
}

output "role_name" {
  value = aws_iam_role.role.name
}

output "policy_name" {
  value = aws_iam_policy.policy.name
}

output "instance_profile_name" {
  value = aws_iam_instance_profile.profile.name
}