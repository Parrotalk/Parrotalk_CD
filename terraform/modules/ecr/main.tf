# modules/ecr/main.tf

resource "aws_ecr_repository" "this" {
  name                 = var.repository_name
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

# 수명 주기 정책: untagged 이미지 하루 후 자동 삭제
resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name
  policy     = <<POLICY
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Remove untagged images after 1 day",
      "selection": {
        "tagStatus": "untagged",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 1
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
POLICY
}

output "ecr_repository_url" {
  value = aws_ecr_repository.this.repository_url
}
