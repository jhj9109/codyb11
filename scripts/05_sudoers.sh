#!/bin/bash
# 01_b_sudoers_setup.sh: agent-admin을 위한 최소 권한 패스워드 면제 규칙 적용
set -euo pipefail

echo "=== [05] Sudoers Minimal Privilege Configuration ==="

TARGET_USER="agent-admin"
SUDOERS_FILE="/etc/sudoers.d/agent-app-rules"

# 1. 멱등성(Idempotency)을 고려하여 설정 파일 안전하게 생성
# /etc/sudoers 파일을 직접 건드리는 것보다 /etc/sudoers.d/ 폴더 밑에 격리하는 것이 안전합니다.
sudo bash -c "cat << 'EOF' > $SUDOERS_FILE
# agent-admin 유저는 ufw status 명령어만 비밀번호 없이 실행 가능함
$TARGET_USER ALL=(ALL) NOPASSWD: /usr/sbin/ufw status
EOF"

# 2. 리눅스 보안 규정 준수 (sudoers 확장 파일은 반드시 0440 권한이어야 작동함)
sudo chmod 440 "$SUDOERS_FILE"

echo "[OK] NOPASSWD rule for 'ufw status' successfully applied at $SUDOERS_FILE"