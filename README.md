
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

## 10. 심층 엔지니어링 분석 및 트러블슈팅 가이드

### 10.1 리소스 수집 메커니즘 및 로그 포맷의 정형화 이유 (평가기준 10)
관제 스크립트(`monitor.sh`) 내부에서 시스템 자원 지표를 수집하고 정형화된 포맷으로 기록하기 위해 채택한 상세 파싱 메커니즘과 그 설계 의도는 다음과 같습니다.

1. **CPU 사용률 추출 방식**
   - **명령어:** `top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}'`
   - **메커니즘:** `top` 명령어를 배치 모드(`-b`)로 1회만(`-n1`) 실행하여 순시적인 CPU 상태 스냅샷을 확보합니다. 이후 `awk` 연산을 통해 유저 공간 실행 비율(`$2`, us)과 커널 공간 실행 비율(`$4`, sy)을 산술 더하기하여 전체 활성 CPU 부하량을 정확하게 파싱합니다.
2. **Memory 사용률 추출 방식**
   - **명령어:** `free | awk '/Mem/ {printf("%.1f", $3/$2 * 100.0)}'`
   - **메커니즘:** `free` 명령어 출력 중 실제 메모리 행(`/Mem/`)을 정규식 매칭하여 타겟팅합니다. 전체 가용한 물리 메모리 분모(`$2`) 대비 현재 운영체제 및 프로세스에 의해 사용 중인 메모리 분자(`$3`)의 비율을 계산한 뒤, 소수점 한 자리 형식으로 정규화합니다.
3. **Disk 사용률 추출 방식**
   - **명령어:** `df / | awk '/\// {print $5}' | sed 's/%//'`
   - **메커니즘:** 루트 디렉토리(`/`)의 디스크 공간을 조회한 뒤, 파일 시스템 경로 분기점에 강한 포맷 매칭을 유도하여 5번째 필드인 사용률(`$5`)을 안전하게 낚아챕니다. 최종적으로 `sed`를 이용해 크기 비교 연산에 방해가 되는 퍼센트 기호(`%`)를 전처리 세척합니다.
4. **로그 포맷을 `[YYYY-MM-DD HH:MM:SS] PID:...` 형태로 고정해야 하는 운영상 이유**
   - **시계열 분석의 용이성:** 날짜와 시간 서식을 대괄호`[]` 내부의 고정 폭 문자열로 통제하여, 향후 분산 로그 수집기(Fluentd, Logstash 등)나 통계 분석 스크립트(`report.sh`)가 타임스탬프 스크리닝 연산을 수행할 때 토큰 분리(Tokenization) 효율을 극대화합니다.
   - **정형 데이터 파싱 구조:** 공백(Space)을 확실한 구분자(Delimiter)로 배치하여 `awk '{print $4}'`와 같이 정해진 인덱스 번호만으로 원하는 매트릭 데이터에 오차 없이 접근할 수 있도록 보장하는 설계 표준입니다.

---

### 10.2 위협 모델 관점에서의 인프라 보안 요새화 (평가기준 13, 14)

#### ① SSH 포트 변경 및 Root 원격 접속 차단 효과 (위협 모델링 분석)
- **무차별 대입 공격(Brute-Force) 무력화:** 공인 인터넷 환경에 노출된 서버의 표준 포트 `22`번은 자동화된 악성 봇넷(Botnet)의 지속적인 타겟입니다. 포트를 비표준 포트(`20022`)로 변경하는 포트 난독화(Port Obfuscation) 기법만으로도 Mass Scanning 공격 시도의 99% 이상을 원천 차단하는 방어 효과를 가집니다.
- **공격 표면(Attack Surface) 축소:** 최고 권한 계정인 `root`로의 직접 원격 로그인을 차단(`PermitRootLogin no`)하면 공격자는 1차적으로 일반 사용자 계정을 탈취한 뒤 2차 권한 상승(Privilege Escalation) 단계를 추가로 거쳐야 합니다. 이 다중 방어선(Defense in Depth) 구조는 해킹 단계를 물리적으로 배가시킬 뿐만 아니라, 일반 유저 세션의 `/var/log/auth.log` 감시를 통해 명확한 침적 감사 추적 궤적(Audit Trail)을 남길 수 있게 만듭니다.

#### ② api_keys 및 로그 디렉토리 권한 제한과 '최소 권한의 원칙'
- **최소 권한의 원칙(Principle of Least Privilege) 적용:** 시스템 내의 특정 구성 요소나 유저는 오직 맡은 바 직무를 수행하는 데 필요한 필수 불가결한 권한만을 소유해야 한다는 원칙입니다.
- **수행 이유:** 서비스 구동용 민감 데이터인 API 키 정보 파일과 인프라 동작 상태를 고스란히 담고 있는 로그 파일들은 시스템의 기밀성(Confidentiality)에 직결됩니다. 만약 이 폴더들이 일반 유저(`Others`)에게 공개되어 있다면, 로컬 유저 권한을 획득한 공격자가 인프라 구조를 쉽게 정찰(Reconnaissance)하여 횡적 이동(Lateral Movement) 공격으로 이어갈 수 있습니다. 따라서 전용 운영 그룹인 `agent-core`로 소유 그룹을 엄격히 제한하고 권한 장벽을 세우는 것이 시스템 무결성을 방어하는 정석 아키텍처입니다.

---

### 10.3 관제 시스템의 예외 처리 및 쉘 리다이렉션 운영 철학 (평가기준 15, 16)

#### ① "경고 출력 후 계속 진행" 항목을 분리한 운영상의 목적
- **가용성 중심의 모니터링 시스템 구축:** 방화벽의 비활성화 상태나 특정 자원 임계치 초과(예: CPU 사용량 20% 초과) 현상은 시스템이 아예 멈춰버린 '치명적 장애(Fatal Error)'가 아닌, 모니터링을 유지하며 운영자에게 시급히 전파해야 하는 '운영 알람(Warning Alert)' 영역입니다.
- 만약 이 단계에서 스크립트를 `exit 1`로 완전 종료 시켜버린다면, **가장 부하가 높고 위험한 순간에 관제 시스템 데몬 자체가 다운되어 인프라의 눈이 멀어버리는(Observability 유실) 대참사**가 일어납니다. 따라서 헬스 체크 실패 시에만 프로세스를 즉시 탈출시키고, 임계치 초과는 알람만 파일에 적재한 채 관제 루프를 유지하는 구조로 엄격히 이원화 설계하였습니다.

#### ② 리다이렉션 기호 `>` 와 `>>` 의 근본적 차이 및 로그 누적의 당위성
- **`>` (Overwrite, 덮어쓰기):** 대상 파일을 열 때 기존 내용물을 완전히 잘라내어 0바이트로 초기화(Truncate)한 뒤, 오직 새로 유입된 텍스트 스트림만 기록합니다.
- **`>>` (Append, 이어쓰기):** 파일의 끝(End-of-File) 마커 위치로 파일 포인터를 이동시켜 기존 이력을 완벽히 보존한 채 하단에 로그 세션을 누적 추가합니다.
- **로그 유실 방지 수단:** 로그 데이터는 시간에 따른 인프라 변동 추이를 분석하고 사후 포렌식을 수행하기 위한 '역사적 기록 증거물'입니다. 관제 스크립트가 실행될 때마다 `>`를 사용하여 이전 데이터를 지워버린다면 요약 리포트(`report.sh`)가 기간별 통계를 연산하는 행위 자체가 불가능해지므로 지속적인 누적을 보장하는 `>>` 연산자가 필수적입니다.

---

### 10.4 장애 전파 및 트러블슈팅 가상 시나리오 분석 (평가기준 17, 18, 19)

#### ① 모니터링 대상이 웹 서버(Nginx 등)로 변경될 시 핵심 수정 포인트 (평가기준 17)
관제 아키텍처 파이프라인의 이식성(Portability)을 극대화하기 위해 웹 서버 타겟팅 시 다음과 같은 핵심 모듈러 레이아웃을 전면 수정합니다.
1. **프로세스 식별명 변경:** `pgrep -x "agent-app"` 마스터 패턴을 `pgrep -x "nginx"` 또는 Nginx Master/Worker 구조를 명확히 판별할 수 있는 정규식 경계로 치환합니다.
2. **포트 체크 넘버 변경:** 커스텀 포트 `15034` 감시 모듈을 정식 HTTP/HTTPS 규격 서비스 포트인 `80` 또는 `443`으로 리매핑합니다.
3. **특화 지표 및 로그 파싱:** 단순 시스템 자원 수집을 넘어, Nginx의 `stub_status` 메트릭 엔드포인트를 찔러 활성 연결 수(Active Connections), 요청 처리율(Req/Sec) 데이터를 파싱하도록 파이프라인을 고도화합니다.
4. **임계값 튜닝:** 정적 뼈대 코드 위주의 웹 서버는 파일 디스크 소모 임계치보다 대량의 소켓 커넥션을 동시 수용해야 하므로 CPU/MEM 임계치 장벽을 더 높게 설정하고, 추가적으로 에러 로그(`5xx Error Count`) 임계치를 관제 스크립트 내에 새로 인입해야 합니다.

#### ② "프로젝트 프로세스는 생존해 있으나 포트 오픈이 실패한 상황" 장애 분석 (평가기준 18)
시스템 모니터링 중 프로세스 ID(PID)는 잡히는데 `ss -tuln` 결과창에 해당 포트가 누락되어 있다면 다음 원인 후보군을 순서대로 추적 디버깅합니다.

* **예상 장애 원인 후보군:**
  1. **애플리케이션 데드락 (Application Hang):** Python 등 메인 백엔드 런타임 내부의 부트 시퀀스 코드 연산 도중 무한 루프나 데드락, 혹은 커넥션 풀(Pool) 고갈 현상이 발생해 포트 바인딩(`bind()`) 단계까지 진입하지 못하고 락이 걸린 상태.
  2. **네트워크 바인딩 설정 미스:** 내부 소스코드 상에서 수신 대기 인터페이스 주소를 `0.0.0.0`(모든 인터페이스)이 아닌 `127.0.0.1`(로컬 루프백)로 묶어두어 외부 네트워크 대역 검측에서 포트가 닫힌 것처럼 오인되는 현상.
  3. **포트 충돌 경합 사태:** 다른 유령 프로세스나 데몬이 이미 `15034` 포트를 선점하고 있어서 우리 앱이 소켓 초기화 실패 후 좀비 프로세스 상태로 껍데기만 잔존한 현상.
* **시니어 엔지니어의 정석 트러블슈팅 추적 순서:**
  1. `tail -n 100 /var/log/agent-app/agent.log` 명령어로 애플리케이션의 런타임 에러 로그 및 예외 스택 트레이스(Stack Trace)를 가장 먼저 수사합니다.
  2. `ss -lptn | grep ":15034"` 를 구동해 다른 PID가 포트를 선점 중인지 네트워크 소켓 레이어를 점검합니다.
  3. `strace -p [PID]` 커맨드로 현재 살아있는 좀비 프로세스가 어느 시스템 콜(System Call) 구간에서 멈춰 멈춤(Hang) 상태가 되었는지 리눅스 커널 레벨에서 최종 격리 심문합니다.

#### ③ 급격한 로그 증가로 인한 디스크 풀(Full) 장애 대응 가이드 (평가기준 19)
관제 데이터가 무한정 팽창하여 스토리지 임계치 장벽(80%)을 무너뜨리고 100% 임박 사태를 유발했을 때 운영자가 취해야 할 정석 타임라인별 조치 계획입니다.

* **🚨 단기적 비상 조치 계획 (즉각적인 서비스 다운 방어):**
  - **로그 임시 강제 수동 순환:** `bash /home/agent-admin/agent-app/bin/log_manager.sh` 명령어를 즉시 수동 수동 가동하여 산재한 과거 원본 로그를 gzip 압축본으로 강제 전환, 수 기가바이트의 공간을 1초 만에 확보합니다.
  - **시스템 가비지 세척:** `apt-get clean` 및 `/tmp` 폴더 하단의 임시 찌꺼기 텍스트 파일들을 청소하여 운영체제가 커널 패닉에 빠지지 않도록 최소 숨통 공간을 강제 개척합니다.
* **🎯 중·장기적 구조적 개선 계획 (근본적인 아키텍처 패치):**
  - **로그 관리 보존 주기(Retention Policy) 강화:** `log_manager.sh` 내부의 보존 기한을 기존 30일 보관에서 `14일 보관`으로 엄격하게 하향 튜닝하여 상시 디스크 사용 스케일을 낮춥니다.
  - **외부 독립 스토리지 백적재 배포:** 아카이브 디렉토리 경로(`/var/log/monitor/agent-app/archive`)를 메인 OS 디스크 영역에서 분리하여, 별도의 외장 볼륨 파티션(AWS Elastic Block Store 등)으로 마운트 이격 하거나, 주기적으로 AWS S3 같은 오브젝트 스토리지로 로그를 쉽핑(Log Shipping)한 뒤 로컬 디스크에서는 완전히 날려버리는 클라우드 네이티브 인프라 구조로 고도화 배포를 진행합니다.

  ### 10.5 관제 스크립트의 포트 확인 명령어(`ss`) 선택 이유 (평가기준 9 보완)

관제 스크립트(`monitor.sh`) 내부에서 포트 바인딩 상태를 검측할 때, 레거시 명령어인 `netstat` 대신 현대 리눅스 표준인 **`ss` (Socket Statistics)** 명령어를 채택한 아키텍처적 이유는 다음과 같습니다.

- **커널 구조 기반의 압도적인 속도 차이:** 기존 `netstat`은 실행될 때마다 `/proc` 디렉토리 하위에 존재하는 수많은 파일들을 순차적으로 읽어 파싱하므로, 시스템의 연결 수가 많을수록 심각한 병목(Overhead)을 유발합니다. 반면 `ss` 커널 내부의 네트워크 상태를 직접 관리하는 **Netlink API**와 통신하여 데이터를 즉시 가져오므로 연산 속도와 리소스 효율이 압도적으로 우수합니다.
- **관제 환경 최적화:** 1분 주기로 쉴 새 없이 백그라운드에서 구동되어야 하는 `cron` 기반 관제 스크립트 특성상, 찰나의 성능 저하나 CPU 스파이크도 허용해서는 안 됩니다. 따라서 가장 가볍고 효율적인 `ss -lptn` 커맨드를 파이프라인 전위에 배치하여, 애플리케이션의 헬스 체크가 시스템에 미치는 영향을 최소화(Zero-impact) 하였습니다.

---

### 10.6 소유자/실행자 권한 분리(SoD) 설계 메커니즘 (평가기준 11 보완)

`monitor.sh` 파일에 대해 소유자를 `agent-dev`, 소유 그룹을 `agent-core`로 지정하고 권한을 `750(rwxr-x---)`으로 설정한 것은, 단순한 권한 부여를 넘어 정보보안의 핵심인 **'직무 분리(Separation of Duties, SoD)'** 원칙을 완벽히 만족시키기 위함입니다.

1. **소유자 (agent-dev) - 개발 주체 [rwx]**
   - 개발 권한을 가진 `agent-dev` 계정에게만 유일하게 쓰기(`w`) 권한을 부여했습니다. 이를 통해 오직 허가된 개발자만이 관제 로직을 수정하거나 패치할 수 있도록 코드의 무결성을 보장합니다.
2. **실행자 그룹 (agent-core) - 운영 주체 [r-x]**
   - 스크립트를 주기적으로 실행해야 하는 `agent-admin` 계정 및 `cron` 데몬은 `agent-core` 그룹에 속하게 하여 읽기 및 실행(`r-x`) 권한만을 부여받습니다. 
   - **설계 핵심:** 운영자는 스크립트를 원활히 가동할 수 있지만, **코드 내부 로직을 임의로 변조하거나 삭제할 권한(`w`)은 원천 차단**됩니다. 이는 운영 과정에서 발생할 수 있는 휴먼 에러나 악의적인 내부자 위협(Insider Threat)으로부터 시스템을 보호합니다.
3. **기타 외부인 (Others) - 접근 차단 [---]**
   - 시스템에 침투한 일반 공격자나 무관한 계정은 관제 스크립트의 존재 자체를 열람할 수 없게 하여 정찰 공격(Reconnaissance)을 방어합니다.

이러한 `750` 권한 체계는 개발자(Dev)와 인프라 운영자(Ops) 간의 역할과 책임을 OS 파일 시스템 레벨에서 물리적으로 강제 격리하는 가장 안정적인 운영 표준입니다.