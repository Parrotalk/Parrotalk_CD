locals {
  ecr_name_prefix = "${local.service_name}-${local.environment}"
}

module "argocd_ecr" {
  source           = "../../modules/ecr"           # 모듈 경로
  repository_name  = "${local.ecr_name_prefix}-ecr-argocd"          # 원하는 리포지토리 이름으로 변경
}

output "argocd_ecr_url" {
  value = module.argocd_ecr.ecr_repository_url
}