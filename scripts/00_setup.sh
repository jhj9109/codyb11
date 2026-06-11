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

# 보너스 파일, 루트로 한번씩 실행할 예정
AGENT_HOME="/home/agent-admin/agent-app"
cp /root/scripts/monitor.sh "$AGENT_HOME/bin/report.sh"
cp /root/scripts/log_manager.sh "$AGENT_HOME/bin/log_manager.sh"
cp /root/scripts/test_log_manager.sh "$AGENT_HOME/bin/test_log_manager.sh"


echo "[OK] All required packages installed."