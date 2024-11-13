#!/bin/bash

NAMESPACE="default"   # 네임스페이스를 변경하려면 이 값을 수정하세요.
POD_NAME="test-pod"
IMAGE="nginx:alpine"  # 테스트용으로 간단한 NGINX 이미지를 사용

# Pod 생성
echo "Creating pod $POD_NAME in namespace $NAMESPACE..."
kubectl run $POD_NAME --image=$IMAGE --namespace=$NAMESPACE
sleep 5  # Pod가 생성될 시간을 줍니다.

# Pod 생성 확인
if kubectl get pod $POD_NAME --namespace=$NAMESPACE > /dev/null 2>&1; then
    echo "Pod $POD_NAME created successfully."
else
    echo "Failed to create Pod $POD_NAME."
    exit 1
fi

# Pod 삭제
echo "Deleting pod $POD_NAME..."
kubectl delete pod $POD_NAME --namespace=$NAMESPACE
sleep 5  # Pod가 삭제될 시간을
