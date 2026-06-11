#!/bin/bash
# report.sh: monitor.log 분석 및 기간별 리소스 통계 요약 리포트 생성
set -euo pipefail

# ==========================================
# ⚙️ 1. 기본 환경 변수 및 인자 처리
# ==========================================
# 크론 진공 환경 및 사용자 커스텀 환경 대응을 위해 디폴트 경로 바인딩
LOG_FILE="${AGENT_LOG_DIR:-/var/log/agent-app}/monitor.log"

# 사용법 안내용 함수
usage() {
    echo "Usage: $0 [-s 'YYYY-MM-DD HH:MM:SS'] [-e 'YYYY-MM-DD HH:MM:SS']"
    echo "Example: $0 -s '2026-06-11 10:00:00' -e '2026-06-11 12:00:00'"
    exit 1
}

START_TIME=""
END_TIME=""

# getopts를 활용한 우아한 CLI 옵션 파싱
while getopts "s:e:h" opt; do
    case "$opt" in
        s) START_TIME=$OPTARG ;;
        e) END_TIME=$OPTARG ;;
        h|*) usage ;;
    esac
done

# ==========================================
# 🛡️ 2. 예외 처리 및 유효성 검증
# ==========================================
if [ ! -f "$LOG_FILE" ]; then
    echo "[ERROR] 분석 대상 로그 파일($LOG_FILE)이 존재하지 않습니다."
    exit 1
fi

# ==========================================
# 🔍 3. 데이터 필터링 및 awk 통계 연산 매직
# ==========================================
echo "============================================="
echo "📊 [인프라 관제 통계 요약 리포트 생성]"
echo "============================================="
echo "분석 대상: $LOG_FILE"

# 시간 필터링 메시지 출력
if [ -n "$START_TIME" ] && [ -n "$END_TIME" ]; then
    echo "분석 기간: $START_TIME ~ $END_TIME"
elif [ -n "$START_TIME" ]; then
    echo "분석 기간: $START_TIME 이후 전체 구간"
elif [ -n "$END_TIME" ]; then
    echo "분석 기간: $END_TIME 이전 전체 구간"
else
    echo "분석 기간: 로그 전체 수집 구간"
fi
echo "============================================="

# 핵심 연산 프로세스: 
# 1. grep -v로 [DEBUG], [INFO] 꼬리표를 뗀 정제된 표준 관제 행만 통과시킵니다.
# 2. awk를 이용해 시간 비교 및 누적 통계 연산(평균, 최대, 최소, 샘플수)을 한방에 처리합니다.
# 3. 데이터 유실 및 문자열 꼬임 방지를 위해 sed로 % 기호를 전처리해 떼어냅니다.

cat "$LOG_FILE" | grep -v "\[DEBUG\]" | grep -v "\[INFO\]" | grep -v "\[ERROR\]" | grep -v "\[START\]" | grep -v "\[END\]" | grep -v "===" | sed 's/%//g' | awk -v start="$START_TIME" -v end="$END_TIME" '
BEGIN {
    # 최대/최소 비교기 초기화
    cpu_min = 999.9; cpu_max = -1.0;
    mem_min = 999.9; mem_max = -1.0;
    disk_min = 999.9; disk_max = -1.0;
    count = 0;
}
{
    # monitor.log 표준 포맷에서 데이터 위치 매핑:
    # $1=[2026-06-11, $2=10:24:01], $4=CPU:0.5, $5=MEM:3.4, $6=DISK_USED:1
    
    # 대괄호 유실 처리 및 시간 결합
    gsub(/[\[\]]/, "", $1);
    gsub(/[\[\]]/, "", $2);
    log_time = $1 " " $2;

    # 기간 검색 조건 스크리닝 (문자열 대소비교 연산 활용)
    if (start != "" && log_time < start) next;
    if (end != "" && log_time > end) next;

    # 변수 분할 발라내기 (split 파싱)
    split($4, cpu_arr, ":"); cpu = cpu_arr[2];
    split($5, mem_arr, ":"); mem = mem_arr[2];
    split($6, disk_arr, ":"); disk = disk_arr[2];

    # 데이터 누적
    cpu_sum += cpu; mem_sum += mem; disk_sum += disk;
    count++;

    # 경계값 최댓값/최솟값 저격 매칭
    if (cpu < cpu_min) cpu_min = cpu; if (cpu > cpu_max) cpu_max = cpu;
    if (mem < mem_min) mem_min = mem; if (mem > mem_max) mem_max = mem;
    if (disk < disk_min) disk_min = disk; if (disk > disk_max) disk_max = disk;
}
END {
    # 2-2. 수집 대상 데이터가 0개일 때 분모 폭파(Division by Zero) 철벽 방어 예외 처리
    if (count == 0) {
        print "\n⚠️ [안내] 선택하신 조건에 일치하는 관제 샘플 데이터가 0개입니다.";
        print "          시간 범위 또는 monitor.log 데이터 축적 상태를 확인해 주세요.";
        exit 0;
    }

    # 최종 예쁜 서식 포맷 출력
    printf "\n📈 [총 수집 데이터 샘플 수: %d 개]\n\n", count;
    
    print "⚙️ 1. CPU 사용률 통계"
    printf "   - 평균(AVG): %.2f %%\n", cpu_sum / count
    printf "   - 최대(MAX): %.1f %%\n", cpu_max
    printf "   - 최소(MIN): %.1f %%\n\n", cpu_min

    print "🧠 2. MEM 사용률 통계"
    printf "   - 평균(AVG): %.2f %%\n", mem_sum / count
    printf "   - 최대(MAX): %.1f %%\n", mem_max
    printf "   - 최소(MIN): %.1f %%\n\n", mem_min

    print "💾 3. DISK 사용률 통계"
    printf "   - 평균(AVG): %.2f %%\n", disk_sum / count
    printf "   - 최대(MAX): %d %%\n", disk_max  # 디스크는 보통 정수 포맷 매칭
    printf "   - 최소(MIN): %d %%\n", disk_min
    print "============================================="
}
'