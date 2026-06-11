#!/bin/bash
# 04_monitor.sh: 구간별 추적 로그가 포함된 디버깅 버전
set -euo pipefail

LOG_FILE_OLD="$AGENT_LOG_DIR/monitor.log"
LOG_FILE="/var/log/agent-app/monitor.log"
echo "[LOG_FILE_OLD] : $LOG_FILE_OLD" >> "$LOG_FILE"
NOW=$(TZ='Asia/Seoul' date +"%Y-%m-%d %H:%M:%S")

# 디버깅 시작 알림
echo "[$NOW] [DEBUG] ==========================================" >> "$LOG_FILE"
echo "[$NOW] [DEBUG] [START] monitor.sh 관제 주기 시작" >> "$LOG_FILE"

# 1. Health Check 단계
echo "[$NOW] [DEBUG] [STEP 1] 프로세스 및 포트 헬스체크 진입" >> "$LOG_FILE"

APP_PID=$(pgrep -d ',' -f "agent-app" || true)
echo "[$NOW] [DEBUG] 수집된 APP_PID 문자열: [$APP_PID]" >> "$LOG_FILE"

if [ -z "$APP_PID" ]; then
    echo "[$NOW] [ERROR] agent-app process is not running." >> "$LOG_FILE"
    exit 1
fi
echo "[$NOW] [DEBUG] [SUCCESS] 프로세스 체크 통과" >> "$LOG_FILE"

PORT_CHECK=$(ss -tuln | grep ":15034" || true)
echo "[$NOW] [DEBUG] 수집된 PORT_CHECK 문자열: [$PORT_CHECK]" >> "$LOG_FILE"

if [ -z "$PORT_CHECK" ]; then
    echo "[$NOW] [ERROR] Port 15034 is not in LISTEN state." >> "$LOG_FILE"
    exit 1
fi
echo "[$NOW] [DEBUG] [SUCCESS] 포트 점유 체크 통과" >> "$LOG_FILE"


# 2. UFW 상태 점검 단계
echo "[$NOW] [DEBUG] [STEP 2] UFW 방화벽 상태 점검 진입" >> "$LOG_FILE"

UFW_STATUS=$(sudo ufw status | grep -i "Status: active" || true)
echo "[$NOW] [DEBUG] 수집된 UFW_STATUS 문자열: [$UFW_STATUS]" >> "$LOG_FILE"

if [ -z "$UFW_STATUS" ]; then
    echo "[$NOW] [WARNING] UFW is inactive." >> "$LOG_FILE"
else
    echo "[$NOW] [DEBUG] [SUCCESS] UFW 활성화 확인 완료" >> "$LOG_FILE"
fi


# 3. 자원 수집 단계 (도커 환경용 df / 방어 코드 반영)
echo "[$NOW] [DEBUG] [STEP 3] 시스템 리소스(CPU/MEM/DISK) 수집 진입" >> "$LOG_FILE"

CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}' || echo "0.0")
echo "[$NOW] [DEBUG] 연산된 CPU_USAGE: [$CPU_USAGE%]" >> "$LOG_FILE"

MEM_USAGE=$(free | awk '/Mem/ {printf("%.1f", $3/$2 * 100.0)}' || echo "0.0")
echo "[$NOW] [DEBUG] 연산된 MEM_USAGE: [$MEM_USAGE%]" >> "$LOG_FILE"

# 환경 변화에 강한 정규식 매칭 방식으로 오작동을 차단합니다.
DISK_USED=$(df / | awk '/\// {print $5}' | sed 's/%//' || echo "0")
echo "[$NOW] [DEBUG] 파싱된 DISK_USED: [$DISK_USED%]" >> "$LOG_FILE"


# 4. 임계값 경고 출력 단계
echo "[$NOW] [DEBUG] [STEP 4] 리소스 임계값 비교 연산 진입" >> "$LOG_FILE"

if (( $(echo "$CPU_USAGE > 20.0" | bc -l) )); then 
    echo "[$NOW] [WARNING] CPU threshold exceeded ($CPU_USAGE% > 20%)" >> "$LOG_FILE"
else
    echo "[$NOW] [DEBUG] CPU 임계값 미만 (정상)" >> "$LOG_FILE"
fi

if (( $(echo "$MEM_USAGE > 10.0" | bc -l) )); then 
    echo "[$NOW] [WARNING] MEM threshold exceeded ($MEM_USAGE% > 10%)" >> "$LOG_FILE"
else
    echo "[$NOW] [DEBUG] MEM 임계값 미만 (정상)" >> "$LOG_FILE"
fi

if [ "$DISK_USED" -gt 80 ]; then 
    echo "[$NOW] [WARNING] DISK threshold exceeded ($DISK_USED% > 80%)" >> "$LOG_FILE"
else
    echo "[$NOW] [DEBUG] DISK 임계값 미만 (정상)" >> "$LOG_FILE"
fi


# 5. 최종 정상 로그 기록 및 종료
echo "[$NOW] [DEBUG] [STEP 5] 표준 관제 데이터 파일 적재 시작" >> "$LOG_FILE"

# 일반 수동 실행 유저를 위한 화면 표준출력
echo "실행 로그 남기기용도 >>> [$NOW] PID:$APP_PID CPU:${CPU_USAGE}% MEM:${MEM_USAGE}% DISK_USED:${DISK_USED}%"

# 과제 표준 양식 포맷 적재
echo "[$NOW] PID:$APP_PID CPU:${CPU_USAGE}% MEM:${MEM_USAGE}% DISK_USED:${DISK_USED}%" >> "$LOG_FILE"

echo "[$NOW] [DEBUG] [END] monitor.sh 관제 주기 정상 종료" >> "$LOG_FILE"
echo "[$NOW] [DEBUG] ==========================================" >> "$LOG_FILE"