
# b1-1

## 1. 기본 보안 및 네트워크 설정

### 1.1 SSH 설정
- sshd 설정 파일을 건들고 재시작 한다.

### 1.2 방화벽 설정 (UFW 선택)
- ufw 명령어로 요구되어진 설정들을 세팅한다.

## 2. 계정/그룹/권한 체계

### 2.1 계정/그룹 생성
- group 명령어로 그룹을 생성 한다.
- useradd 명령어로 계정을 생성한다.
  - m: 홈 디렉터리 생성
  - g: primary 그룹 지정
  - G: secondary 그룹 기정

### 2.2 디렉토리 생성 / 접근 권한
- sudo -u 유저명 과 함께 mkdir 명령어로 각각 생성한다.
- chown 명령어로 파일의 소유자를 지정하고, chmod 명령어로 권한을 지정한다.
- setfacl 명령어로 앞으로 생성될 파일의 기본 권한도 지정한다.

## 3. 실행 환경 구성

### 3.1 환경변수
- export 환경변수명=값 으로 설정한다.
- 쉘 오픈시 적용될 수 있도록 .bashrc에 등록한다.

### 3.2 키 파일 생성
- 정해진 위치에 파일 생성

### 3.3 앱 실행
- 일반 계정 실행
- Boot Sequence 5단계가 모두 [OK]로 출력되고, 마지막에 “Agent READY”가 출력
- 앱이 0.0.0.0:15034로 LISTEN 상태
- 앱 종료는 Ctrl+C로 수행

## 4. 시스템 관제 스크립트 구현

### 4.1 스크립트 파일 위치 & 권한 정책 (monitor.sh)
- 경로: $AGENT_HOME/bin/monitor.sh
- 소유자: agent-dev
- 그룹: agent-core
- 권한: 750
- cron 실행 계정: agent-admin (agent-core 그룹에 속한)

### 4.2 Health Check
- agent_app.py 실행 상태 확인
- TCP 15034 LISTEN 
- 비정상시 exit 1

### 4.3 상태 점검(only 경고)
- UFW 황성화 상태 점검

### 4.4 자원 수집
- CPU 사용륭
- 메모리 사용률
- 디스크 사용률

### 4.5 임계값 경고(only 경고)
- CPU 20%, MEM 10%, DISK_USED > 80%

### 4.6 로그기록
- /var/log/agent-app/monitor.log
- [YYYY-MM-DD HH:MM:SS] PID:... CPU:..% MEM:..% DISK_USED:..%

### 4.7 로그 파일 용량 관리
- monitor.log가 커지면 최대 10MB/10개 파일 유지(방법 자유: logrotate 사용 또는 스크립트 로직 구현)

# 1. SSH 포트 변경(20022) 및 Root 원격 접속 차단 설정 확인 내역
```bash
# /etc/ssh/sshd_config 파일 내 Include /etc/ssh/sshd_config.d/*.conf
cat /etc/ssh/sshd_config.d/99-custom-security.conf;

ss -tulnp | grep sshd;
```

```bash
root@1ce3142e27f6:~# cat /etc/ssh/sshd_config.d/99-custom-security.conf;

Port 20022
PermitRootLogin no

root@1ce3142e27f6:~# ss -tulnp | grep sshd;

tcp   LISTEN 0      128          0.0.0.0:20022      0.0.0.0:*    users:(("sshd",pid=4702,fd=3))     
tcp   LISTEN 0      128             [::]:20022         [::]:*    users:(("sshd",pid=4702,fd=4))
```

# 2. 방화벽(UFW) 활성화 및 20022/tcp, 15034/tcp 허용 내역
```bash
sudo ufw status verbose
```
```bash
root@1ce3142e27f6:~# sudo ufw status verbose

Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), deny (routed)
New profiles: skip

To                         Action      From
--                         ------      ----
20022/tcp                  ALLOW IN    Anywhere                  
15034/tcp                  ALLOW IN    Anywhere                  
20022/tcp (v6)             ALLOW IN    Anywhere (v6)             
15034/tcp (v6)             ALLOW IN    Anywhere (v6)
```

# 3. 계정/그룹 생성 확인 내역
```bash
id agent-test agent-dev agent-admin
```
```bash
root@1ce3142e27f6:~# id agent-test agent-dev agent-admin

uid=1000(agent-test) gid=1001(agent-common) groups=1001(agent-common)
uid=1001(agent-dev) gid=1000(agent-core) groups=1000(agent-core),1001(agent-common)
uid=1002(agent-admin) gid=1000(agent-core) groups=1000(agent-core),1001(agent-common)
```

# 4. 디렉토리 구조 및 권한(ACL 포함) 확인 내역
```bash
getfacl /home/agent-admin/agent-app
getfacl /home/agent-admin/agent-app/upload_files
getfacl /home/agent-admin/agent-app/api_keys
getfacl /home/agent-admin/agent-app/bin

getfacl /var/log/agent-app
```
```bash
root@1ce3142e27f6:~# getfacl /home/agent-admin/agent-app

getfacl: Removing leading '/' from absolute path names
# file: home/agent-admin/agent-app
# owner: agent-admin
# group: agent-core
user::rwx
group::r-x
other::r-x

root@1ce3142e27f6:~# getfacl /home/agent-admin/agent-app/upload_files

getfacl: Removing leading '/' from absolute path names
# file: home/agent-admin/agent-app/upload_files
# owner: agent-admin
# group: agent-common
# flags: -s-
user::rwx
group::rwx
other::---
default:user::rwx
default:group::rwx
default:group:agent-common:rwx
default:mask::rwx
default:other::---

root@1ce3142e27f6:~# getfacl /home/agent-admin/agent-app/api_keys

getfacl: Removing leading '/' from absolute path names
# file: home/agent-admin/agent-app/api_keys
# owner: agent-admin
# group: agent-core
# flags: -s-
user::rwx
group::rwx
other::---
default:user::rwx
default:group::rwx
default:group:agent-core:rwx
default:mask::rwx
default:other::---

root@1ce3142e27f6:~# getfacl /home/agent-admin/agent-app/bin

getfacl: Removing leading '/' from absolute path names
# file: home/agent-admin/agent-app/bin
# owner: agent-admin
# group: agent-core
# flags: -s-
user::rwx
group::r-x
other::---

root@1ce3142e27f6:~# getfacl /var/log/agent-app

getfacl: Removing leading '/' from absolute path names
# file: var/log/agent-app
# owner: agent-admin
# group: agent-core
# flags: -s-
user::rwx
group::rwx
other::---
default:user::rwx
default:group::rwx
default:group:agent-core:rwx
default:mask::rwx
default:other::---
```

# 5. 앱 Boot Sequence 5단계 [OK] 및 “Agent READY” 확인 내역

```bash
# 5-1. 파이썬 앱 정상 실행 프로세스 소유자 및 명령어 라인 확인
ps -eo user,group,args | grep agent-app.py

# 5-2. 앱 서비스 포트(15034) LISTEN 상태 확인
ss -tulnp | grep :15034
```
```bash
root@1ce3142e27f6:~# ps -eo user,group,args | grep agent-app.py

root     root     grep --color=auto agent-app.py

root@1ce3142e27f6:~# ss -tulnp | grep :15034

tcp   LISTEN 0      1            0.0.0.0:15034      0.0.0.0:*    users:(("agent-app",pid=5536,fd=4))
```

# 6. monitor.sh 실행 결과(프로세스/포트/리소스/경고) 내역
```bash
# 6-1. monitor.sh 파일의 소유자(agent-dev), 그룹(agent-core), 권한(750) 상태 확인
ls -la /home/agent-admin/agent-app/bin

# 6-2. 스크립트 수동 실행 테스트 및 정상 로깅 알림 확인
bash /home/agent-admin/agent-app/bin/monitor.sh
```
```bash
agent-admin@69eb134fdfb8:~$ ls -la /home/agent-admin/agent-app/bin

total 4
drwxr-s--- 1 agent-admin agent-core   20 Jun  9 09:18 .
drwxr-xr-x 1 agent-admin agent-core   64 Jun  9 09:18 ..
-rwxr-x--- 1 agent-dev   agent-core 1844 Jun  9 09:18 monitor.sh

agent-admin@69eb134fdfb8:~$ bash /home/agent-admin/agent-app/bin/monitor.sh

UFW_STATUS: Status: active
로그용 : [2026-06-09 09:23:28] PID:4951,4952,5098,5100 CPU:1.6% MEM:3.5% DISK_USED:1%
```

# 7. /var/log/agent-app/monitor.log 누적 기록 확인(최근 라인) 내역
```bash
# 7-1. 수집 로그 파일 내용 및 최근 누적 데이터 출력
cat /var/log/agent-app/monitor.log | tail -n 5
```
```bash
[2026-06-09 13:16:01] [ERROR] agent-app process is not running.
[2026-06-09 13:17:01] [ERROR] agent-app process is not running.
[2026-06-09 13:18:01] [ERROR] agent-app process is not running.
[2026-06-09 13:19:01] [ERROR] agent-app process is not running.
[2026-06-09 13:20:01] PID:4966,4967 CPU:0% MEM:4.0% DISK_USED:1%
```

# 8. crontab 매분 실행 등록 및 자동 실행 확인(1분 후 로그 증가) 내역
```bash
# 8-1. agent-admin 계정의 crontab 등록 내용 확인
sudo -u agent-admin crontab -l

# 8-2. 1분 주기 자동 실행 여부 모니터링 (실행 후 데이터 실시간 증가 확인)
# 켜두고 1~2분 대기하면 로그가 자동으로 계속 올라오는 것을 볼 수 있습니다.
tail -f /var/log/agent-app/monitor.log
```
```bash
root@04d0b9b73c70:~# sudo -u agent-admin crontab -l

AGENT_LOG_DIR=/var/log/agent-app
* * * * * bash /home/agent-admin/agent-app/bin/monitor.sh

root@04d0b9b73c70:~# tail -f /var/log/agent-app/monitor.log

[2026-06-09 13:16:01] [ERROR] agent-app process is not running.
[2026-06-09 13:17:01] [ERROR] agent-app process is not running.
[2026-06-09 13:18:01] [ERROR] agent-app process is not running.
[2026-06-09 13:19:01] [ERROR] agent-app process is not running.
[2026-06-09 13:20:01] PID:4966,4967 CPU:0% MEM:4.0% DISK_USED:1%
[2026-06-09 13:21:01] PID:4966,4967 CPU:0% MEM:2.8% DISK_USED:1%
[2026-06-09 13:22:01] PID:4966,4967 CPU:0% MEM:3.7% DISK_USED:1%
[2026-06-09 13:23:01] PID:4966,4967 CPU:0% MEM:3.3% DISK_USED:1%
[2026-06-09 13:24:01] PID:4966,4967 CPU:0% MEM:3.3% DISK_USED:1%
```

# 9. 환경변수 체크
```bash
export | grep AGENT_
```
```bash
agent-dev@53ff7e734267:~$ export | grep AGENT_

declare -x AGENT_HOME="/home/agent-admin/agent-app"
declare -x AGENT_KEY_PATH="/home/agent-admin/agent-app/api_keys"
declare -x AGENT_LOG_DIR="/var/log/agent-app"
declare -x AGENT_PORT="15034"
declare -x AGENT_UPLOAD_DIR="/home/agent-admin/agent-app/upload_files"
```

# 10. 실행 로그
```bash
root@f538ee2d99cf:~# su - agent-admin
agent-admin@f538ee2d99cf:~$ cd
agent-admin@f538ee2d99cf:~$ ./agent-app/agent-app
>>> Starting Agent Boot Sequence...
[1/5] Checking User Account               [OK]
   ... Running as service user 'agent-admin' (uid=1002)
[2/5] Verifying Environment Variables     [OK]
   ... All required Envs correct
[3/5] Checking Required Files             [OK]
   ... Verified 'secret.key' with correct key string.
[4/5] Checking Port Availability          [OK]
   ... Port 15034 is available.
[5/5] Verifying Log Permission            [OK]
   ... Log directory is writable: /var/log/agent-app
------------------------------------------------------------
All Boot Checks Passed!
Agent READY
```