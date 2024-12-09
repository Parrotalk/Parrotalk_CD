#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "사용법: $0 워커노드의 <instance-id>"
    echo "예시: $0 i-1234567890abcdef0"
    exit 1
fi

INSTANCE_ID=$1
DATE=$(date +%Y%m%d-%H%M)
AMI_NAME="k8s-worker-tmpl-${DATE}"

echo "워커노드 AMI 생성 시작..."

AMI_ID=$(aws ec2 create-image \
    --instance-id "${INSTANCE_ID}" \
    --name "${AMI_NAME}" \
    --description "K8s worker node AMI ${DATE}" \
    --no-reboot \
    --query 'ImageId' \
    --output text)

echo "AMI 생성 대기중... (약 5분 소요)"
aws ec2 wait image-available --image-ids "${AMI_ID}"

echo "AMI 생성 완료!"
echo "생성된 AMI ID: ${AMI_ID}"