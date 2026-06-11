#!/bin/bash
# 00_setup.sh: 필수 패키지 설치
set -euo pipefail

echo "=== [00] Install Prerequisites ==="
apt-get update

# sudo, SSH, 방화벽(ufw), 모니터링(procps, iproute2), 계산(bc), 스케줄러(cron), 로그(logrotate), 권한(acl) 설치
apt-get install -y \
    sudo \
    openssh-server \
    ufw \
    procps \
    iproute2 \
    bc \
    cron \
    logrotate \
    acl \
    vim

echo "[OK] All required packages installed."