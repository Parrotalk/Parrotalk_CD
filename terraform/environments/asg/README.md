K8s 워커노드 ASG 구성하기
사전 준비

기존 워커노드로 AMI 생성

bashCopy./scripts/create-ami.sh <instance-id>

테라폼 실행

bashCopyterraform init
terraform plan
terraform apply
주의사항

AMI 생성은 실제 운영중인 워커노드의 설정을 그대로 가져오기 위한 작업입니다
AMI 생성 후 테라폼 실행 시 해당 AMI ID를 사용