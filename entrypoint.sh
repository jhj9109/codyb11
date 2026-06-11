#!/bin/bash
# entrypoint.sh: 스크립트 순차적 자동 실행 및 시스템 유지
set -e # 에러 발생 시 즉시 중단

echo "===[ SYSTEM ] Starting automatic script execution ==="

# 호스트에서 복사해온 스크립트들을 순차적으로 실행 (하나라도 실패하면 여기서 멈춤)
/root/scripts/00_setup.sh && \
/root/scripts/01_account_setup.sh && \
/root/scripts/02_env_app_setup.sh && \
/root/scripts/03_key_setup.sh && \
/root/scripts/04_security_setup.sh && \
/root/scripts/05_sudoers.sh && \
/root/scripts/06_cron_logrotate_setup.sh

echo "===[ SYSTEM ] All setup scripts executed successfully ==="

# SSH 데몬 및 크론 서비스를 포그라운드로 유지하여 컨테이너가 종료되지 않게 방어
# 만약 단순 터미널 진입을 원하시면 아래 라인을 주석 처리하고 exec /bin/bash 를 쓰셔도 됩니다.
# exec /usr/sbin/sshd -D
# exec /bin/bash
exec tail -f /dev/null