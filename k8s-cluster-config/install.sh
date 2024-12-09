#!/bin/bash
read -p "Choose action (install/reset/scale): " ACTION  # scale 옵션 추가

KUBESPRAY_VERSION="v2.26.0"
CLUSTER_NAME="ptk"
BASE_DIR=$(pwd)

git clone https://github.com/kubernetes-sigs/kubespray.git
cd kubespray
git checkout $KUBESPRAY_VERSION

python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

rm -rf inventory
ln -s $BASE_DIR/inventory inventory

case "$ACTION" in
 "install")
   ansible-playbook -i inventory/$CLUSTER_NAME/hosts.ini cluster.yml -b -v
   if [ ! -f "$HOME/.kube/config" ]; then
     mkdir -p $HOME/.kube
     cp $BASE_DIR/inventory/$CLUSTER_NAME/artifacts/admin.conf $HOME/.kube/config
     chmod 600 $HOME/.kube/config
     echo "Kubeconfig has been set up."
   fi
   ;;
 "reset")
   ansible-playbook -i inventory/$CLUSTER_NAME/hosts.ini reset.yml -b -v
   ;;
 "scale")  # scale 옵션 추가
   ansible-playbook -i inventory/$CLUSTER_NAME/hosts.ini scale.yml -b -v
   ;;
 *)
   echo "Invalid action. Choose install, reset, or scale."
   exit 1
   ;;
esac

echo "$ACTION completed."