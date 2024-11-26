# 1. README.md

# PTK Kubernetes Cluster Configuration

이 저장소는 PTK Kubernetes 클러스터 구성을 위한 Kubespray 설정을 포함하고 있습니다.

## 사전 요구사항

- Python 3.8+
- pip
- git
- AWS CLI 구성
- SSH 키 (ptk-k8s-key.pem)

## 설치 방법

<<<<<<< HEAD
1. aws 네트워크 구성 설치:
```
cd terraform
terraform init
terraform apply
```

2. aws 서버 구성 설치:
```
cd terraform/environments/dev
terraform init
terraform plan
terraform apply
```

3. 쿠버네티스 클러스터 설치:
```bash
cd k8s-cluster-config
./install.sh
> install 입력
```

4. argocd 설치:
```bash
cd k8s-cluster-config
ansible-playbook playbooks/setup-argocd (최대 10분 소요)
```

## 디렉토리 구조
- `inventory/ptk/`: 클러스터 설정 파일
=======
1. 저장소 클론:
```bash
git clone https://github.com/your-org/k8s-cluster-config.git
cd k8s-cluster-config
```

2. 사전 요구사항 설치:
```bash
./scripts/setup-requirements.sh
```

3. 클러스터 설치:
```bash
./install.sh
```

4. 설치 검증:
```bash
./scripts/verify-installation.sh
```

## 디렉토리 구조
- `inventory/ptk-dev/`: 클러스터 설정 파일
- `scripts/`: 유틸리티 스크립트
>>>>>>> 2519dd2bed55a806a97d29202daeea748c1ab6bc

## 주의사항
- AWS 자격 증명이 필요합니다
- 방화벽 설정을 확인해주세요
<<<<<<< HEAD
- SSH 키는 ~/.ssh/ptk-k8s-key.pem 위치에 있어야 합니다

kubectl apply -f root-app.yaml

helm repo add jetstack https://charts.jetstack.io 
helm repo update
=======
- SSH 키는 ~/.ssh/ptk-k8s-key.pem 위치에 있어야 합니다
>>>>>>> 2519dd2bed55a806a97d29202daeea748c1ab6bc
