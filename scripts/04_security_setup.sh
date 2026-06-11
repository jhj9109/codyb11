#!/bin/bash
# 01_security_setup.sh: SSH 및 방화벽 고도화
set -euo pipefail

echo "=== [04] Security Setup ==="

# 1. SSH 설정 (원본을 건드리지 않고 .d 디렉토리에 커스텀 파일 생성)
SSH_CUSTOM_CONF="/etc/ssh/sshd_config.d/99-custom-security.conf"
echo "Port 20022" | sudo tee $SSH_CUSTOM_CONF > /dev/null
echo "PermitRootLogin no" | sudo tee -a $SSH_CUSTOM_CONF > /dev/null
sudo service ssh restart # 도커 환경 호환 명령어

echo "[OK] SSH configured at $SSH_CUSTOM_CONF"

# 2. UFW 방화벽 설정 (기본 정책 적용)
sudo ufw --force reset # 기존 규칙 초기화
sudo ufw default deny incoming # 들어오는건 일단 다 막음
sudo ufw default allow outgoing # 나가는건 다 허용

# 필요한 포트만 개방
sudo ufw allow 20022/tcp
sudo ufw allow 15034/tcp
sudo ufw --force enable

# ssh root접속 테스트를 위한 root 계정 및 일반 계정 비번 설정
echo "root:123" | chpasswd
echo "agent-admin:222" | chpasswd
echo "agent-dev:333" | chpasswd
echo "agent-test:444" | chpasswd

echo "[OK] UFW Firewall configured and enabled."