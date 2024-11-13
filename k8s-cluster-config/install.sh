#!/bin/bash
# 작업 유형 선택 (install 또는 reset)
read -p "Choose action (install/reset): " ACTION

KUBESPRAY_VERSION="v2.26.0"
CLUSTER_NAME="ptk-dev"
BASE_DIR=$(pwd)

# Kubespray 클론
git clone https://github.com/kubernetes-sigs/kubespray.git
cd kubespray
git checkout $KUBESPRAY_VERSION

# Python 가상환경 설정
python3 -m venv venv
source venv/bin/activate

# 의존성 설치
pip install -r requirements.txt

# 기존 inventory 디렉토리 제거 및 symbolic link 생성
rm -rf inventory
ln -s $BASE_DIR/inventory inventory

if [ "$ACTION" == "install" ]; then
    # 설치 실행
    ansible-playbook -i inventory/$CLUSTER_NAME/hosts.ini cluster.yml -b -v

    # kubeconfig 설정
    if [ ! -f "$HOME/.kube/config" ]; then
        mkdir -p $HOME/.kube
        cp $BASE_DIR/inventory/$CLUSTER_NAME/artifacts/admin.conf $HOME/.kube/config
        chmod 600 $HOME/.kube/config
        echo "Kubeconfig has been set up."
    fi

    echo "Kubernetes cluster installation complete."

elif [ "$ACTION" == "reset" ]; then
    # 클러스터 초기화 (삭제)
    ansible-playbook -i inventory/$CLUSTER_NAME/hosts.ini reset.yml -b -v

    echo "Kubernetes cluster reset complete."

else
    echo "Invalid action specified. Please choose either 'install' or 'reset'."
fi
