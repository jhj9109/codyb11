# 1. 베이스 이미지 지정
FROM ubuntu:22.04

# 2. 환경 변수 설정 (설치 중 거주지/시간대 선택 팝업창 뜨는 것 방지)
ENV DEBIAN_FRONTEND=noninteractive

# 3. 작업 디렉토리 설정 및 스크립트 파일들 복사
WORKDIR /root
COPY scripts/ /root/scripts/
COPY entrypoint.sh /root/entrypoint.sh
COPY agent-app/agent-app-linux-x86 /root/agent-app

# 4. 모든 스크립트 파일에 실행 권한 부여 및 줄바꿈 기호(CRLF) 방어
RUN chmod +x /root/entrypoint.sh /root/scripts/*.sh

# 5. 컨테이너가 시작될 때 마스터 스크립트 자동 실행
ENTRYPOINT ["/root/entrypoint.sh"]