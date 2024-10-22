# iam.tf
locals {
  name_prefix = "${local.service_name}-${local.environment}"
}

# IAM 역할 생성
resource "aws_iam_role" "transcribe_role" {
  name = "${local.name_prefix}-transcribe-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# DEV 그룹 생성
resource "aws_iam_group" "dev_group" {
  name = "${local.name_prefix}-group"
}

# DEV 사용자 생성
resource "aws_iam_user" "dev_user" {
  name = "${local.environment}-user"
}

# 사용자를 그룹에 추가
resource "aws_iam_group_membership" "dev_membership" {
  name = "${local.name_prefix}-${local.environment}-membership"
  
  users = [aws_iam_user.dev_user.name]
  group = aws_iam_group.dev_group.name
}

# S3 권한 정책
resource "aws_iam_policy" "s3_policy" {
  name        = "${local.name_prefix}-s3-policy"
  description = "S3 permissions for dev group"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.data_bucket.arn,
          "${aws_s3_bucket.data_bucket.arn}/*"
        ]
      }
    ]
  })
}

# EC2 권한 정책
resource "aws_iam_policy" "ec2_policy" {
  name        = "${local.name_prefix}-ec2-policy"
  description = "EC2 permissions for dev group"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:RebootInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

# Transcribe 권한 정책
resource "aws_iam_policy" "transcribe_policy" {
  name        = "${local.name_prefix}-transcribe-policy"
  description = "Transcribe permissions for dev group"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "transcribe:StartTranscriptionJob",
          "transcribe:GetTranscriptionJob",
          "transcribe:ListTranscriptionJobs",
          "transcribe:DeleteTranscriptionJob"
        ]
        Resource = "*"
      }
    ]
  })
}

# 그룹에 정책 연결
resource "aws_iam_group_policy_attachment" "s3_policy_attachment" {
  policy_arn = aws_iam_policy.s3_policy.arn
  group      = aws_iam_group.dev_group.name
}

resource "aws_iam_group_policy_attachment" "ec2_policy_attachment" {
  policy_arn = aws_iam_policy.ec2_policy.arn
  group      = aws_iam_group.dev_group.name
}

resource "aws_iam_group_policy_attachment" "transcribe_policy_attachment" {
  policy_arn = aws_iam_policy.transcribe_policy.arn
  group      = aws_iam_group.dev_group.name
}

# 역할 수임 권한 정책
resource "aws_iam_group_policy" "assume_role_policy" {
  name  = "${local.name_prefix}-assume-role-policy"
  group = aws_iam_group.dev_group.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = aws_iam_role.transcribe_role.arn
      }
    ]
  })
}