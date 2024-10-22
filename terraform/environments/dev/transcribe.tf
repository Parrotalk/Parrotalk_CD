# transcribe.tf
# S3 버킷 생성
resource "aws_s3_bucket" "data_bucket" {
  bucket = "${local.name_prefix}-data-bucket"
  
  tags = merge(local.tags, {
    Name = "${local.name_prefix}-data-bucket"
    Environment = local.environment
  })
}

# 퍼블릭 액세스 설정
resource "aws_s3_bucket_public_access_block" "data_bucket_access" {
  bucket = aws_s3_bucket.data_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# 소유권 설정
resource "aws_s3_bucket_ownership_controls" "data_bucket_ownership" {
  bucket = aws_s3_bucket.data_bucket.id
  
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
  depends_on = [aws_s3_bucket_public_access_block.data_bucket_access]
}

# ACL 설정
resource "aws_s3_bucket_acl" "data_bucket_acl" {
  bucket = aws_s3_bucket.data_bucket.id
  acl    = "public-read-write"
  
  depends_on = [
    aws_s3_bucket_public_access_block.data_bucket_access,
    aws_s3_bucket_ownership_controls.data_bucket_ownership
  ]
}

# 버킷 정책
resource "aws_s3_bucket_policy" "data_bucket_policy" {
  bucket = aws_s3_bucket.data_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "PublicReadWrite"
        Effect = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.data_bucket.arn}/*"
      }
    ]
  })

  depends_on = [
    aws_s3_bucket_public_access_block.data_bucket_access,
    aws_s3_bucket_acl.data_bucket_acl
  ]
}
