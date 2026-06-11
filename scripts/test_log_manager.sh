#!/bin/bash
# test_log_manager.sh: 정밀 경계값 세팅 및 사용자 대기 프롬프트 포함 검증 스크립트
set -euo pipefail

# ==========================================
# ⚙️ 1. 환경 변수 세팅 (log_manager.sh와 유기적 연동)
# ==========================================
export AGENT_LOG_DIR="/var/log/agent-app"
LOG_DIR="$AGENT_LOG_DIR"
ARCHIVE_DIR="/var/log/monitor/agent-app/archive"
MANAGER_SCRIPT="/home/agent-admin/agent-app/bin/log_manager.sh"

echo "============================================="
echo "🛠️ [STEP 1] 요구사항 맞춤형 테스트 환경 세팅 시작"
echo "============================================="

# 기존 테스트 잔재 초기화 및 폴더 클린업
sudo rm -rf "$LOG_DIR"/* "$ARCHIVE_DIR"/* 2>/dev/null || true
sudo mkdir -p "$LOG_DIR" "$ARCHIVE_DIR"

# -----------------------------------------------------------
# [조건 1] 10MB 초과하는 monitor.log 계열 파일 '정확히 11개' 세팅
# -----------------------------------------------------------
echo "- [세팅 1] 11MB짜리 monitor 로그 파일 총 11개 생성 중 (10개 순환 한계 밀어내기 검증)..."
# 원본 monitor.log 생성 (11MB)
sudo dd if=/dev/zero of="$LOG_DIR/monitor.log" bs=1M count=11 2>/dev/null
# 백업 순환본 형태인 monitor_1.log ~ monitor_10.log 까지 총 10개 추가 생성
for i in {1..10}; do
    sudo cp "$LOG_DIR/monitor.log" "$LOG_DIR/monitor_$i.log"
done

# -----------------------------------------------------------
# [조건 2] /var/log/agent-app/ 아래에 7일 이상 경과된 파일 1개 세팅
# -----------------------------------------------------------
echo "- [세팅 2] 8일 경과된 과거 원본 로그(agent_old.log) 생성 중..."
sudo touch -d "8 days ago" "$LOG_DIR/agent_old.log"

# -----------------------------------------------------------
# [조건 3] archive/ 아래에 8일, 16일, 24일, 32일 경과된 .gz 4개 세팅
# -----------------------------------------------------------
echo "- [세팅 3] 아카이브 디렉토리에 날짜별 그라데이션 .gz 파일 4개 생성 중..."
sudo touch -d "8 days ago" "$ARCHIVE_DIR/archive_8d.gz"
sudo touch -d "16 days ago" "$ARCHIVE_DIR/archive_16d.gz"
sudo touch -d "24 days ago" "$ARCHIVE_DIR/archive_24d.gz"
sudo touch -d "32 days ago" "$ARCHIVE_DIR/archive_32d.gz"

echo "[SUCCESS] 요구사항 명세에 따른 가짜 환경 구성이 완료되었습니다."
echo ""


# ==========================================
# ⏸️ 2. 매니저 스크립트 실행 전 유저 입력 대기 프롬프트
# ==========================================
echo "============================================="
echo "👀 [PAUSE] 매니저 스크립트 실행 전 대기 (Before 상태 검측)"
echo "============================================="
echo "본 터미널을 그대로 둔 채, '새 터미널 창'을 열어서 아래 명령어로 세팅을 확인하세요:"
echo "  👉 용량 초과 로그 11개 확인: ls -lh $LOG_DIR/monitor*"
echo "  👉 7일 경과 원본 확인    : ls -lh $LOG_DIR/agent_old.log"
echo "  👉 날짜별 아카이브 4개 확인: ls -lh $ARCHIVE_DIR"
echo "============================================="
echo ""
# 사용자가 다른 창에서 수동 확인을 마치고 엔터를 칠 때까지 홀딩합니다.
read -r -p "Before 상태 조사가 끝났다면 [Enter]를 눌러 log_manager.sh를 가동하세요..." 
echo ""


echo "============================================="
echo "🚀 [STEP 2] log_manager.sh 본품 가동 (sudo bash)"
echo "============================================="
sudo bash "$MANAGER_SCRIPT"
echo ""


echo "============================================="
echo "🎯 [STEP 3] 최종 결과 검증 (Assertion)"
echo "============================================="

FAILED=0

# 검증 1: monitor.log 원본이 성공적으로 0바이트로 초기화되었는가?
ORIGINAL_SIZE=$(stat -c%s "$LOG_DIR/monitor.log" 2>/dev/null || echo -1)
if [ "$ORIGINAL_SIZE" -eq 0 ]; then
    echo "✅ [PASS] 1. monitor.log 원본 비우기(copytruncate) 성공 (0바이트)"
else
    echo "❌ [FAIL] 1. monitor.log 원본이 비워지지 않았거나 누락됨 (용량: $ORIGINAL_SIZE 바이트)"
    FAILED=1
fi

# 검증 1-2: 10개 한계 정책에 의해 monitor_*.log 파일이 정확히 10개만 남았는가? (가장 오래된 11번째 탈락 확인)
MONITOR_COUNT=$(ls -1 "$LOG_DIR"/monitor_*.log 2>/dev/null | wc -l)
if [ "$MONITOR_COUNT" -eq 10 ]; then
    echo "✅ [PASS] 1-2. monitor 로그 최대 10개 보존 규칙 매칭 성공 (가장 오래된 파일 유실 처리됨)"
else
    echo "❌ [FAIL] 1-2. monitor 로그 순환 개수가 명세(10개)와 다름 (현재: $MONITOR_COUNT 개)"
    FAILED=1
fi

# 검증 2: 7일 경과 로그 원본이 유실되고 압축된 채 archive 폴더로 이사갔는가?
if [ -f "$ARCHIVE_DIR/agent_old.log.gz" ] && [ ! -f "$LOG_DIR/agent_old.log" ]; then
    echo "✅ [PASS] 2. 7일 경과 로그(agent_old.log) 압축 후 아카이브 디렉토리로 이동 성공"
else
    echo "❌ [FAIL] 2. 7일 경과 로그가 정상적으로 압축/이동되지 않고 기존 위치에 잔존함"
    FAILED=1
fi

# 검증 3: 30일 초과된 archive_32d.gz만 정확히 표적 저격 삭제되었는가?
if [ ! -f "$ARCHIVE_DIR/archive_32d.gz" ]; then
    echo "✅ [PASS] 3. 30일 초과 아카이브(archive_32d.gz) 영구 파기 성공"
else
    echo "❌ [FAIL] 3. 보존 기한이 만료된 archive_32d.gz 파일이 파기되지 않음"
    FAILED=1
fi

# 검증 3-2: 30일 이하 기한이 남은 아카이브 3개(8, 16, 24일)는 손상 없이 보존되었는가? (오작동 방어)
if [ -f "$ARCHIVE_DIR/archive_8d.gz" ] && [ -f "$ARCHIVE_DIR/archive_16d.gz" ] && [ -f "$ARCHIVE_DIR/archive_24d.gz" ]; then
    echo "✅ [PASS] 3-2. 30일 이하 아카이브 군(8일, 16일, 24일) 안전 보존 완료"
else
    echo "❌ [FAIL] 3-2. 보존되어야 할 30일 이하 아카이브 파일 중 일부가 오작동으로 삭제됨"
    FAILED=1
fi

echo "============================================="
if [ "$FAILED" -eq 0 ]; then
    echo "🎉🎉 [최종 결과] 정밀 세팅된 샌드박스 테스트 케이스를 100% 통과했습니다! (합격) 🎉🎉"
else
    echo "⚠️ [최종 결과] 일부 경계값 조건 검증이 실패했습니다. 매니저 로직을 점검하세요."
fi
echo "============================================="