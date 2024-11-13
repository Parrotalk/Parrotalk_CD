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

# AWS 관리형 정책 연결
resource "aws_iam_group_policy_attachment" "ec2_full_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  group      = aws_iam_group.dev_group.name
}

resource "aws_iam_group_policy_attachment" "route53_full_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
  group      = aws_iam_group.dev_group.name
}

resource "aws_iam_group_policy_attachment" "s3_read_only_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  group      = aws_iam_group.dev_group.name
}

resource "aws_iam_group_policy_attachment" "transcribe_full_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonTranscribeFullAccess"
  group      = aws_iam_group.dev_group.name
}

resource "aws_iam_group_policy_attachment" "cloudtrail_full_access" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCloudTrail_FullAccess"
  group      = aws_iam_group.dev_group.name
}

resource "aws_iam_group_policy_attachment" "cloudwatch_logs_full_access" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  group      = aws_iam_group.dev_group.name
}

# 고객 관리형 정책 생성 및 연결
resource "aws_iam_policy" "assume_role_policy" {
  name        = "ptk-dev-assume-role-policy"
  description = "Assume role policy for dev group"

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

resource "aws_iam_policy" "ec2_policy" {
  name        = "ptk-dev-ec2-policy"
  description = "Custom EC2 policy for dev group"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:StartInstances",
          "ec2:StopInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "s3_policy" {
  name        = "ptk-dev-s3-policy"
  description = "Custom S3 policy for dev group"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = "*"
      }
    ]
  })
}


# 고객 관리형 정책 연결
resource "aws_iam_group_policy_attachment" "assume_role_attachment" {
  policy_arn = aws_iam_policy.assume_role_policy.arn
  group      = aws_iam_group.dev_group.name
}

resource "aws_iam_group_policy_attachment" "ec2_policy_attachment" {
  policy_arn = aws_iam_policy.ec2_policy.arn
  group      = aws_iam_group.dev_group.name
}

resource "aws_iam_group_policy_attachment" "s3_policy_attachment" {
  policy_arn = aws_iam_policy.s3_policy.arn
  group      = aws_iam_group.dev_group.name
}

### ecr 컨테이너 권한

# ECR 정책 생성
data "aws_iam_role" "existing_role" {
  name = "control-plane.cluster-api-provider-aws.sigs.k8s.io"
}

resource "aws_iam_policy" "ecr_policy" {
  name        = "cluster-api-ecr-policy"
  description = "ECR access policy for cluster-api-provider-aws"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage"
        ]
        Resource = "arn:aws:ecr:ap-northeast-2:703671911294:repository/ptk-dev-ecr-argocd"
      },
      {
        Effect = "Allow"
        Action = "ecr:GetAuthorizationToken"
        Resource = "*"
      }
    ]
  })
}

# 기존 role에 정책 연결
resource "aws_iam_role_policy_attachment" "ecr_policy_attachment" {
  role       = data.aws_iam_role.existing_role.name
  policy_arn = aws_iam_policy.ecr_policy.arn
}
