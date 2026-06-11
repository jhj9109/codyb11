#!/bin/bash
# 04_monitor.sh: 안전한 모니터링 및 로깅
set -euo pipefail

LOG_FILE="$AGENT_LOG_DIR/monitor.log"
NOW=$(TZ='Asia/Seoul' date +"%Y-%m-%d %H:%M:%S")

# 1. Health Check (에러 코드 방어: || true 추가)
# pgrep이 프로세스를 못 찾아 에러를 내도 스크립트가 죽지 않게 함
APP_PID=$(pgrep -d ',' -f "agent-app$" || true)
if [ -z "$APP_PID" ]; then
    echo "[$NOW] [ERROR] agent-app process is not running." >> "$LOG_FILE"
    exit 1
fi

PORT_CHECK=$(ss -tuln | grep ":15034" || true)
if [ -z "$PORT_CHECK" ]; then
    echo "[$NOW] [ERROR] Port 15034 is not in LISTEN state." >> "$LOG_FILE"
    exit 1
fi

# 2. UFW 상태 점검
UFW_STATUS=$(sudo ufw status | grep -i "Status: active" || true)
echo "UFW_STATUS: $UFW_STATUS"
if [ -z "$UFW_STATUS" ]; then
    echo "[$NOW] [WARNING] UFW is inactive." >> "$LOG_FILE"
fi

# 3. 자원 수집 (awk 연산 최적화)
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}' || echo "0.0")
MEM_USAGE=$(free | awk '/Mem/ {printf("%.1f", $3/$2 * 100.0)}' || echo "0.0")
DISK_USED=$(df / | awk 'NR==2 {print $5}' | sed 's/%//' || echo "0")

# 4. 임계값 경고 출력 (bc 명령어 활용)
if (( $(echo "$CPU_USAGE > 20.0" | bc -l) )); then 
    echo "[$NOW] [WARNING] CPU threshold exceeded ($CPU_USAGE% > 20%)" >> "$LOG_FILE"
fi
if (( $(echo "$MEM_USAGE > 10.0" | bc -l) )); then 
    echo "[$NOW] [WARNING] MEM threshold exceeded ($MEM_USAGE% > 10%)" >> "$LOG_FILE"
fi
if [ "$DISK_USED" -gt 80 ]; then 
    echo "[$NOW] [WARNING] DISK threshold exceeded ($DISK_USED% > 80%)" >> "$LOG_FILE"
fi

# 5. 최종 정상 로그 기록
echo "로그용 : [$NOW] PID:$APP_PID CPU:${CPU_USAGE}% MEM:${MEM_USAGE}% DISK_USED:${DISK_USED}%"
echo "[$NOW] PID:$APP_PID CPU:${CPU_USAGE}% MEM:${MEM_USAGE}% DISK_USED:${DISK_USED}%" >> "$LOG_FILE"
