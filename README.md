
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

## 4. 시스템 관제 및 로그 자동 관리 아키텍처 (고도화)

### 4.2 프로세스 오검출 및 중복 매핑 필터링 (`monitor.sh`)
- **이슈:** `pgrep -f "agent-app"` 방식으로 PID를 수집할 경우, 관제 스크립트(`agent-app/bin/monitor.sh`) 자체의 실행 경로에 동일한 키워드가 포함되어 **'자기 자신을 프로세스로 오검출'**하여 무한 루프나 누적 통계 왜복을 유발하는 결함 발견.
- **해결 및 정밀 제어 (Regex Anchor & Exact Match):**
  - 명령어 문자열의 끝을 지정하는 정규표현식 앵커(`$`) 기호를 사용하여 `agent-app$` 형태의 매칭 경계를 수립하거나, `pgrep`의 `-x` (Exact Match) 옵션을 결합.
  - 실행 파일명이 정확히 `agent-app`과 일치하는 프로세스만 핀포인트로 저격 수집하도록 로직을 교정하여 시스템 관측(Observability) 무결성 확보.

---

## 5. [보너스 1] 요약 리포트 자동 생성 (`report.sh`)

### 5.1 기능 요구사항
- `monitor.log`를 분석하여 수집된 CPU, Memory, Disk 자원의 **평균(AVG) / 최대(MAX) / 최소(MIN)** 수치와 총 데이터 샘플 수를 콘솔에 출력.
- CLI 인자(`-s` 시작시간, `-e` 종료시간)를 입력받아 특정 타임윈도우(Time-Window) 구간의 로그만 필터링하는 파싱 기능 내장.

### 5.2 awk 기반 통계 연산 및 트러블슈팅
- **`awk` 타임스탬프 스크리닝:** 리눅스 쉘 환경에서 복잡한 날짜 연산 라이브러리 없이, `YYYY-MM-DD HH:MM:SS` 서식이 문자열 사전순(Lexicographical Order)으로 정렬 및 대소 비교가 가능하다는 특성을 활용해 정밀 필터링 구현.
- **Division by Zero 방어:** 조건에 맞는 데이터 샘플 수가 0개일 때 분모가 0이 되어 연산 오류(`NaN`)로 스크립트가 폭파되는 현상을 방지하기 위해, `END` 블록 진입 시 `if (count == 0)` 예외 처리 검문소 구축.
- **변수 배달 사고 디버깅:** 최초 빌드 시 `printf` 포맷 출력부의 오타(Human Error)로 인해 디스크 통계 자리에 CPU 변수(`cpu_max`, `cpu_min`)가 잘못 매핑되어 통계 모순이 발생하는 버그 발견 및 정확한 컨텍스트 매핑으로 최종 교정 완료.

---

## 6. [보너스 2] 로그 라이프사이클 관리 (`log_manager.sh`)

### 6.1 용량 기반 무중단 순환 (`copytruncate` 구현)
- `monitor.log` 단일 파일 용량이 10MB를 초과할 경우 백업본을 생성하고 최대 10개까지 순환 스케일 유지 (`monitor_1.log` ~ `monitor_10.log`).
- **무중단 운영 방어선:** `mv` 명령어로 파일을 치우면 앱 프로세스가 기존 파일 디스크립터(FD) 잃고 뻗는 문제를 방지하기 위해, 표준 `copytruncate` 아키텍처 패턴을 차용. `cp`로 스냅샷을 뜬 후 `> monitor.log` 꺾쇠 연산으로 원본 내용을 0바이트로 깎아 가용성(Availability) 확보.
- **네이밍 룰의 연계 설계:** 백업본 이름을 `monitor_1.log` 형태로 매핑하여, 하단의 '7일 경과 로그 압축 정규식(`*.log`)'에 별도 조건문 없이 자연스럽게 걸려들도록 결합도 최적화.

### 6.2 시간 기반 아카이브 및 파기 정책 (Hot ➔ Warm ➔ Cold)
- **7일 경과 압축 (Warm):** `find $LOG_DIR -mtime +7 -name "*.log"` 패턴을 추적하여 일주일이 지난 로그는 `gzip`으로 압축 후 별도의 격리 폴더인 `/var/log/monitor/agent-app/archive/` 로 이동시켜 최신 로그 관측 시야 확보.
- **30일 경과 파기 (Cold):** 아카이브 내 생성된 지 30일이 초과된 `.gz` 압축본은 `find` 정책에 의해 자동으로 영구 파기(`rm -f`) 처리되어 디스크 풀(Full)로 인한 OS 마비 사태 방지.

### 6.3 비대화형(Non-Interactive) 크론 환경 트러블슈팅 기법
- **환경 변수 격리 유실(범인 추적):** 터미널 수동 실행과 달리, `cron` 데몬은 사용자의 `.bashrc` 프로필을 로드하지 않는 비로그인 진공 쉘 상태에서 스크립트를 찌름.
- 이로 인해 `$AGENT_LOG_DIR` 변수가 공백(`""`)이 되면서 엄격 모드(`set -u`) 경고에 걸려 스크립트가 첫 1초 만에 비명횡사하던 고질적인 크론 작동 정지 버그 격리 성공.
- **최종 무결성 패치:** 크론탭 명세 자체의 상단 영역에 static하게 환경 변수를 직접 바인딩하여 주입하는 IaC(Infrastructure as Code) 정석 패턴으로 변수 유실 철벽 방어 성공.

---

## 7. 가상 샌드박스 자동 단위 테스트 (`test_log_manager.sh`)

- **경계값 검증 (Boundary Value Testing):** 순환 한계점인 10개를 완벽하게 테스트하기 위해 일부러 11개의 11MB 대용량 더미 파일을 `dd if=/dev/zero` 커맨드로 쏟아부어 밀어내기 한계선 검증.
- **날짜 그라데이션 시뮬레이션:** 실제 시간이 흐르길 기다릴 수 없으므로 리눅스 커널 메타데이터를 조작하는 `touch -d "8/16/24/32 days ago"` 명령어를 통해 시간 여행 환경 구축. 30일이 지난 32일 차 아카이브 파일만 정확하게 '표적 저격 삭제'되고 나머지 보존 대상 파일들은 무사히 살아남는지 교차 검증(True Negative Check) 완료.
- **대기 프롬프트 (`PAUSE`) 인프라 시각화:** 세팅 직후와 매니저 가동 직전 단계 사이에 사용자의 입력(`read`)을 기다리는 홀딩 구간을 설정. 다른 터미널에서 `ls -lh`로 파일 시스템의 Before / After 변화를 운영자가 생생하게 관측할 수 있도록 엔지니어링 편의성 극대화.

---

## 8. 도커 환경에서의 데이터 영속성(Persistence) 고찰

- 도커 컨테이너는 기본적으로 **'일회성(Ephemeral/Stateless)'** 구조를 가짐. 뼈대인 Read-Only 이미지 위에 쓰기 가능한 임시 스케치북(Writable Layer)이 얹어지는 형태임.
- `docker compose stop`은 프로세스만 멈추므로 데이터가 유지되나, `docker compose down`을 실행하는 순간 컨테이너 격리 장벽이 완전 파기되며 내부 스케치북에 쌓였던 `monitor.log` 결과물들이 통째로 쓰레기통으로 증발함.
- **결론 및 아키텍처 패턴:** 관제 시스템의 연속성과 데이터 거버넌스를 보장하기 위해, `docker-compose.yml` 볼륨 설정을 통해 컨테이너 내부 로그 경로를 호스트 하드디스크 디렉토리와 파이프라인으로 묶는 **'볼륨 마운트 영속성 처리'**의 당위성을 완벽하게 증명 및 확보함.