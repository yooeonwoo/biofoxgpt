#!/bin/bash

# Pull all required Docker images for BIOFOX Agent deployment
# This script helps to download all images before deployment
# to avoid timeouts or network issues during the actual deployment

echo "Pulling Docker images for BIOFOX Agent deployment..."

# MongoDB
echo "Pulling MongoDB image..."
docker pull mongo

# MeiliSearch
echo "Pulling MeiliSearch image..."
docker pull getmeili/meilisearch:v1.12.3

# pgvector (PostgreSQL with vector extension)
echo "Pulling pgvector image..."
docker pull ankane/pgvector:latest

# RAG API
echo "Pulling RAG API image..."
docker pull ghcr.io/danny-avila/librechat-rag-api-dev-lite:latest

# BIOFOX Agent (LibreChat)
echo "Pulling BIOFOX Agent image..."
docker pull ghcr.io/danny-avila/librechat-dev:latest

echo "All images have been successfully pulled!"
echo "You can now run the deployment script."