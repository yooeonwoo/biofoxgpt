#!/bin/bash

# BIOFOX Agent Deployment Script for DigitalOcean
# This script replaces docker-compose functionality with individual Docker commands
# Target IP: 152.42.225.142

# Exit on error
set -e

echo "Starting BIOFOX Agent deployment on DigitalOcean..."

# Create directories for persistent storage
mkdir -p ./data-node
mkdir -p ./meili_data_v1.12
mkdir -p ./pgdata2
mkdir -p ./images
mkdir -p ./uploads
mkdir -p ./logs

# Get current user ID and group ID for container permissions
export UID=$(id -u)
export GID=$(id -g)
export RAG_PORT=8000

# Create Docker network for containers to communicate
echo "Creating Docker network: biofox-network"
docker network create biofox-network || echo "Network already exists"

# Pull and start MongoDB container
echo "Starting MongoDB container..."
docker run -d \
  --name biofox-mongodb \
  --network biofox-network \
  --restart always \
  --user "${UID}:${GID}" \
  -v "$(pwd)/data-node:/data/db" \
  mongo \
  mongod --noauth

# Pull and start Meilisearch container
echo "Starting Meilisearch container..."
docker run -d \
  --name biofox-meilisearch \
  --network biofox-network \
  --restart always \
  --user "${UID}:${GID}" \
  -e "MEILI_HOST=http://biofox-meilisearch:7700" \
  -e "MEILI_NO_ANALYTICS=true" \
  -e "MEILI_MASTER_KEY=${MEILI_MASTER_KEY}" \
  -v "$(pwd)/meili_data_v1.12:/meili_data" \
  getmeili/meilisearch:v1.12.3

# Pull and start PostgreSQL with pgvector
echo "Starting PostgreSQL container with pgvector..."
docker run -d \
  --name vectordb \
  --network biofox-network \
  --restart always \
  -e "POSTGRES_DB=mydatabase" \
  -e "POSTGRES_USER=myuser" \
  -e "POSTGRES_PASSWORD=mypassword" \
  -v "$(pwd)/pgdata2:/var/lib/postgresql/data" \
  ankane/pgvector:latest

# Pull and start RAG API container
echo "Starting RAG API container..."
docker run -d \
  --name biofox-rag-api \
  --network biofox-network \
  --restart always \
  -e "DB_HOST=vectordb" \
  -e "RAG_PORT=${RAG_PORT}" \
  --env-file .env \
  --link vectordb:vectordb \
  ghcr.io/danny-avila/librechat-rag-api-dev-lite:latest

# Pull and start BIOFOX Agent API container
echo "Starting BIOFOX Agent container..."
docker run -d \
  --name BIOFOX-Agent \
  --network biofox-network \
  -p 3081:3081 \
  --restart always \
  --user "${UID}:${GID}" \
  --add-host=host.docker.internal:host-gateway \
  -e "HOST=0.0.0.0" \
  -e "MONGO_URI=mongodb://biofox-mongodb:27017/BIOFOX" \
  -e "PORT=3081" \
  -e "MEILI_HOST=http://biofox-meilisearch:7700" \
  -e "RAG_PORT=${RAG_PORT}" \
  -e "RAG_API_URL=http://biofox-rag-api:${RAG_PORT}" \
  -v "$(pwd)/.env:/app/.env" \
  -v "$(pwd)/images:/app/client/public/images" \
  -v "$(pwd)/uploads:/app/uploads" \
  -v "$(pwd)/logs:/app/api/logs" \
  ghcr.io/danny-avila/librechat-dev:latest

# Ensure containers are running in the correct order
echo "Ensuring all containers are running properly..."
# Give PostgreSQL time to initialize
sleep 10
docker restart biofox-rag-api

echo "Deployment completed successfully!"
echo "BIOFOX Agent is accessible at http://152.42.225.142:3081"
echo ""
echo "Container status:"
docker ps

# Health check commands
echo ""
echo "You can check logs with:"
echo "docker logs BIOFOX-Agent"
echo "docker logs biofox-mongodb"
echo "docker logs biofox-meilisearch"
echo "docker logs vectordb"
echo "docker logs biofox-rag-api"