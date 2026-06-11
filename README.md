
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