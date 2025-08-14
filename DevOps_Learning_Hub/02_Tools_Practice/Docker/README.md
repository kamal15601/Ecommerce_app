# 🐳 Docker Practice Labs (2025 Edition)

Comprehensive hands-on labs for mastering Docker containerization, updated with the latest features, best practices, and industry standards for 2025.

## 📚 Table of Contents

1. [Lab 1: Docker Fundamentals](#lab-1-docker-fundamentals)
2. [Lab 2: Dockerfile Best Practices](#lab-2-dockerfile-best-practices)
3. [Lab 3: Multi-Stage Builds](#lab-3-multi-stage-builds)
4. [Lab 4: Docker Networking](#lab-4-docker-networking)
5. [Lab 5: Docker Volumes](#lab-5-docker-volumes)
6. [Lab 6: Docker Compose](#lab-6-docker-compose)
7. [Lab 7: Docker Security](#lab-7-docker-security)
8. [Lab 8: Docker Registry](#lab-8-docker-registry)
9. [Lab 9: Container Monitoring](#lab-9-container-monitoring)
10. [Lab 10: Production Optimization](#lab-10-production-optimization)

## 🎯 Prerequisites

- Docker Desktop installed (latest version)
- Basic command line knowledge
- Text editor (VS Code recommended)
- Docker Hub account (for registry exercises)

## 🚀 Lab 1: Docker Fundamentals

### Objective
Learn basic Docker commands and container lifecycle management.

### Steps

#### 1.1 Basic Commands
```bash
# Check Docker version
docker --version
docker version
docker info

# Download and run your first container
docker run hello-world

# Run interactive container
docker run -it ubuntu:20.04 /bin/bash

# Inside the container, explore:
ls -la
cat /etc/os-release
ps aux
exit
```

#### 1.2 Container Lifecycle
```bash
# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# Run container in background (detached mode)
docker run -d --name my-nginx nginx:alpine

# View container logs
docker logs my-nginx
docker logs -f my-nginx  # Follow logs

# Execute commands in running container
docker exec -it my-nginx sh
# Inside container:
ls /usr/share/nginx/html/
cat /usr/share/nginx/html/index.html
exit

# Stop and start containers
docker stop my-nginx
docker start my-nginx
docker restart my-nginx

# Remove containers
docker rm my-nginx
docker rm -f my-nginx  # Force remove running container
```

#### 1.3 Image Management
```bash
# List local images
docker images

# Search for images on Docker Hub
docker search node

# Pull specific image versions
docker pull node:16-alpine
docker pull node:18-alpine
docker pull postgres:14

# Inspect image details
docker inspect node:16-alpine

# Remove images
docker rmi node:18-alpine
docker rmi $(docker images -q)  # Remove all images
```

### 🎯 Exercise
Create a simple web server container:
```bash
# Run Python web server
docker run -d -p 8080:8000 --name python-server python:3.9-slim python -m http.server

# Test the server
curl http://localhost:8080

# Check what's running inside
docker exec -it python-server ps aux
```

---

## 🔨 Lab 2: Dockerfile Best Practices

### Objective
Create optimized Dockerfiles following best practices.

### 2.1 Basic Dockerfile
```dockerfile
# Dockerfile.basic
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Copy requirements first (layer caching)
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Expose port
EXPOSE 5000

# Set environment variables
ENV FLASK_APP=app.py
ENV FLASK_ENV=production

# Create non-root user
RUN adduser --disabled-password --gecos '' appuser
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:5000/health || exit 1

# Start application
CMD ["python", "app.py"]
```

### 2.2 Build and Test
```bash
# Create sample Flask app
cat > app.py << 'EOF'
from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route('/')
def hello():
    return jsonify({
        'message': 'Hello from Docker!',
        'environment': os.environ.get('FLASK_ENV', 'development'),
        'version': '1.0.0'
    })

@app.route('/health')
def health():
    return jsonify({'status': 'healthy'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

# Create requirements.txt
cat > requirements.txt << 'EOF'
Flask==2.3.3
gunicorn==21.2.0
EOF

# Build image
docker build -f Dockerfile.basic -t my-flask-app:v1 .

# Run container
docker run -d -p 5000:5000 --name flask-app my-flask-app:v1

# Test the application
curl http://localhost:5000
curl http://localhost:5000/health

# Check container logs
docker logs flask-app
```

### 2.3 Advanced Dockerfile
```dockerfile
# Dockerfile.advanced
FROM python:3.9-slim AS base

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

FROM base AS dependencies

# Set working directory
WORKDIR /app

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM base AS runtime

# Copy installed packages from dependencies stage
COPY --from=dependencies /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages
COPY --from=dependencies /usr/local/bin /usr/local/bin

# Create non-root user
RUN groupadd -r appgroup && useradd -r -g appgroup appuser

# Set working directory and ownership
WORKDIR /app
RUN chown -R appuser:appgroup /app

# Copy application code
COPY --chown=appuser:appgroup . .

# Switch to non-root user
USER appuser

# Set environment variables
ENV PYTHONPATH=/app
ENV FLASK_APP=app.py
ENV FLASK_ENV=production

# Expose port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:5000/health || exit 1

# Use gunicorn for production
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "4", "app:app"]
```

---

## 🏗️ Lab 3: Multi-Stage Builds

### Objective
Learn to create efficient images using multi-stage builds.

### 3.1 Node.js Multi-Stage Build
```dockerfile
# Dockerfile.multistage
# Build stage
FROM node:16-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install all dependencies (including dev dependencies)
RUN npm ci

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Production stage
FROM node:16-alpine AS production

# Install dumb-init for proper process handling
RUN apk add --no-cache dumb-init

# Create app directory
WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

# Copy package files
COPY package*.json ./

# Install only production dependencies
RUN npm ci --only=production && npm cache clean --force

# Copy built application from builder stage
COPY --from=builder --chown=nextjs:nodejs /app/dist ./dist
COPY --from=builder --chown=nextjs:nodejs /app/public ./public

# Switch to non-root user
USER nextjs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "dist/server.js"]
```

### 3.2 Create Sample Node.js App
```bash
# Initialize Node.js project
mkdir nodejs-app && cd nodejs-app

# Create package.json
cat > package.json << 'EOF'
{
  "name": "nodejs-docker-app",
  "version": "1.0.0",
  "description": "Sample Node.js app for Docker",
  "main": "server.js",
  "scripts": {
    "start": "node dist/server.js",
    "build": "mkdir -p dist && cp server.js dist/",
    "dev": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  }
}
EOF

# Create server.js
cat > server.js << 'EOF'
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.json({
    message: 'Hello from Node.js Docker!',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development'
  });
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy' });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});
EOF

# Build and test
docker build -f Dockerfile.multistage -t nodejs-app:multistage .
docker run -d -p 3000:3000 --name nodejs-multistage nodejs-app:multistage

# Test the application
curl http://localhost:3000
curl http://localhost:3000/health
```

---

## 🌐 Lab 4: Docker Networking

### Objective
Master Docker networking concepts and configurations.

### 4.1 Network Types
```bash
# List default networks
docker network ls

# Inspect bridge network
docker network inspect bridge

# Create custom networks
docker network create --driver bridge my-bridge-network
docker network create --driver bridge --subnet=192.168.100.0/24 my-custom-network

# Create host network (Linux only)
# docker network create --driver host my-host-network
```

### 4.2 Container Communication
```bash
# Run containers in default network
docker run -d --name web-server nginx:alpine
docker run -d --name app-server python:3.9-slim python -m http.server 8000

# Run containers in custom network
docker run -d --name web1 --network my-bridge-network nginx:alpine
docker run -d --name web2 --network my-bridge-network nginx:alpine

# Test connectivity
docker exec web1 ping web2
docker exec web1 nslookup web2

# Connect existing container to network
docker network connect my-bridge-network app-server

# Disconnect from network
docker network disconnect my-bridge-network app-server
```

### 4.3 Advanced Networking
```bash
# Port mapping variations
docker run -d -p 8080:80 --name nginx1 nginx:alpine
docker run -d -p 127.0.0.1:8081:80 --name nginx2 nginx:alpine
docker run -d -p 8082:80/tcp -p 8083:80/udp --name nginx3 nginx:alpine

# Expose vs Publish
docker run -d --expose 8000 --name exposed-only python:3.9-slim python -m http.server
docker run -d -p 9000:8000 --name published python:3.9-slim python -m http.server

# Network aliases
docker run -d --name db --network my-bridge-network --network-alias database postgres:13
docker run -d --name app --network my-bridge-network alpine sh -c "while true; do ping database; sleep 10; done"
```

### 4.4 Docker Compose Networking
```yaml
# docker-compose.networking.yml
version: '3.8'

services:
  frontend:
    image: nginx:alpine
    ports:
      - "80:80"
    networks:
      - frontend-network
      - backend-network

  api:
    image: node:16-alpine
    command: node server.js
    networks:
      - backend-network
      - database-network

  database:
    image: postgres:13
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
    networks:
      - database-network

networks:
  frontend-network:
    driver: bridge
  backend-network:
    driver: bridge
  database-network:
    driver: bridge
    internal: true  # No external access
```

---

## 💾 Lab 5: Docker Volumes

### Objective
Learn persistent data management with Docker volumes.

### 5.1 Volume Types
```bash
# Named volumes
docker volume create my-data-volume
docker volume ls
docker volume inspect my-data-volume

# Run container with named volume
docker run -d -v my-data-volume:/data --name data-container alpine sh -c "echo 'Hello Volume' > /data/message.txt && sleep 3600"

# Verify data persistence
docker exec data-container cat /data/message.txt
docker stop data-container
docker rm data-container

# Create new container with same volume
docker run --rm -v my-data-volume:/data alpine cat /data/message.txt

# Bind mounts (development)
mkdir -p ./host-data
echo "Hello from host" > ./host-data/host-message.txt

docker run --rm -v $(pwd)/host-data:/app/data alpine cat /app/data/host-message.txt

# tmpfs mounts (in-memory)
docker run --rm --tmpfs /app/temp alpine sh -c "echo 'temporary data' > /app/temp/temp.txt && cat /app/temp/temp.txt"
```

### 5.2 Database Persistence
```bash
# PostgreSQL with persistent data
docker volume create postgres-data

docker run -d \
  --name postgres-db \
  -e POSTGRES_DB=ecommerce \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=secret123 \
  -v postgres-data:/var/lib/postgresql/data \
  -p 5432:5432 \
  postgres:13

# Connect and create data
docker exec -it postgres-db psql -U admin -d ecommerce -c "
CREATE TABLE products (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100),
  price DECIMAL(10,2)
);
INSERT INTO products (name, price) VALUES ('Laptop', 999.99), ('Phone', 599.99);
"

# Verify data
docker exec -it postgres-db psql -U admin -d ecommerce -c "SELECT * FROM products;"

# Test persistence
docker stop postgres-db
docker rm postgres-db

# Start new container with same volume
docker run -d \
  --name postgres-db-new \
  -e POSTGRES_DB=ecommerce \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=secret123 \
  -v postgres-data:/var/lib/postgresql/data \
  -p 5433:5432 \
  postgres:13

# Verify data persistence
docker exec -it postgres-db-new psql -U admin -d ecommerce -c "SELECT * FROM products;"
```

### 5.3 Volume Management
```bash
# Backup volumes
docker run --rm -v postgres-data:/source -v $(pwd):/backup alpine tar czf /backup/postgres-backup.tar.gz -C /source .

# Restore volumes
docker volume create postgres-data-restored
docker run --rm -v postgres-data-restored:/target -v $(pwd):/backup alpine tar xzf /backup/postgres-backup.tar.gz -C /target

# Volume cleanup
docker volume prune  # Remove unused volumes
docker volume rm my-data-volume
```

---

## 🐙 Lab 6: Docker Compose

### Objective
Orchestrate multi-container applications with Docker Compose.

### 6.1 Basic Compose File
```yaml
# docker-compose.basic.yml
version: '3.8'

services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./html:/usr/share/nginx/html:ro
    depends_on:
      - api

  api:
    build:
      context: .
      dockerfile: Dockerfile.api
    ports:
      - "5000:5000"
    environment:
      - DATABASE_URL=postgresql://user:password@db:5432/appdb
      - REDIS_URL=redis://redis:6379
    depends_on:
      - db
      - redis

  db:
    image: postgres:13
    environment:
      POSTGRES_DB: appdb
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

volumes:
  postgres_data:

networks:
  default:
    driver: bridge
```

### 6.2 Environment-Specific Overrides
```yaml
# docker-compose.override.yml (development)
version: '3.8'

services:
  api:
    environment:
      - DEBUG=true
      - LOG_LEVEL=debug
    volumes:
      - .:/app
    command: python app.py --reload

  web:
    volumes:
      - ./nginx/dev.conf:/etc/nginx/nginx.conf
```

```yaml
# docker-compose.prod.yml (production)
version: '3.8'

services:
  web:
    deploy:
      replicas: 3
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M

  api:
    deploy:
      replicas: 2
      resources:
        limits:
          memory: 1G
        reservations:
          memory: 512M
    environment:
      - DEBUG=false
      - LOG_LEVEL=info

  db:
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 1G
```

### 6.3 Compose Commands
```bash
# Basic operations
docker-compose up -d
docker-compose ps
docker-compose logs
docker-compose logs -f api

# Build and recreate
docker-compose build
docker-compose up --build
docker-compose up --force-recreate

# Scale services
docker-compose up --scale api=3 --scale web=2

# Environment-specific deployments
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Stop and cleanup
docker-compose stop
docker-compose down
docker-compose down -v  # Remove volumes too
```

---

## 🔒 Lab 7: Docker Security

### Objective
Implement security best practices in Docker containers.

### 7.1 Secure Dockerfile
```dockerfile
# Dockerfile.secure
FROM python:3.9-slim AS base

# Install security updates
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -r appgroup && \
    useradd -r -g appgroup -d /app -s /sbin/nologin -c "App User" appuser

FROM base AS dependencies

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM base AS runtime

# Copy dependencies from previous stage
COPY --from=dependencies /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages

# Set up application directory
WORKDIR /app
RUN chown -R appuser:appgroup /app

# Copy application code
COPY --chown=appuser:appgroup . .

# Switch to non-root user
USER appuser

# Remove unnecessary packages and files
RUN pip uninstall -y pip setuptools

# Set security-focused environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Expose port (non-privileged)
EXPOSE 8080

# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Run with restricted capabilities
CMD ["python", "app.py"]
```

### 7.2 Security Scanning
```bash
# Scan image for vulnerabilities
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  -v $(pwd):/app \
  anchore/grype:latest \
  your-image:tag

# Use Docker Scout (if available)
docker scout quickview your-image:tag
docker scout cves your-image:tag

# Dockerfile linting
docker run --rm -i hadolint/hadolint < Dockerfile.secure
```

### 7.3 Runtime Security
```bash
# Run container with security options
docker run -d \
  --name secure-app \
  --read-only \
  --tmpfs /tmp \
  --tmpfs /run \
  --cap-drop ALL \
  --cap-add NET_BIND_SERVICE \
  --security-opt no-new-privileges \
  --user 1000:1000 \
  -p 8080:8080 \
  your-secure-app:latest

# AppArmor profile (Linux)
docker run --security-opt apparmor:docker-default your-app

# SELinux labels (Linux)
docker run --security-opt label=level:s0:c100,c200 your-app
```

### 7.4 Secrets Management
```bash
# Docker secrets (Swarm mode)
echo "mysecretpassword" | docker secret create db_password -

# Use external secret management
docker run -d \
  --name app-with-secrets \
  -e VAULT_ADDR=https://vault.example.com \
  -e VAULT_TOKEN_FILE=/run/secrets/vault_token \
  -v vault_token:/run/secrets/vault_token:ro \
  your-app:latest
```

---

## 📦 Lab 8: Docker Registry

### Objective
Work with Docker registries for image distribution.

### 8.1 Docker Hub Operations
```bash
# Login to Docker Hub
docker login

# Tag images for Docker Hub
docker tag my-app:latest yourusername/my-app:latest
docker tag my-app:latest yourusername/my-app:v1.0.0

# Push to Docker Hub
docker push yourusername/my-app:latest
docker push yourusername/my-app:v1.0.0

# Pull from Docker Hub
docker pull yourusername/my-app:v1.0.0
```

### 8.2 Private Registry Setup
```yaml
# docker-compose.registry.yml
version: '3.8'

services:
  registry:
    image: registry:2
    ports:
      - "5000:5000"
    environment:
      REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY: /data
      REGISTRY_AUTH: htpasswd
      REGISTRY_AUTH_HTPASSWD_REALM: Registry Realm
      REGISTRY_AUTH_HTPASSWD_PATH: /auth/htpasswd
    volumes:
      - registry_data:/data
      - ./auth:/auth

  registry-ui:
    image: joxit/docker-registry-ui:static
    ports:
      - "8080:80"
    environment:
      REGISTRY_TITLE: My Private Registry
      REGISTRY_URL: http://registry:5000
    depends_on:
      - registry

volumes:
  registry_data:
```

### 8.3 Registry Operations
```bash
# Create auth file for private registry
mkdir auth
docker run --entrypoint htpasswd httpd:2.4 -Bbn admin password > auth/htpasswd

# Start private registry
docker-compose -f docker-compose.registry.yml up -d

# Tag and push to private registry
docker tag my-app:latest localhost:5000/my-app:latest
docker push localhost:5000/my-app:latest

# List images in registry
curl -X GET http://localhost:5000/v2/_catalog

# Get image tags
curl -X GET http://localhost:5000/v2/my-app/tags/list
```

### 8.4 Amazon ECR
```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com

# Create ECR repository
aws ecr create-repository --repository-name my-app --region us-east-1

# Tag and push to ECR
docker tag my-app:latest 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app:latest
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app:latest
```

---

## 📊 Lab 9: Container Monitoring

### Objective
Monitor container performance and health.

### 9.1 Basic Monitoring
```bash
# Container resource usage
docker stats
docker stats --no-stream
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# Container processes
docker top container_name

# Container events
docker events
docker events --filter container=my-app
```

### 9.2 Health Checks
```dockerfile
# Dockerfile with health check
FROM nginx:alpine

# Custom health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/ || exit 1

# Or using a custom script
COPY healthcheck.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/healthcheck.sh
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD /usr/local/bin/healthcheck.sh
```

```bash
# healthcheck.sh
#!/bin/sh
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:80/)
if [ $response -eq 200 ]; then
    exit 0
else
    exit 1
fi
```

### 9.3 cAdvisor Monitoring
```yaml
# docker-compose.monitoring.yml
version: '3.8'

services:
  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    ports:
      - "8080:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
    privileged: true
    devices:
      - /dev/kmsg

  app:
    image: nginx:alpine
    ports:
      - "80:80"
```

---

## ⚡ Lab 10: Production Optimization

### Objective
Optimize containers for production deployment.

### 10.1 Image Optimization
```dockerfile
# Dockerfile.optimized
# Use specific version tags, not 'latest'
FROM python:3.9.16-slim AS base

# Use multi-stage builds
FROM base AS dependencies
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM base AS runtime

# Copy only what's needed
COPY --from=dependencies /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages

# Minimize layers
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -r appgroup \
    && useradd -r -g appgroup appuser

WORKDIR /app
COPY --chown=appuser:appgroup app.py .

USER appuser

# Use ENTRYPOINT for immutable commands
ENTRYPOINT ["python"]
CMD ["app.py"]
```

### 10.2 Resource Limits
```yaml
# docker-compose.production.yml
version: '3.8'

services:
  web:
    image: my-web-app:latest
    deploy:
      resources:
        limits:
          cpus: '0.50'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
        window: 120s

  api:
    image: my-api:latest
    deploy:
      replicas: 3
      update_config:
        parallelism: 1
        delay: 10s
        failure_action: rollback
      rollback_config:
        parallelism: 1
        delay: 5s
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
```

### 10.3 Performance Testing
```bash
# Install hey for load testing
go install github.com/rakyll/hey@latest

# Run performance test
hey -n 10000 -c 100 http://localhost:8080/

# Monitor during test
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
```

### 10.4 Production Checklist
```bash
# Security checklist
□ Use non-root user
□ Remove unnecessary packages
□ Scan for vulnerabilities
□ Use read-only filesystem where possible
□ Set resource limits
□ Use health checks
□ Implement proper logging
□ Use secrets management
□ Keep base images updated
□ Use specific image tags

# Performance checklist
□ Optimize image size
□ Use multi-stage builds
□ Cache dependencies
□ Minimize layers
□ Use appropriate base images
□ Implement proper monitoring
□ Set up alerting
□ Test resource limits
□ Profile application performance
□ Implement graceful shutdown
```

---

## 🎯 Practice Exercises

### Exercise 1: Full-Stack Application
Create a complete dockerized application with:
- Frontend (React/Vue)
- Backend API (Node.js/Python)
- Database (PostgreSQL)
- Cache (Redis)
- Reverse proxy (NGINX)

### Exercise 2: CI/CD Integration
Integrate your Docker workflow with:
- Automated testing in containers
- Multi-stage builds for different environments
- Image scanning and security checks
- Automated deployment

### Exercise 3: Monitoring Stack
Set up comprehensive monitoring:
- Container metrics with cAdvisor
- Application metrics with Prometheus
- Log aggregation with ELK stack
- Alerting with AlertManager

---

## 📚 Additional Resources

### Documentation
- [Docker Official Documentation](https://docs.docker.com/)
- [Docker Best Practices](https://docs.docker.com/develop/best-practices/)
- [Dockerfile Reference](https://docs.docker.com/engine/reference/builder/)

### Tools
- [Docker Desktop](https://www.docker.com/products/docker-desktop)
- [Portainer](https://www.portainer.io/) - Container management UI
- [Hadolint](https://github.com/hadolint/hadolint) - Dockerfile linter
- [Dive](https://github.com/wagoodman/dive) - Image layer analyzer

### Security
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [Snyk Container Security](https://snyk.io/product/container-vulnerability-management/)

---

**Next**: Move to `../Kubernetes/` for container orchestration labs.
