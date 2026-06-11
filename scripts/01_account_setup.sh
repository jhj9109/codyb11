#!/bin/bash
# 02_account_setup.sh: 계정 및 디렉터리 권한 고도화
set -euo pipefail
source /root/scripts/vars.env

echo "=== [01] Account & Directory Setup ==="

UPLOAD_FILES_DIR="$AGENT_HOME/upload_files"
API_KEYS_DIR="$AGENT_HOME/api_keys"
BIN_DIR="$AGENT_HOME/bin"

# 1. 그룹 생성 (이미 존재하면 무시)
getent group agent-core >/dev/null || sudo groupadd agent-core
getent group agent-common >/dev/null || sudo groupadd agent-common

# 2. 계정 생성 (-g: 주 그룹, -G: 보조 그룹)
id -u agent-test >/dev/null 2>&1 || sudo useradd -m -s /bin/bash -g agent-common agent-test
id -u agent-dev >/dev/null 2>&1 || sudo useradd -m -s /bin/bash -g agent-core -G agent-common agent-dev
id -u agent-admin >/dev/null 2>&1 || sudo useradd -m -s /bin/bash -g agent-core -G agent-common agent-admin

# 3. 디렉터리 생성
sudo -u agent-admin mkdir -p $UPLOAD_FILES_DIR
sudo -u agent-admin mkdir -p $API_KEYS_DIR
sudo -u agent-admin mkdir -p $BIN_DIR
sudo mkdir -p $AGENT_LOG_DIR

# 4. 소유권 및 권한 설정 (SGID 적용)
# Upload 폴더: common 그룹에게 개방 (admin, dev, test 모두 접근)
sudo chown -R agent-admin:agent-common $UPLOAD_FILES_DIR
sudo chmod 2770 $UPLOAD_FILES_DIR

# API Key & Log 폴더: core 그룹만 접근 (test는 절대 접근 불가)
sudo chown -R agent-admin:agent-core $API_KEYS_DIR $AGENT_LOG_DIR $BIN_DIR
sudo chmod 2770 $API_KEYS_DIR $AGENT_LOG_DIR
sudo chmod 2750 $BIN_DIR # bin 폴더는 실행/읽기만 가능하게(5) 제한

# 5. 오버엔지니어링(ACL) 추가: "앞으로 생길 파일"들에 대해서도 권한 강제 고정
# (-d 옵션: Default, 미래에 생성될 파일의 기본 권한을 지정)
sudo setfacl -d -m g:agent-common:rwx $UPLOAD_FILES_DIR
sudo setfacl -d -m g:agent-core:rwx $API_KEYS_DIR
sudo setfacl -d -m g:agent-core:rwx $AGENT_LOG_DIR

echo "[OK] Accounts, Directories, and SGID/ACL permissions configured."