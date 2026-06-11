#!/bin/bash
# log_manager.sh: 용량 기반 순환 및 시간 기반 아카이브/삭제 자동화 스크립트
set -euo pipefail

# ==========================================
# ⚙️ 1. 환경 변수 및 설정값
# ==========================================
LOG_DIR="/var/log/agent-app"
ARCHIVE_DIR="/var/log/monitor/agent-app/archive"
MAX_SIZE=$((10 * 1024 * 1024))  # 10MB (Byte 단위)
MAX_FILES=10                    # 유지할 최대 순환 파일 개수
NOW=$(TZ='Asia/Seoul' date +"%Y-%m-%d %H:%M:%S")

echo "[$NOW] [INFO] === 로그 관리 스크립트 가동 시작 ==="

# ==========================================
# 🛡️ 2. 예외 처리 (방어 로직)
# ==========================================
# 2-1. 원본 디렉토리 미존재 예외 처리
if [ ! -d "$LOG_DIR" ]; then
    echo "[$NOW] [WARNING] 대상 디렉토리($LOG_DIR)가 존재하지 않습니다. 안전하게 종료합니다."
    exit 0
fi

# 2-2. 권한 부족 예외 처리
if [ ! -w "$LOG_DIR" ]; then
    echo "[$NOW] [ERROR] 디렉토리($LOG_DIR)에 쓰기 권한이 없습니다. 관리자에게 문의하세요."
    exit 1
fi

# 2-3. 아카이브 디렉토리가 없으면 안전하게 생성
mkdir -p "$ARCHIVE_DIR" || { echo "[$NOW] [ERROR] 아카이브 폴더 생성 실패"; exit 1; }


# ==========================================
# 🔄 3. [구현 1] monitor.log 용량 기반 순환 (10MB / 최대 10개)
# ==========================================
MONITOR_LOG="$LOG_DIR/monitor.log"

if [ -f "$MONITOR_LOG" ]; then
    FILE_SIZE=$(stat -c%s "$MONITOR_LOG" 2>/dev/null || echo 0)
    
    if [ "$FILE_SIZE" -gt "$MAX_SIZE" ]; then
        echo "[$NOW] [INFO] monitor.log 용량($FILE_SIZE Byte)이 10MB를 초과하여 순환을 시작합니다."
        
        # 가장 오래된 10번째 로그 삭제
        [ -f "$LOG_DIR/monitor_$MAX_FILES.log" ] && rm -f "$LOG_DIR/monitor_$MAX_FILES.log"
        
        # 파일 번호 밀어내기 (9->10, 8->9 ... 1->2)
        for i in $(seq $((MAX_FILES - 1)) -1 1); do
            if [ -f "$LOG_DIR/monitor_$i.log" ]; then
                mv "$LOG_DIR/monitor_$i.log" "$LOG_DIR/monitor_$((i + 1)).log"
            fi
        done
        
        # 원본 복사 후 내용 비우기 (앱 중단 방지: copytruncate)
        cp "$MONITOR_LOG" "$LOG_DIR/monitor_1.log"
        > "$MONITOR_LOG"
        
        echo "[$NOW] [SUCCESS] monitor.log 순환 완료 (monitor_1.log 생성됨)"
    fi
fi


# ==========================================
# 📦 4. [구현 2] 7일 경과 *.log 파일 압축 및 이동
# ==========================================
echo "[$NOW] [INFO] 7일 경과 로그 압축 프로세스 진입"

# mtime +7인 .log 파일을 찾아서 변수에 담기 (에러 방지: 2>/dev/null)
TARGET_ARCHIVES=$(find "$LOG_DIR" -maxdepth 1 -name "*.log" -type f -mtime +7 2>/dev/null || true)

# 2-4. 대상 파일 0개 예외 처리
if [ -z "$TARGET_ARCHIVES" ]; then
    echo "[$NOW] [INFO] 7일 이상 경과된 .log 대상 파일이 없습니다. (SKIP)"
else
    echo "$TARGET_ARCHIVES" | while read -r FILE; do
        [ -z "$FILE" ] && continue
        FILENAME=$(basename "$FILE")
        
        # 압축(gzip) 성공 시에만 원본 삭제 (원자성 보장)
        if gzip -c "$FILE" > "$ARCHIVE_DIR/${FILENAME}.gz"; then
            rm -f "$FILE"
            echo "[$NOW] [SUCCESS] 아카이브 및 원본 삭제 완료: ${FILENAME}.gz"
        else
            echo "[$NOW] [ERROR] 압축 실패로 인해 파일을 이동하지 않습니다: $FILENAME"
        fi
    done
fi


# ==========================================
# 🗑️ 5. [구현 3] 30일 경과 아카이브 완전 삭제
# ==========================================
echo "[$NOW] [INFO] 30일 경과 아카이브 삭제 프로세스 진입"

TARGET_DELETES=$(find "$ARCHIVE_DIR" -maxdepth 1 -name "*.gz" -type f -mtime +30 2>/dev/null || true)

# 2-5. 삭제 대상 파일 0개 예외 처리
if [ -z "$TARGET_DELETES" ]; then
    echo "[$NOW] [INFO] 30일 이상 경과된 아카이브 삭제 대상 파일이 없습니다. (SKIP)"
else
    echo "$TARGET_DELETES" | while read -r FILE; do
        [ -z "$FILE" ] && continue
        rm -f "$FILE"
        echo "[$NOW] [SUCCESS] 보존 기한(30일) 만료 파일 영구 삭제: $(basename "$FILE")"
    done
fi

echo "[$NOW] [INFO] === 로그 관리 스크립트 정상 종료 ==="