# 1. user_data.sh 파일 생성 (프로젝트 루트 디렉토리에 저장)
#!/bin/bash

# Set timezone to Korea
sudo timedatectl set-timezone Asia/Seoul

# Install language pack
sudo apt-get install -y language-pack-ko

# Set locale to Korean
sudo locale-gen ko_KR.UTF-8
sudo update-locale LANG=ko_KR.UTF-8 LC_ALL=ko_KR.UTF-8