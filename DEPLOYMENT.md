# BIOFOX Agent Deployment to DigitalOcean

This guide provides instructions for deploying BIOFOX Agent to a DigitalOcean server.

## Prerequisites

- DigitalOcean server (Droplet) running Ubuntu (IP: 152.42.225.142)
- Docker and Git installed on the server
- SSH access to the server

## Deployment Steps

1. Connect to your DigitalOcean server:

```bash
ssh root@152.42.225.142
```

2. Create a deployment directory:

```bash
mkdir -p /opt/biofoxagent
cd /opt/biofoxagent
```

3. Clone the repository (if applicable) or create necessary directories:

```bash
git clone https://github.com/yourusername/biofoxgpt.git .
# OR if copying files directly
mkdir -p data-node meili_data_v1.12 pgdata2 images uploads logs
```

4. Copy the `.env` file to the server:

```bash
# Run this from your local machine
scp /Users/yoo/biofoxgpt/biofoxgpt/.env root@152.42.225.142:/opt/biofoxagent/
```

5. Copy the deployment script:

```bash
# Run this from your local machine
scp /Users/yoo/biofoxgpt/biofoxgpt/deploy-digitalocean.sh root@152.42.225.142:/opt/biofoxagent/
```

6. Make the script executable on the server:

```bash
# Run on server
chmod +x /opt/biofoxagent/deploy-digitalocean.sh
```

7. Run the deployment script:

```bash
# Run on server
cd /opt/biofoxagent
./deploy-digitalocean.sh
```

## Post-Deployment

After successful deployment, BIOFOX Agent will be accessible at:
- http://152.42.225.142:3081

## Monitoring and Maintenance

Check the status of the containers:

```bash
docker ps
```

View logs for specific containers:

```bash
docker logs BIOFOX-Agent
docker logs biofox-mongodb
docker logs biofox-meilisearch
docker logs vectordb
docker logs biofox-rag-api
```

Restart a specific container:

```bash
docker restart BIOFOX-Agent
```

Stop all containers:

```bash
docker stop BIOFOX-Agent biofox-mongodb biofox-meilisearch vectordb biofox-rag-api
```

Start all containers:

```bash
docker start biofox-mongodb biofox-meilisearch vectordb biofox-rag-api BIOFOX-Agent
```

## Manual Deployment (Alternative to Script)

If the deployment script doesn't work, you can run the Docker commands manually:

```bash
# Create Docker network
docker network create biofox-network

# Start MongoDB
docker run -d \
  --name biofox-mongodb \
  --network biofox-network \
  --restart always \
  -v "$(pwd)/data-node:/data/db" \
  mongo \
  mongod --noauth

# Start Meilisearch
docker run -d \
  --name biofox-meilisearch \
  --network biofox-network \
  --restart always \
  -e "MEILI_HOST=http://biofox-meilisearch:7700" \
  -e "MEILI_NO_ANALYTICS=true" \
  -e "MEILI_MASTER_KEY=${MEILI_MASTER_KEY}" \
  -v "$(pwd)/meili_data_v1.12:/meili_data" \
  getmeili/meilisearch:v1.12.3

# Start PostgreSQL with pgvector
docker run -d \
  --name vectordb \
  --network biofox-network \
  --restart always \
  -e "POSTGRES_DB=mydatabase" \
  -e "POSTGRES_USER=myuser" \
  -e "POSTGRES_PASSWORD=mypassword" \
  -v "$(pwd)/pgdata2:/var/lib/postgresql/data" \
  ankane/pgvector:latest

# Start RAG API
docker run -d \
  --name biofox-rag-api \
  --network biofox-network \
  --restart always \
  -e "DB_HOST=vectordb" \
  -e "RAG_PORT=8000" \
  --link vectordb:vectordb \
  --env-file .env \
  ghcr.io/danny-avila/librechat-rag-api-dev-lite:latest

# Start BIOFOX Agent
docker run -d \
  --name BIOFOX-Agent \
  --network biofox-network \
  -p 3081:3081 \
  --restart always \
  -e "HOST=0.0.0.0" \
  -e "MONGO_URI=mongodb://biofox-mongodb:27017/BIOFOX" \
  -e "PORT=3081" \
  -e "MEILI_HOST=http://biofox-meilisearch:7700" \
  -e "RAG_PORT=8000" \
  -e "RAG_API_URL=http://biofox-rag-api:8000" \
  -v "$(pwd)/.env:/app/.env" \
  -v "$(pwd)/images:/app/client/public/images" \
  -v "$(pwd)/uploads:/app/uploads" \
  -v "$(pwd)/logs:/app/api/logs" \
  ghcr.io/danny-avila/librechat-dev:latest

# Give PostgreSQL time to initialize
sleep 10
docker restart biofox-rag-api
```

## Troubleshooting

If you encounter issues:

1. Check if Docker is running:
```bash
systemctl status docker
```

2. Ensure all required ports are open:
```bash
ufw status
```

3. Check server resources:
```bash
df -h  # Check disk space
free -m  # Check memory
htop  # Check CPU and memory usage (may need to install with apt-get install htop)
```

4. Review logs for errors:
```bash
docker logs BIOFOX-Agent
```

5. Ensure container network is properly configured:
```bash
docker network inspect biofox-network
```

## Updating the Application

To update the application:

1. Stop the container:
```bash
docker stop BIOFOX-Agent
```

2. Pull the latest image:
```bash
docker pull ghcr.io/danny-avila/librechat-dev:latest
```

3. Start the container:
```bash
docker start BIOFOX-Agent
```