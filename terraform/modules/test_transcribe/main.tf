variable "service_name" {
  description = "Name of the service"
  type        = string
  default     = "ptk"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

locals {
  bucket_name          = format("%s-%s-data-bucket", var.service_name, var.environment)
  iam_group_name       = format("%s-%s-group", var.service_name, var.environment)
  iam_user_name        = format("%s-%s-user", var.service_name, var.environment)
  group_membership     = format("%s-%s-group-membership", var.service_name, var.environment)
}

# IAM Group
resource "aws_iam_group" "service_group" {
  name = local.iam_group_name
}

# IAM User
resource "aws_iam_user" "service_user" {
  name = local.iam_user_name
}

# Attach the user to the group
resource "aws_iam_group_membership" "service_group_membership" {
  name  = local.group_membership
  group = aws_iam_group.service_group.name
  users = [aws_iam_user.service_user.name]
}

# S3 Bucket Policy Document
data "aws_iam_policy_document" "s3_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      aws_s3_bucket.service_bucket.arn,
      "${aws_s3_bucket.service_bucket.arn}/*"
    ]
  }
}

# Transcribe Policy Document
data "aws_iam_policy_document" "transcribe_policy" {
  statement {
    effect = "Allow"
    actions = [
      "transcribe:StartTranscriptionJob",
      "transcribe:GetTranscriptionJob",
      "transcribe:DeleteTranscriptionJob"
    ]
    resources = ["*"]
  }
}

# Attach the S3 and Transcribe Policies to the Group
resource "aws_iam_group_policy" "service_group_policy" {
  name   = format("%s-%s-s3-policy", var.service_name, var.environment)
  group  = aws_iam_group.service_group.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

resource "aws_iam_group_policy" "transcribe_group_policy" {
  name   = format("%s-%s-transcribe-policy", var.service_name, var.environment)
  group  = aws_iam_group.service_group.id
  policy = data.aws_iam_policy_document.transcribe_policy.json
}

# IAM Role for EC2 with Full Access
resource "aws_iam_role" "transcribe_ec2_role" {
  name = format("%s-%s-ec2-transcribe-role", var.service_name, var.environment)

  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

# Assume Role Policy for EC2
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# IAM Policy for Full EC2 Access and S3, Transcribe Access
data "aws_iam_policy_document" "transcribe_s3_ec2_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:*",  # Full EC2 access
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "transcribe:StartTranscriptionJob",
      "transcribe:GetTranscriptionJob",
      "transcribe:DeleteTranscriptionJob"
    ]
    resources = ["*"]
  }
}

# Attach Policy to EC2 Role
resource "aws_iam_role_policy" "transcribe_s3_ec2_policy_attachment" {
  name   = format("%s-%s-transcribe-s3-ec2-policy", var.service_name, var.environment)
  role   = aws_iam_role.transcribe_ec2_role.id
  policy = data.aws_iam_policy_document.transcribe_s3_ec2_policy.json
}

# IAM Instance Profile for EC2
resource "aws_iam_instance_profile" "transcribe_instance_profile" {
  name = format("%s-%s-transcribe-instance-profile", var.service_name, var.environment)
  role = aws_iam_role.transcribe_ec2_role.name
}

# EC2 인스턴스에 IAM Role 연결을 수동으로 수행
#resource "aws_iam_instance_profile_attachment" "attach_profile_to_instance" {
#  instance_id         = "i-013e97ed7811f78d5"  # 이미 존재하는 EC2 인스턴스 ID
#  iam_instance_profile = aws_iam_instance_profile.transcribe_instance_profile.name
#}

# S3 Bucket 생성 및 ACL, Public Access 설정
resource "aws_s3_bucket" "service_bucket" {
  bucket = local.bucket_name
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.service_bucket.id
  block_public_acls        = false
  block_public_policy      = false
  ignore_public_acls       = false
  restrict_public_buckets  = false
}
