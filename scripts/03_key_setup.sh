#!/bin/bash
# 03_env_app_setup.sh: 환경 변수 분리 및 멱등성 확보
set -euo pipefail
source /root/scripts/vars.env

echo "=== [03] Key Setup ==="

KEY_CONTENT="agent_api_key_test"
KEY_PATH="$AGENT_KEY_PATH/secret.key"

# 1. API 키 파일 생성 (이미 존재하면 건너뜀)
# if [조건] -f 파일 -d 디렉토리 -e 존재 -s 존재&사이즈!=0 -r 현재유저 읽기권한 -w 쓰기권한, ! 조건 반전
# sudo -u 유저 명령어... : 해당 유저 권한으로 실행
# bash -c "명령어" : 새로운 bash쉘 열고 명령어 실행
# > 는 sudo 영향 받지 않고 현재 스크립트 실행 중인 유저 권한으로 실행
if [ ! -f $KEY_PATH ]; then
    sudo -u agent-admin bash -c "echo '$KEY_CONTENT' > $KEY_PATH"
    echo "[OK] API key created."
else
    echo "[INFO] API key already exists. Skipping."
fi

echo "=== [App File Migration] ==="

APP_SOURCE="/root/agent-app"
APP_DEST="$AGENT_HOME/agent-app"

# 1. 원본 '파일'이 존재하는지 확인 (-f 사용)
if [ -f "$APP_SOURCE" ]; then
    # 2. 파일 이동 (이동이므로 원본 삭제 과정 생략 가능)
    sudo mv "$APP_SOURCE" "$APP_DEST"
    
    # 3. 단일 파일 소유권 변경 (-R 옵션 불필요)
    sudo chown agent-admin:agent-core "$APP_DEST"
    
    # 4. 실행 파일 권한 부여 (소유자 rwx, 그룹 rx, 기타 권한 없음)
    sudo chmod 750 "$APP_DEST"
    
    echo "[OK] Application file moved, ownership and execution permissions updated."
else
    echo "[WARNING] $APP_SOURCE file does not exist. Skipping migration."
fi

