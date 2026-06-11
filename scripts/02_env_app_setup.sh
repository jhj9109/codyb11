#!/bin/bash
# 03_env_app_setup.sh: 환경 변수 분리 및 멱등성 확보
set -euo pipefail
source /root/scripts/vars.env

echo "=== [02] Environment Setup ==="

ENV_FILE="/etc/profile.d/agent.sh"
cat > "$ENV_FILE" << EOF
export AGENT_HOME="$AGENT_HOME"
export AGENT_PORT=$AGENT_PORT
export AGENT_UPLOAD_DIR="\$AGENT_HOME/upload_files"
export AGENT_KEY_PATH="\$AGENT_HOME/api_keys"
export AGENT_LOG_DIR="$AGENT_LOG_DIR"
EOF

sudo chmod 644 "$ENV_FILE"
echo "[OK] Environment file created at $ENV_FILE."

# root에도 적용시키기 위해
ROOT_BASHRC="/root/.bashrc"

SOURCE_LINE="source $ENV_FILE"

if ! grep -Fxq "$SOURCE_LINE" "$ROOT_BASHRC" 2>/dev/null; then
    echo "$SOURCE_LINE" >> "$ROOT_BASHRC"
    echo "[OK] Injected env vars to root's .bashrc"
else
    echo "[INFO] Env vars already injected for root."
fi
