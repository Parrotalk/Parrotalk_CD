locals {
  ecr_name_prefix = "${local.service_name}-${local.environment}"  # 공통 Prefix 설정
}

# ArgoCD용 ECR
module "argocd_ecr" {
  source           = "../../modules/ecr"               # 기존 ArgoCD ECR 모듈 경로
  repository_name  = "${local.ecr_name_prefix}-ecr-argocd"  # 기존 ArgoCD ECR 이름
}

# Jenkins용 ECR 추가
module "jenkins_ecr" {
  source           = "../../modules/ecr"               # 동일한 모듈 재사용
  repository_name  = "${local.ecr_name_prefix}-ecr-jenkins"  # Jenkins용 ECR 이름
}

# 기존 ArgoCD ECR URL 출력
output "argocd_ecr_url" {
  value = module.argocd_ecr.ecr_repository_url
}

# Jenkins ECR URL 출력 추가
output "jenkins_ecr_url" {
  value = module.jenkins_ecr.ecr_repository_url
}
