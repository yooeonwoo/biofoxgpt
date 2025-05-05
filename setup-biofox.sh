#!/bin/bash

# BIOFOX Agent 설치 스크립트
# 필요한 디렉토리 생성 및 Docker Compose 실행

# 데이터 디렉토리 생성
echo "데이터 디렉토리를 생성합니다..."
mkdir -p /home/biofoxdata/data-node
mkdir -p /home/biofoxdata/meili_data_v1.12
mkdir -p /home/biofoxdata/pgdata2
mkdir -p /home/biofoxdata/images
mkdir -p /home/biofoxdata/uploads
mkdir -p /home/biofoxdata/logs

# 기존 컨테이너 정리 (있는 경우)
echo "기존 컨테이너를 정리합니다..."
docker compose down
docker network rm biofoxagent_biofox-network 2>/dev/null || true

# Docker Compose 실행
echo "Docker Compose로 BIOFOX Agent를 시작합니다..."
docker compose up -d

# 상태 확인
echo "컨테이너 상태 확인:"
docker ps

echo "BIOFOX Agent 설치가 완료되었습니다!"
echo "웹사이트는 http://152.42.225.142:3081 에서 접속할 수 있습니다."