# Dockerfile

# Python 3.11의 slim 버전을 기반 이미지로 사용, 용량을 줄여 ECR 푸시 속도 개선 가능함
FROM python:3.11-slim

# Working Dir을 컨테이너 내부에서 작업할 디렉토리(/app) 설정
WORKDIR /app

# requirements.txt 파일 복사해서 의존성 설치
COPY requirements.txt .

# --no-cache-dir을 사용하면 pip 캐시를 사용하지 않아 이미지 용량 절약 가능
# pip는 Python 패키지를 설치하고 관리하는 패키지 매니저임
RUN pip install --no-cache-dir -r requirements.txt

# 프로젝트의 모든 파일을 작업 디렉토리로 복사
COPY . .

# 애플리케이션이 외부로 노출될 포트 지정 8080 => Flask
EXPOSE 8080

# 컨테이너가 시작될 때 실행할 기본 명령 정의
# Flask 환경 변수 설정을 위한 flask run 명령 사용
CMD ["flask","run","--host=0.0.0.0","--port=8080"]
