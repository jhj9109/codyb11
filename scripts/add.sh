#!/bin/bash

# 06_monitor2_setup.sh

set -euo pipefail

source /root/scripts/vars.env

echo "=== Monitor2 Setup ==="

MONITOR2_SCRIPT="$AGENT_HOME/bin/monitor2.sh"

# monitor2 배포

cp /root/scripts/monitor2.sh "$MONITOR2_SCRIPT"

sudo chown agent-dev:agent-core "$MONITOR2_SCRIPT"
sudo chmod 750 "$MONITOR2_SCRIPT"

echo "[OK] monitor2.sh deployed."

# monitor2 크론 등록

CRON_JOB="* * * * * bash $MONITOR2_SCRIPT"

CURRENT_CRON=$(sudo -u agent-admin crontab -l 2>/dev/null || true)

echo "==== CURRENT CRON ===="
echo "$CURRENT_CRON"
echo "======================"

if ! echo "$CURRENT_CRON" | grep -Fq "$MONITOR2_SCRIPT"; then
(
echo "$CURRENT_CRON"
echo "$CRON_JOB"
) | sudo -u agent-admin crontab -

```
echo "[OK] monitor2 cron registered."
```

else
echo "[INFO] monitor2 cron already exists."
fi

UPDATED_CRON=$(sudo -u agent-admin crontab -l 2>/dev/null || true)

echo "==== UPDATED CRON ===="
echo "$UPDATED_CRON"
echo "======================"

# 리스타트 불필요