#!/bin/bash
# 05_cron_logrotate_setup.sh: 시스템 표준을 준수한 자동화
set -euo pipefail
source /root/scripts/vars.env

echo "=== [06] Cron & Logrotate Setup ==="

MONITOR_SCRIPT="$AGENT_HOME/bin/monitor.sh"

# 모니터링 파일 정해진 위치로 이동 및 소유자/권한 설정
cp /root/scripts/monitor.sh $MONITOR_SCRIPT
sudo chown agent-dev:agent-core $MONITOR_SCRIPT
sudo chmod 750 $MONITOR_SCRIPT

# 보너스 파일, 루트로 한번씩 실행할 예정
cp /root/scripts/report.sh "$AGENT_HOME/bin/report.sh"
cp /root/scripts/log_manager.sh "$AGENT_HOME/bin/log_manager.sh"
cp /root/scripts/test_log_manager.sh "$AGENT_HOME/bin/test_log_manager.sh"

# 1. 시스템 표준 Logrotate 설정 (루트 권한으로 시스템 디렉터리에 생성)
LOGROTATE_CONF="/etc/logrotate.d/agent-app"
sudo tee "$LOGROTATE_CONF" >/dev/null <<EOF
/var/log/agent-app/monitor.log {
    su agent-admin agent-core
    size 10M
    rotate 10
    missingok
    notifempty
    copytruncate
}
EOF
echo "[OK] System logrotate configured at $LOGROTATE_CONF"

CRON_JOB="AGENT_LOG_DIR=$AGENT_LOG_DIR
* * * * * bash $MONITOR_SCRIPT"
# 기존 크론탭 내용을 변수에 저장 (임시 파일 안 씀!)
CURRENT_CRON=$(sudo -u agent-admin crontab -l 2>/dev/null || true)

echo "====CURRENT_CRON==="
echo "$CURRENT_CRON"
echo "==================="

# 변수 안에서 문자열 검색
if ! echo "$CURRENT_CRON" | grep -Fq "$MONITOR_SCRIPT"; then
    # 기존 내용과 새 내용을 합쳐서 crontab 표준 입력(-)으로 바로 쏴줌
    (echo "$CURRENT_CRON"; echo "$CRON_JOB") | sudo -u agent-admin crontab -
    UPDATED_CRON=$(sudo -u agent-admin crontab -l 2>/dev/null || true)
    echo "========UPDATED_CRON==========="
    echo "$UPDATED_CRON"
    echo "==============================="
    echo "[OK] Cron job registered for agent-admin."
else
    echo "[INFO] Cron job already exists. Skipping."
fi

# 도커 환경 호환을 위한 cron 서비스 시작
sudo service cron start || echo "[WARNING] Failed to start cron service. Check manually."
