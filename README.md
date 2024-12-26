# Infrastructure as Code Repository

이 저장소는 인프라스트럭처 프로비저닝 및 설정을 위한 IaC(Infrastructure as Code) 코드를 포함하고 있습니다.

## 프로젝트 구조

```
.
├── db-server-config/      # DB 서버 설정을 위한 Ansible 플레이북
├── k8s-cluster-config/    # 쿠버네티스 클러스터 설정
└── terraform/             # 테라폼 인프라 코드
```

## 시작하기

### 사전 요구사항
- Ansible 2.9+
- Terraform 1.0+
- AWS CLI
- kubectl
- Kubespray

### 배포 순서

1. 기본 네트워크 인프라 배포
```bash
# 프로젝트 루트의 terraform 디렉토리에서 시작
cd terraform

# VPC, 서브넷 등 네트워크 인프라 배포
terraform init
terraform plan
terraform apply

# 네트워크 인프라 배포 완료 후 환경별 리소스 배포
cd environments/dev
terraform init
terraform plan
terraform apply
```

**중요**: 반드시 루트의 terraform 디렉토리에서 네트워크 인프라를 먼저 배포한 후, environments/dev 디렉토리의 리소스를 배포해야 합니다. 이는 VPC, 서브넷 등의 네트워크 리소스가 다른 리소스들의 기반이 되기 때문입니다.

2. Kubernetes 클러스터 설치
```bash
cd k8s-cluster-config

# 1. inventory 설정
# - inventory/ptk/ (운영 환경)
# - inventory/ptk-dev/ (개발 환경)
# 중 적절한 환경의 inventory 선택

# 2. Kubespray를 통한 클러스터 자동 설치
./install.sh
```

**Kubespray 관련 주의사항**:
- install.sh 스크립트는 선택된 inventory를 Kubespray에 자동으로 적용하여 클러스터를 구성합니다
- inventory 파일의 hosts.ini에 정의된 노드들에 대해 자동으로 클러스터가 구성됩니다
- group_vars의 설정값들이 클러스터 구성에 자동으로 적용됩니다

3. DB 서버 설정
```bash
cd db-server-config
ansible-playbook -i inventory.ini deploy.yml
```

## 컴포넌트 설명

### DB Server Configuration (`db-server-config/`)
- Ansible을 사용한 데이터베이스 서버 설정 자동화
- Docker Compose 템플릿 및 턴서버 설정 포함
- 주요 파일:
  - `deploy.yml`: 메인 배포 플레이북
  - `docker.yml`: Docker 관련 설정
  - `templates/`: 설정 템플릿 파일들

### Kubernetes Cluster Configuration (`k8s-cluster-config/`)
- 쿠버네티스 클러스터 설정 및 관리
- Kubespray를 통한 클러스터 자동 설치
- ArgoCD, Jenkins, ALB 등의 컴포넌트 설치 자동화
- 환경별 설정:
  - `inventory/ptk/`: 운영 환경 설정
  - `inventory/ptk-dev/`: 개발 환경 설정
- 주요 플레이북:
  - `setup_argocd.yml`: ArgoCD 설치 및 설정
  - `setup_jenkins.yml`: Jenkins 설치
  - `setup_alb.yml`: Application Load Balancer 설정
  - `setup_db.yaml`: 데이터베이스 설정

### Terraform Infrastructure (`terraform/`)
- AWS 인프라 프로비저닝을 위한 테라폼 코드
- 루트 디렉토리: 네트워크 인프라 정의 (VPC, 서브넷 등)
- 환경별 설정:
  - `environments/dev/`: 개발 환경 인프라
  - `environments/asg/`: Auto Scaling Group 설정
- 주요 모듈:
  - EC2 인스턴스
  - ECR 레지스트리
  - IAM 역할 및 정책
  - 보안 그룹
  - Transcribe 서비스

## 디렉토리 구조 상세
```
terraform/
├── modules/                  # 재사용 가능한 테라폼 모듈
├── environments/            # 환경별 테라폼 설정
└── *.tf                     # 공통 테라폼 설정 파일

k8s-cluster-config/
├── inventory/              # 환경별 인벤토리 및 변수
├── playbooks/             # Ansible 플레이북
└── roles/                 # Ansible 역할
```

## 참고사항
- 각 환경별 설정은 해당 환경의 `group_vars` 디렉토리에서 관리됩니다.
- 보안 관련 설정은 AWS Secrets Manager를 통해 관리됩니다.
- 모든 변경사항은 Git을 통해 버전 관리됩니다.
- 테라폼 배포 시 반드시 네트워크 인프라를 먼저 배포한 후 환경별 리소스를 배포해야 합니다.
- Kubespray를 통한 클러스터 설치는 inventory 설정 후 install.sh 스크립트로 자동화되어 있습니다.
