# 🐳 Docker Interview Questions

Comprehensive collection of Docker interview questions with detailed answers, covering beginner to advanced levels. Updated for 2025 with the latest Docker features, best practices, security considerations, and ecosystem integration patterns.

## 📚 Table of Contents

1. [Fundamentals (Questions 1-25)](#fundamentals)
2. [Dockerfile & Images (Questions 26-50)](#dockerfile--images)
3. [Networking (Questions 51-75)](#networking)
4. [Volumes & Storage (Questions 76-100)](#volumes--storage)
5. [Security (Questions 101-125)](#security)
6. [Performance & Optimization (Questions 126-150)](#performance--optimization)
7. [Orchestration & Integration (Questions 151-175)](#orchestration--integration)
8. [Troubleshooting & Advanced Scenarios (Questions 176-200)](#troubleshooting--advanced-scenarios)

---

## 🏁 Fundamentals

### Q1: What is Docker and how does it differ from virtual machines?
**Answer:**
Docker is a containerization platform that packages applications and their dependencies into lightweight, portable containers. Key differences from VMs:

| Aspect | Docker Containers | Virtual Machines |
|--------|------------------|------------------|
| **Architecture** | Shares host OS kernel | Full OS per VM |
| **Resource Usage** | Lightweight (MBs) | Heavy (GBs) |
| **Startup Time** | Seconds | Minutes |
| **Isolation** | Process-level | Hardware-level |
| **Portability** | High | Medium |
| **Performance** | Near-native | Virtualization overhead |
| **Density** | High (100s of containers) | Low (dozen VMs) |
| **Security Isolation** | Less complete | More comprehensive |

**2025 Docker Architecture:**
```
┌─────────────────────────────────────┐
│        Containerized Apps           │
├─────────────────────────────────────┤
│   Container Runtime Interface (CRI) │
├─────────────────────────────────────┤
│      containerd / CRI-O / etc.     │
├─────────────────────────────────────┤
│          Host OS Kernel            │
├─────────────────────────────────────┤
│       Physical/Virtual Server       │
└─────────────────────────────────────┘
```

### Q2: Explain Docker architecture and its main components.
**Answer:**
Docker follows a client-server architecture with three main components:

1. **Docker Client**: Command-line interface that communicates with Docker daemon
2. **Docker Daemon (dockerd)**: Background service managing containers, images, networks
3. **Docker Registry**: Repository for Docker images (Docker Hub, private registries)

**Components:**
- **Images**: Read-only templates for creating containers
- **Containers**: Running instances of images
- **Dockerfile**: Text file with instructions to build images
- **Networks**: Enable container communication
- **Volumes**: Persistent storage for containers

### Q3: What is a Docker container lifecycle?
**Answer:**
Container lifecycle stages:

```bash
# 1. Created
docker create --name myapp nginx:alpine

# 2. Running
docker start myapp
# or directly: docker run -d --name myapp nginx:alpine

# 3. Paused (optional)
docker pause myapp
docker unpause myapp

# 4. Stopped
docker stop myapp

# 5. Removed
docker rm myapp
```

**Lifecycle Commands:**
- `docker create` - Creates container without starting
- `docker start` - Starts stopped container
- `docker run` - Creates and starts container
- `docker pause/unpause` - Suspends/resumes processes
- `docker stop` - Gracefully stops container (SIGTERM then SIGKILL)
- `docker kill` - Forcefully stops container (SIGKILL)
- `docker rm` - Removes stopped container

### Q4: What are Docker images and how are they created?
**Answer:**
Docker images are read-only templates containing application code, runtime, libraries, and dependencies. They're built in layers using Union File System.

**Creation methods:**
```bash
# 1. From Dockerfile
docker build -t myapp:v1.0 .

# 2. From existing container
docker commit container_name new_image:tag

# 3. From base image
docker run -it ubuntu:20.04 bash
# Make changes...
docker commit container_id custom_ubuntu:v1
```

**Image layers:**
```dockerfile
FROM ubuntu:20.04           # Layer 1
RUN apt-get update          # Layer 2
RUN apt-get install nginx   # Layer 3
COPY app.py /app/           # Layer 4
CMD ["python", "/app/app.py"] # Layer 5
```

### Q5: Explain Docker networking modes.
**Answer:**
Docker provides several network drivers:

1. **Bridge (default)**: Isolated network for containers on same host
```bash
docker run -d --name web --network bridge nginx
```

2. **Host**: Container shares host's network stack
```bash
docker run -d --name web --network host nginx
```

3. **None**: No networking
```bash
docker run -d --name web --network none nginx
```

4. **Overlay**: Multi-host networking for Docker Swarm
```bash
docker network create -d overlay my-overlay-network
```

5. **Macvlan**: Assign MAC address to container
```bash
docker network create -d macvlan \
  --subnet=192.168.1.0/24 \
  --gateway=192.168.1.1 \
  -o parent=eth0 my-macvlan
```

### Q6: What is the difference between CMD and ENTRYPOINT?
**Answer:**

| Aspect | CMD | ENTRYPOINT |
|--------|-----|------------|
| **Purpose** | Default command/args | Main command |
| **Override** | Completely replaced | Arguments appended |
| **Usage** | Can be overridden | Fixed command |

**Examples:**
```dockerfile
# CMD example
FROM ubuntu
CMD ["echo", "Hello World"]

# Run: docker run myimage
# Output: Hello World
# Run: docker run myimage echo "Different"
# Output: Different

# ENTRYPOINT example
FROM ubuntu
ENTRYPOINT ["echo"]
CMD ["Hello World"]

# Run: docker run myimage
# Output: Hello World
# Run: docker run myimage "Different"
# Output: Different
```

**Best Practice - Combined:**
```dockerfile
FROM ubuntu
ENTRYPOINT ["python", "app.py"]
CMD ["--help"]

# docker run myapp           -> python app.py --help
# docker run myapp --version -> python app.py --version
```

### Q7: How do you handle secrets in Docker?
**Answer:**
Multiple approaches for secret management:

1. **Docker Secrets (Swarm mode):**
```bash
echo "mysecret" | docker secret create db_password -
docker service create --secret db_password nginx
```

2. **Environment Variables (not recommended for production):**
```dockerfile
ENV API_KEY=secret_key  # Bad practice
```

3. **External Secret Management:**
```dockerfile
FROM alpine
RUN apk add --no-cache curl
COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
```

```bash
#!/bin/bash
# entrypoint.sh
export DB_PASSWORD=$(vault kv get -field=password secret/db)
exec "$@"
```

4. **Init Containers:**
```yaml
# Kubernetes example
initContainers:
- name: secret-fetcher
  image: vault:latest
  command: ['sh', '-c', 'vault read -field=password secret/db > /shared/password']
  volumeMounts:
  - name: shared-data
    mountPath: /shared
```

### Q8: Explain Docker volumes and their types.
**Answer:**
Docker volumes provide persistent storage that survives container lifecycle.

**Types:**

1. **Named Volumes** (managed by Docker):
```bash
docker volume create mydata
docker run -v mydata:/data nginx
```

2. **Bind Mounts** (host directory):
```bash
docker run -v /host/path:/container/path nginx
```

3. **tmpfs Mounts** (memory):
```bash
docker run --tmpfs /tmp nginx
```

**Comparison:**
| Type | Location | Managed by | Performance | Use Case |
|------|----------|------------|-------------|----------|
| **Named Volume** | Docker area | Docker | Good | Production data |
| **Bind Mount** | Host filesystem | User | Best | Development |
| **tmpfs Mount** | Host memory | Docker | Fastest | Temporary data |

### Q9: What is multi-stage build and why use it?
**Answer:**
Multi-stage builds allow using multiple FROM statements in a Dockerfile to create optimized images.

**Benefits:**
- Smaller final image size
- Separate build and runtime environments
- Enhanced security (no build tools in production)

**Example:**
```dockerfile
# Build stage
FROM node:16-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine AS production
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

**Size comparison:**
- Single stage: ~500MB (includes Node.js, npm, source code)
- Multi-stage: ~50MB (only nginx and built assets)

### Q10: How do you optimize Docker images?
**Answer:**
Image optimization strategies:

1. **Use minimal base images:**
```dockerfile
FROM alpine:3.18        # ~5MB
# vs
FROM ubuntu:20.04       # ~72MB
```

2. **Multi-stage builds:**
```dockerfile
FROM golang:1.19 AS builder
COPY . .
RUN go build -o app

FROM alpine:3.18
COPY --from=builder /app .
```

3. **Minimize layers:**
```dockerfile
# Bad
RUN apt-get update
RUN apt-get install -y package1
RUN apt-get install -y package2

# Good
RUN apt-get update && \
    apt-get install -y package1 package2 && \
    rm -rf /var/lib/apt/lists/*
```

4. **Use .dockerignore:**
```dockerignore
node_modules
.git
*.md
.env
```

5. **Order layers by change frequency:**
```dockerfile
FROM node:16-alpine
WORKDIR /app
COPY package*.json ./    # Changes less frequently
RUN npm ci
COPY . .                 # Changes more frequently
CMD ["npm", "start"]
```

---

## 🏗️ Dockerfile & Images

### Q26: What are Dockerfile best practices?
**Answer:**
Key Dockerfile best practices:

1. **Use specific base image tags:**
```dockerfile
FROM node:16.20.0-alpine  # Good
FROM node:latest          # Bad
```

2. **Create non-root user:**
```dockerfile
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001
USER nextjs
```

3. **Set working directory:**
```dockerfile
WORKDIR /app
```

4. **Copy package files first:**
```dockerfile
COPY package*.json ./
RUN npm ci
COPY . .
```

5. **Use HEALTHCHECK:**
```dockerfile
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:3000/health || exit 1
```

6. **Set appropriate metadata:**
```dockerfile
LABEL maintainer="team@company.com"
LABEL version="1.0.0"
LABEL description="My application"
```

### Q27: How do you debug a failing Docker build?
**Answer:**
Debugging strategies:

1. **Build with debug output:**
```bash
docker build --progress=plain --no-cache -t myapp .
```

2. **Inspect intermediate layers:**
```bash
docker build -t myapp .
# If build fails at step 5, run:
docker run -it $(docker images -q | head -n2 | tail -n1) sh
```

3. **Use multi-stage for debugging:**
```dockerfile
FROM node:16-alpine AS debug
WORKDIR /app
COPY package*.json ./
RUN npm ci
# Add debugging commands here
CMD ["sh"]

FROM debug AS production
COPY . .
RUN npm run build
```

4. **Build specific stage:**
```bash
docker build --target debug -t myapp-debug .
docker run -it myapp-debug
```

### Q28: Explain Docker image layering and caching.
**Answer:**
Docker uses layered filesystem with copy-on-write:

**Layer Structure:**
```
┌─────────────────────┐
│    Application      │ <- Layer 4 (RW)
├─────────────────────┤
│    Dependencies     │ <- Layer 3 (RO)
├─────────────────────┤
│    Base OS Updates  │ <- Layer 2 (RO)
├─────────────────────┤
│    Base Image       │ <- Layer 1 (RO)
└─────────────────────┘
```

**Cache Optimization:**
```dockerfile
# Optimized for caching
FROM python:3.9-slim

# 1. System dependencies (rarely change)
RUN apt-get update && apt-get install -y curl

# 2. Application dependencies (change less frequently)
COPY requirements.txt .
RUN pip install -r requirements.txt

# 3. Application code (changes frequently)
COPY . .

# Each RUN, COPY, ADD creates a new layer
# Docker caches layers and reuses them if unchanged
```

**Cache Invalidation:**
- Any change invalidates current layer and all subsequent layers
- Place frequently changing instructions at the end

### Q29: How do you pass build-time variables to Docker?
**Answer:**
Use ARG instruction for build-time variables:

```dockerfile
# Define build arguments
ARG NODE_VERSION=16
ARG BUILD_ENV=production
ARG BUILD_DATE
ARG GIT_COMMIT

FROM node:${NODE_VERSION}-alpine

# Set environment variables from args
ENV BUILD_ENV=${BUILD_ENV}
ENV BUILD_DATE=${BUILD_DATE}
ENV GIT_COMMIT=${GIT_COMMIT}

# Use in RUN commands
RUN if [ "$BUILD_ENV" = "development" ]; then \
      npm install; \
    else \
      npm ci --only=production; \
    fi

LABEL build.env=${BUILD_ENV}
LABEL build.date=${BUILD_DATE}
LABEL build.commit=${GIT_COMMIT}
```

**Build with arguments:**
```bash
docker build \
  --build-arg NODE_VERSION=18 \
  --build-arg BUILD_ENV=production \
  --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
  --build-arg GIT_COMMIT=$(git rev-parse HEAD) \
  -t myapp:latest .
```

**Security Note:**
```dockerfile
# ARG values are visible in image history
ARG SECRET_KEY=default  # Bad - visible in docker history

# Use runtime environment variables for secrets
ENV SECRET_KEY_FILE=/run/secrets/secret_key  # Good
```

### Q30: What is Docker image digest and why is it important?
**Answer:**
Image digest is a SHA256 hash that uniquely identifies image content.

**Format:**
```
image@sha256:abcd1234...
```

**Benefits:**
1. **Immutable reference**: Content cannot change
2. **Security**: Ensures exact image version
3. **Compliance**: Audit trail for deployments

**Usage:**
```bash
# Pull by digest
docker pull nginx@sha256:abc123...

# Get digest of local image
docker images --digests

# Use in Dockerfile
FROM node:16-alpine@sha256:def456...

# Kubernetes deployment
spec:
  containers:
  - name: app
    image: myapp@sha256:789abc...
```

**Best Practices:**
- Use digests in production deployments
- Pin base images by digest in critical applications
- Automate digest updates in CI/CD

---

## 🌐 Networking

### Q51: How do containers communicate in Docker?
**Answer:**
Container communication methods:

1. **Same Bridge Network:**
```bash
# Containers can reach each other by name
docker network create mynetwork
docker run -d --name web --network mynetwork nginx
docker run -d --name api --network mynetwork python:3.9

# Inside web container:
curl http://api:8000
```

2. **Service Discovery:**
```yaml
# docker-compose.yml
version: '3.8'
services:
  web:
    image: nginx
    depends_on:
      - api
  api:
    image: python:3.9
    # Accessible as 'api' hostname
```

3. **External Access:**
```bash
# Port mapping
docker run -p 8080:80 nginx  # Host:Container
```

4. **Container Links (deprecated):**
```bash
docker run --link api:api nginx
```

### Q52: Explain Docker port mapping and exposure.
**Answer:**

**EXPOSE vs PUBLISH:**

| Instruction | Purpose | Accessibility |
|-------------|---------|---------------|
| `EXPOSE` | Documents ports | Container-to-container only |
| `-p/--publish` | Maps host ports | External access |

**Examples:**
```dockerfile
# Dockerfile
EXPOSE 8080  # Documentation only
```

```bash
# Publish ports
docker run -p 8080:80 nginx           # Host:Container
docker run -p 127.0.0.1:8080:80 nginx # Bind to specific interface
docker run -P nginx                   # Publish all exposed ports randomly
```

**Port mapping types:**
```bash
# TCP (default)
docker run -p 8080:80/tcp nginx

# UDP
docker run -p 53:53/udp dns-server

# Both TCP and UDP
docker run -p 8080:80/tcp -p 8080:80/udp nginx

# Multiple ports
docker run -p 8080:80 -p 8443:443 nginx

# Port ranges
docker run -p 8080-8090:8080-8090 nginx
```

### Q53: What are Docker network drivers and when to use each?
**Answer:**

**Network Drivers:**

1. **Bridge** (default for standalone containers):
```bash
docker network create --driver bridge my-bridge
```
- **Use case**: Single host applications
- **Isolation**: Network-level isolation between containers

2. **Host** (remove network isolation):
```bash
docker run --network host nginx
```
- **Use case**: High performance requirements
- **Limitation**: Port conflicts, less secure

3. **None** (disable networking):
```bash
docker run --network none alpine
```
- **Use case**: Security-sensitive applications, batch jobs

4. **Overlay** (multi-host networking):
```bash
docker network create --driver overlay --attachable my-overlay
```
- **Use case**: Docker Swarm, multi-host communication

5. **Macvlan** (direct physical network access):
```bash
docker network create -d macvlan \
  --subnet=192.168.1.0/24 \
  --gateway=192.168.1.1 \
  -o parent=eth0 my-macvlan
```
- **Use case**: Legacy applications requiring specific IPs

**Selection Criteria:**
- **Single host**: Bridge
- **High performance**: Host
- **Multi-host**: Overlay
- **Legacy integration**: Macvlan
- **Security isolation**: None

### Q54: How do you troubleshoot Docker networking issues?
**Answer:**
Systematic networking troubleshooting:

1. **Check container networking:**
```bash
# Inspect container network settings
docker inspect container_name | grep -A 20 NetworkSettings

# Check if container has IP
docker exec container_name ip addr show

# Test DNS resolution
docker exec container_name nslookup google.com
docker exec container_name nslookup other_container
```

2. **Test connectivity:**
```bash
# Ping between containers
docker exec web ping api

# Test port connectivity
docker exec web telnet api 8080
docker exec web nc -zv api 8080

# Check listening ports
docker exec container_name netstat -tlnp
```

3. **Network inspection:**
```bash
# List networks
docker network ls

# Inspect network
docker network inspect bridge

# Check which containers are on network
docker network inspect mynetwork | jq '.[].Containers'
```

4. **Common issues and solutions:**
```bash
# Issue: Container cannot reach external internet
# Solution: Check DNS settings
docker run --dns 8.8.8.8 alpine nslookup google.com

# Issue: Containers cannot communicate
# Solution: Ensure they're on same network
docker network connect mynetwork container1

# Issue: Port not accessible from host
# Solution: Check port mapping
docker port container_name
```

---

## 💾 Volumes & Storage

### Q76: Explain the difference between volumes, bind mounts, and tmpfs.
**Answer:**

**Comparison:**

| Type | Storage Location | Managed By | Persistence | Performance | Use Case |
|------|-----------------|------------|-------------|-------------|----------|
| **Volume** | Docker area | Docker | Yes | Good | Production data |
| **Bind Mount** | Host filesystem | User | Yes | Best | Development |
| **tmpfs** | Host memory | Docker | No | Fastest | Temporary data |

**Examples:**
```bash
# Named volume
docker volume create mydata
docker run -v mydata:/data postgres

# Bind mount
docker run -v /host/path:/container/path nginx

# tmpfs mount
docker run --tmpfs /tmp:rw,noexec,nosuid,size=1g nginx
```

**Volume commands:**
```bash
# Create volume
docker volume create --driver local \
  --opt type=nfs \
  --opt o=addr=192.168.1.1,rw \
  --opt device=:/path/to/dir \
  foo

# List volumes
docker volume ls

# Inspect volume
docker volume inspect mydata

# Remove unused volumes
docker volume prune

# Backup volume
docker run --rm -v mydata:/source -v $(pwd):/backup alpine \
  tar czf /backup/backup.tar.gz -C /source .

# Restore volume
docker run --rm -v mydata:/target -v $(pwd):/backup alpine \
  tar xzf /backup/backup.tar.gz -C /target
```

### Q77: How do you backup and restore Docker volumes?
**Answer:**

**Volume Backup Strategies:**

1. **Using helper container:**
```bash
# Backup
docker run --rm \
  -v mydata:/source:ro \
  -v $(pwd):/backup \
  alpine tar czf /backup/mydata-backup-$(date +%Y%m%d).tar.gz -C /source .

# Restore
docker volume create mydata-restored
docker run --rm \
  -v mydata-restored:/target \
  -v $(pwd):/backup \
  alpine tar xzf /backup/mydata-backup-20250813.tar.gz -C /target
```

2. **Database-specific backup:**
```bash
# PostgreSQL backup
docker exec postgres-container pg_dump -U username dbname > backup.sql

# Restore
docker exec -i postgres-container psql -U username dbname < backup.sql

# MySQL backup
docker exec mysql-container mysqldump -u root -p database > backup.sql
```

3. **Automated backup script:**
```bash
#!/bin/bash
# backup-volumes.sh
BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d-%H%M%S)

for volume in $(docker volume ls -q); do
  echo "Backing up volume: $volume"
  docker run --rm \
    -v $volume:/source:ro \
    -v $BACKUP_DIR:/backup \
    alpine tar czf /backup/${volume}-${DATE}.tar.gz -C /source .
done

# Cleanup old backups (keep last 7 days)
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
```

4. **Using specialized tools:**
```bash
# Using duplicati for incremental backups
docker run -d --name duplicati \
  -v mydata:/source:ro \
  -v duplicati-config:/config \
  duplicati/duplicati
```

### Q78: What are volume drivers and how do you use them?
**Answer:**

**Built-in Volume Drivers:**

1. **Local driver** (default):
```bash
docker volume create --driver local myvolume
```

2. **NFS driver:**
```bash
docker volume create --driver local \
  --opt type=nfs \
  --opt o=addr=nfs.example.com,rw \
  --opt device=:/path/to/dir \
  nfs-volume
```

3. **CIFS/SMB driver:**
```bash
docker volume create --driver local \
  --opt type=cifs \
  --opt o=username=user,password=pass,uid=1000,gid=1000 \
  --opt device=//server/share \
  cifs-volume
```

**Third-party Volume Drivers:**

1. **AWS EBS:**
```bash
# Install rexray driver
docker plugin install rexray/ebs

# Create EBS volume
docker volume create --driver rexray/ebs \
  --opt size=10 \
  --opt volumetype=gp2 \
  ebs-volume
```

2. **Azure Files:**
```bash
docker plugin install store/azure/azurefile:latest

docker volume create --driver azurefile \
  --opt share=myshare \
  --opt storageaccount=mystorageaccount \
  azure-volume
```

**Custom Volume Driver:**
```golang
// Example volume driver structure
type VolumeDriver struct {
    volumes map[string]*Volume
}

func (d *VolumeDriver) Create(req *volume.CreateRequest) error {
    // Implementation for creating volume
}

func (d *VolumeDriver) Mount(req *volume.MountRequest) (*volume.MountResponse, error) {
    // Implementation for mounting volume
}
```

---

## 🔒 Security

### Q101: What are Docker security best practices?
**Answer:**

**Container Security Best Practices:**

1. **Use minimal base images:**
```dockerfile
FROM alpine:3.18  # 5MB
# vs
FROM ubuntu:20.04 # 72MB
```

2. **Run as non-root user:**
```dockerfile
RUN addgroup -g 1001 -S appgroup && \
    adduser -S app -u 1001 -G appgroup
USER app
```

3. **Use multi-stage builds:**
```dockerfile
FROM golang:1.19 AS builder
COPY . .
RUN go build -o app

FROM alpine:3.18
RUN adduser -D app
USER app
COPY --from=builder /app .
```

4. **Scan for vulnerabilities:**
```bash
# Using Trivy
trivy image nginx:latest

# Using Snyk
snyk container test nginx:latest
```

5. **Set resource limits:**
```bash
docker run --memory="512m" --cpus="0.5" nginx
```

6. **Use read-only filesystem:**
```bash
docker run --read-only --tmpfs /tmp nginx
```

7. **Drop capabilities:**
```bash
docker run --cap-drop ALL --cap-add NET_BIND_SERVICE nginx
```

### Q102: How do you implement secrets management in Docker?
**Answer:**

**Secrets Management Approaches:**

1. **Docker Secrets (Swarm):**
```bash
# Create secret
echo "mysecret" | docker secret create db_password -

# Use in service
docker service create \
  --name myapp \
  --secret db_password \
  myimage
```

2. **External Secret Management:**
```dockerfile
FROM alpine
RUN apk add --no-cache curl jq
COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]

# entrypoint.sh
#!/bin/sh
export DB_PASSWORD=$(vault kv get -field=password secret/db)
exec "$@"
```

3. **Init containers for secrets:**
```yaml
# Kubernetes example
apiVersion: v1
kind: Pod
spec:
  initContainers:
  - name: secret-fetcher
    image: vault:latest
    command:
    - sh
    - -c
    - |
      vault auth -method=aws
      vault read -field=password secret/db > /shared/db_password
    volumeMounts:
    - name: shared-data
      mountPath: /shared
  containers:
  - name: app
    image: myapp
    env:
    - name: DB_PASSWORD_FILE
      value: /shared/db_password
    volumeMounts:
    - name: shared-data
      mountPath: /shared
```

4. **Runtime secret injection:**
```bash
# Using environment variable substitution
docker run -e DB_PASSWORD="$(vault kv get -field=password secret/db)" myapp
```

### Q103: What is Docker Content Trust and how do you use it?
**Answer:**

Docker Content Trust provides digital signature verification for images.

**Enable Content Trust:**
```bash
export DOCKER_CONTENT_TRUST=1

# All pulls/runs will verify signatures
docker pull nginx:latest  # Will verify signature
```

**Signing Images:**
```bash
# Generate delegation key
docker trust key generate mykey

# Add signer
docker trust signer add --key mykey.pub mykey myregistry.com/myimage

# Sign and push
docker trust sign myregistry.com/myimage:latest
```

**Managing Keys:**
```bash
# List keys
docker trust key list

# Inspect repository trust
docker trust inspect --pretty nginx:latest

# View signers
docker trust inspect myregistry.com/myimage
```

**Notary Integration:**
```bash
# Initialize repository with notary
notary init myregistry.com/myimage

# Add targets
notary add myregistry.com/myimage latest sha256:abc123...

# Publish changes
notary publish myregistry.com/myimage
```

---

## ⚡ Performance & Optimization

### Q126: How do you optimize Docker container performance?
**Answer:**

**Performance Optimization Strategies:**

1. **Image Optimization:**
```dockerfile
# Use alpine base images
FROM node:16-alpine  # ~110MB vs node:16 ~900MB

# Multi-stage builds
FROM node:16 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:16-alpine
COPY --from=builder /app/dist .
```

2. **Layer Caching:**
```dockerfile
# Order by change frequency
COPY package*.json ./     # Changes rarely
RUN npm ci               # Cached if package.json unchanged
COPY . .                 # Changes frequently
```

3. **Resource Limits:**
```bash
# Set memory and CPU limits
docker run --memory="512m" --cpus="0.5" myapp

# Use cgroups v2 for better resource control
docker run --cgroupns=private myapp
```

4. **Storage Driver Optimization:**
```bash
# Use overlay2 storage driver (default)
# Configure in /etc/docker/daemon.json
{
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
```

5. **Network Optimization:**
```bash
# Use host networking for high throughput
docker run --network host myapp

# Optimize bridge network
docker network create --driver bridge \
  --opt com.docker.network.bridge.name=br-optimized \
  --opt com.docker.network.driver.mtu=9000 \
  optimized-network
```

### Q127: How do you monitor Docker container performance?
**Answer:**

**Monitoring Tools and Techniques:**

1. **Built-in Docker stats:**
```bash
# Real-time stats
docker stats

# Formatted output
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# Single container
docker stats container_name --no-stream
```

2. **cAdvisor:**
```yaml
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
```

3. **Prometheus + Grafana:**
```yaml
version: '3.8'
services:
  prometheus:
    image: prom/prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml

  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
```

4. **Application Performance Monitoring:**
```python
# Python example with Prometheus client
from prometheus_client import Counter, Histogram, start_http_server
import time

REQUEST_COUNT = Counter('app_requests_total', 'Total requests')
REQUEST_LATENCY = Histogram('app_request_duration_seconds', 'Request latency')

@REQUEST_LATENCY.time()
def process_request():
    REQUEST_COUNT.inc()
    # Your application logic
    time.sleep(0.1)

if __name__ == '__main__':
    start_http_server(8000)  # Metrics endpoint
    # Your app logic
```

### Q128: What are the best practices for container resource management?
**Answer:**

**Resource Management Best Practices:**

1. **Memory Management:**
```bash
# Set memory limits
docker run --memory="512m" --memory-swap="1g" myapp

# Memory reservation
docker run --memory="1g" --memory-reservation="512m" myapp

# OOM killer disable (use with caution)
docker run --oom-kill-disable --memory="1g" myapp
```

2. **CPU Management:**
```bash
# CPU limits (shares)
docker run --cpu-shares=512 myapp  # Relative weight

# CPU quota
docker run --cpu-period=100000 --cpu-quota=50000 myapp  # 50% CPU

# CPU sets
docker run --cpuset-cpus="0,2" myapp  # Specific cores
```

3. **I/O Management:**
```bash
# Block I/O weight
docker run --blkio-weight=500 myapp

# Device read/write rates
docker run --device-read-bps /dev/sda:1mb myapp
docker run --device-write-bps /dev/sda:1mb myapp
```

4. **Resource Monitoring:**
```bash
# Check container resource usage
docker exec myapp cat /sys/fs/cgroup/memory/memory.usage_in_bytes
docker exec myapp cat /sys/fs/cgroup/cpu/cpu.cfs_quota_us
```

---

## 🔍 Troubleshooting

### Q151: How do you troubleshoot a container that won't start?
**Answer:**

**Systematic Troubleshooting Approach:**

1. **Check container logs:**
```bash
# View logs
docker logs container_name
docker logs --tail 50 container_name
docker logs --since 2h container_name

# Follow logs in real-time
docker logs -f container_name
```

2. **Inspect container configuration:**
```bash
# Detailed container info
docker inspect container_name

# Check exit code
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

3. **Test image manually:**
```bash
# Run with shell access
docker run -it --entrypoint /bin/sh image_name

# Override command
docker run -it image_name /bin/bash
```

4. **Common issues and solutions:**

**Exit Code 125 - Docker daemon error:**
```bash
# Check Docker daemon
systemctl status docker
docker version
```

**Exit Code 126 - Container command not executable:**
```bash
# Check file permissions
docker run -it image_name ls -la /path/to/command
```

**Exit Code 127 - Container command not found:**
```bash
# Verify command exists
docker run -it image_name which command_name
```

**Port binding issues:**
```bash
# Check if port is already in use
netstat -tlnp | grep :8080
lsof -i :8080

# Use different port
docker run -p 8081:8080 myapp
```

### Q152: How do you debug networking issues in Docker?
**Answer:**

**Network Debugging Steps:**

1. **Basic connectivity tests:**
```bash
# Test container-to-container communication
docker exec web ping api
docker exec web telnet api 8080

# Test external connectivity
docker exec web ping 8.8.8.8
docker exec web curl http://google.com
```

2. **Inspect network configuration:**
```bash
# List networks
docker network ls

# Inspect specific network
docker network inspect bridge

# Check container network settings
docker exec web ip addr show
docker exec web ip route show
```

3. **DNS troubleshooting:**
```bash
# Test DNS resolution
docker exec web nslookup api
docker exec web nslookup google.com

# Check DNS configuration
docker exec web cat /etc/resolv.conf

# Custom DNS
docker run --dns 8.8.8.8 alpine nslookup google.com
```

4. **Port and firewall issues:**
```bash
# Check listening ports
docker exec web netstat -tlnp
docker exec web ss -tlnp

# Test port connectivity
docker exec web nc -zv api 8080

# Check iptables rules (host)
iptables -L -n
```

### Q153: What tools do you use for Docker debugging?
**Answer:**

**Essential Debugging Tools:**

1. **Docker native tools:**
```bash
# Container inspection
docker inspect container_name
docker logs container_name
docker exec -it container_name sh

# System information
docker system info
docker system df
docker system events
```

2. **Container debugging utilities:**
```bash
# Install debugging tools in container
docker exec -it container_name sh -c "
  apk add --no-cache \
    curl \
    wget \
    netcat-openbsd \
    tcpdump \
    strace \
    htop
"
```

3. **External debugging tools:**
```bash
# Dive - analyze image layers
dive image_name

# Docker-compose logs
docker-compose logs -f service_name

# Portainer - web UI
docker run -d -p 9000:9000 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  portainer/portainer-ce
```

4. **Network debugging:**
```bash
# Wireshark for container traffic
docker run --rm --net container:target_container \
  -v /tmp:/tmp \
  nicolaka/netshoot tcpdump -w /tmp/capture.pcap

# Network namespace debugging
nsenter -t $(docker inspect -f '{{.State.Pid}}' container_name) -n ip addr
```

5. **Performance debugging:**
```bash
# Container resource usage
docker stats --no-stream

# Process monitoring inside container
docker exec container_name top
docker exec container_name ps aux

# System calls tracing
docker exec container_name strace -p 1
```

---

## 🎯 Advanced Scenarios

### Q176: How would you implement a zero-downtime deployment with Docker?
**Answer:**

**Zero-Downtime Deployment Strategies:**

1. **Blue-Green Deployment:**
```bash
#!/bin/bash
# blue-green-deploy.sh

CURRENT_COLOR=$(docker ps --filter "name=app" --format "{{.Names}}" | head -1 | cut -d'-' -f2)
NEW_COLOR=$([[ $CURRENT_COLOR == "blue" ]] && echo "green" || echo "blue")

echo "Current: $CURRENT_COLOR, Deploying: $NEW_COLOR"

# Deploy new version
docker run -d --name app-$NEW_COLOR \
  --network app-network \
  myapp:$NEW_VERSION

# Health check
for i in {1..30}; do
  if docker exec app-$NEW_COLOR curl -f http://localhost:8080/health; then
    echo "Health check passed"
    break
  fi
  sleep 2
done

# Switch load balancer
docker exec load-balancer \
  sed -i "s/app-$CURRENT_COLOR/app-$NEW_COLOR/g" /etc/nginx/nginx.conf
docker exec load-balancer nginx -s reload

# Remove old version
docker stop app-$CURRENT_COLOR
docker rm app-$CURRENT_COLOR

echo "Deployment complete: $NEW_COLOR"
```

2. **Rolling Update with Docker Compose:**
```yaml
# docker-compose.yml
version: '3.8'
services:
  app:
    image: myapp:${VERSION}
    deploy:
      replicas: 4
      update_config:
        parallelism: 1
        delay: 10s
        failure_action: rollback
        order: start-first
      rollback_config:
        parallelism: 1
        delay: 5s
```

```bash
# Deploy with rolling update
VERSION=v2.0 docker stack deploy -c docker-compose.yml mystack
```

3. **Canary Deployment:**
```bash
# Deploy canary version (10% traffic)
docker run -d --name app-canary \
  --label traefik.http.services.app-canary.loadbalancer.server.weight=10 \
  myapp:canary

# Monitor metrics and gradually increase traffic
# If successful, replace all instances
```

### Q177: How do you handle database migrations in containerized applications?
**Answer:**

**Database Migration Strategies:**

1. **Init Containers (Kubernetes):**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
spec:
  template:
    spec:
      initContainers:
      - name: migrate
        image: myapp:latest
        command: ['python', 'manage.py', 'migrate']
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: url
      containers:
      - name: app
        image: myapp:latest
```

2. **Migration Job Pattern:**
```bash
# Run migration as separate container
docker run --rm \
  --network app-network \
  -e DATABASE_URL=postgresql://... \
  myapp:latest python manage.py migrate

# Then start application containers
docker-compose up -d app
```

3. **Sidecar Migration Container:**
```yaml
version: '3.8'
services:
  migrate:
    image: myapp:latest
    command: ["python", "manage.py", "migrate"]
    depends_on:
      - db
    restart: "no"
  
  app:
    image: myapp:latest
    depends_on:
      - migrate
      - db
```

4. **Application-Level Migration:**
```python
# Built into application startup
def migrate_database():
    """Run migrations on application startup"""
    try:
        # Check if migrations are needed
        with database.connection() as conn:
            # Run migration logic
            pass
    except Exception as e:
        logger.error(f"Migration failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    migrate_database()
    start_application()
```

### Q178: How do you implement distributed tracing in Docker containers?
**Answer:**

**Distributed Tracing Implementation:**

1. **Jaeger Setup:**
```yaml
version: '3.8'
services:
  jaeger:
    image: jaegertracing/all-in-one:latest
    ports:
      - "16686:16686"
      - "14268:14268"
    environment:
      - COLLECTOR_OTLP_ENABLED=true

  app:
    image: myapp:latest
    environment:
      - JAEGER_AGENT_HOST=jaeger
      - JAEGER_AGENT_PORT=6831
    depends_on:
      - jaeger
```

2. **Application Instrumentation:**
```python
# Python with OpenTelemetry
from opentelemetry import trace
from opentelemetry.exporter.jaeger.thrift import JaegerExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

# Configure tracing
trace.set_tracer_provider(TracerProvider())
tracer = trace.get_tracer(__name__)

jaeger_exporter = JaegerExporter(
    agent_host_name=os.getenv("JAEGER_AGENT_HOST", "localhost"),
    agent_port=int(os.getenv("JAEGER_AGENT_PORT", "6831")),
)

span_processor = BatchSpanProcessor(jaeger_exporter)
trace.get_tracer_provider().add_span_processor(span_processor)

# Instrument HTTP requests
from opentelemetry.instrumentation.requests import RequestsInstrumentor
RequestsInstrumentor().instrument()

# Manual instrumentation
@app.route('/api/users')
def get_users():
    with tracer.start_as_current_span("get_users") as span:
        span.set_attribute("http.method", "GET")
        span.set_attribute("http.url", "/api/users")
        
        users = fetch_users_from_db()
        span.set_attribute("users.count", len(users))
        
        return jsonify(users)
```

3. **Service Mesh Integration:**
```yaml
# Istio sidecar injection
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  labels:
    app: myapp
spec:
  template:
    metadata:
      annotations:
        sidecar.istio.io/inject: "true"
    spec:
      containers:
      - name: myapp
        image: myapp:latest
```

---

## 🔚 Bonus Questions

### Q199: Explain how you would architect a microservices platform using Docker.
**Answer:**

**Microservices Architecture with Docker:**

```yaml
# docker-compose.microservices.yml
version: '3.8'

services:
  # API Gateway
  api-gateway:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - user-service
      - product-service
      - order-service

  # User Service
  user-service:
    build: ./services/user
    environment:
      - DATABASE_URL=postgresql://user:pass@user-db:5432/users
      - REDIS_URL=redis://redis:6379
    depends_on:
      - user-db
      - redis

  user-db:
    image: postgres:13
    environment:
      POSTGRES_DB: users
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
    volumes:
      - user-data:/var/lib/postgresql/data

  # Product Service
  product-service:
    build: ./services/product
    environment:
      - DATABASE_URL=postgresql://product:pass@product-db:5432/products
    depends_on:
      - product-db

  product-db:
    image: postgres:13
    environment:
      POSTGRES_DB: products
      POSTGRES_USER: product
      POSTGRES_PASSWORD: pass
    volumes:
      - product-data:/var/lib/postgresql/data

  # Order Service
  order-service:
    build: ./services/order
    environment:
      - DATABASE_URL=postgresql://order:pass@order-db:5432/orders
      - MESSAGE_QUEUE=amqp://rabbitmq:5672
    depends_on:
      - order-db
      - rabbitmq

  order-db:
    image: postgres:13
    environment:
      POSTGRES_DB: orders
      POSTGRES_USER: order
      POSTGRES_PASSWORD: pass
    volumes:
      - order-data:/var/lib/postgresql/data

  # Shared Services
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  rabbitmq:
    image: rabbitmq:3-management
    ports:
      - "5672:5672"
      - "15672:15672"

  # Monitoring
  prometheus:
    image: prom/prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml

  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin

volumes:
  user-data:
  product-data:
  order-data:

networks:
  default:
    driver: bridge
```

**Architecture Principles:**
- **Single Responsibility**: Each service has one business function
- **Database per Service**: Independent data stores
- **API Gateway**: Single entry point for clients
- **Service Discovery**: Container names for internal communication
- **Event-Driven**: Message queue for async communication
- **Monitoring**: Centralized metrics and logging

### Q200: What is your approach to Docker in production?
**Answer:**

**Production Docker Strategy:**

1. **Security First:**
```dockerfile
# Production Dockerfile
FROM node:16-alpine AS base
RUN addgroup -g 1001 -S nodejs && adduser -S nextjs -u 1001

FROM base AS dependencies
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM base AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM base AS runtime
WORKDIR /app
USER nextjs
COPY --from=dependencies --chown=nextjs:nodejs /app/node_modules ./node_modules
COPY --from=build --chown=nextjs:nodejs /app/dist ./dist

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

CMD ["node", "dist/server.js"]
```

2. **Resource Management:**
```yaml
# Production compose with resource limits
version: '3.8'
services:
  app:
    image: myapp:${VERSION}
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
      restart_policy:
        condition: on-failure
        max_attempts: 3
```

3. **Monitoring and Observability:**
```yaml
# Comprehensive monitoring stack
services:
  app:
    image: myapp:latest
    labels:
      - "prometheus.io/scrape=true"
      - "prometheus.io/port=8080"

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro

  node-exporter:
    image: prom/node-exporter:latest
    command:
      - '--path.rootfs=/host'
    volumes:
      - '/:/host:ro,rslave'
```

4. **CI/CD Integration:**
```bash
# Production deployment pipeline
#!/bin/bash
set -e

# Build and test
docker build -t myapp:$BUILD_NUMBER .
docker run --rm myapp:$BUILD_NUMBER npm test

# Security scan
trivy image myapp:$BUILD_NUMBER

# Push to registry
docker tag myapp:$BUILD_NUMBER $REGISTRY/myapp:$BUILD_NUMBER
docker push $REGISTRY/myapp:$BUILD_NUMBER

# Deploy with zero downtime
docker stack deploy -c docker-compose.prod.yml myapp
```

**Production Checklist:**
- ✅ Use specific image tags, not `latest`
- ✅ Implement health checks
- ✅ Set resource limits
- ✅ Use non-root users
- ✅ Scan for vulnerabilities
- ✅ Implement monitoring and logging
- ✅ Automate deployments
- ✅ Plan for disaster recovery
- ✅ Regular security updates
- ✅ Performance testing and optimization

---

## 📝 Summary

This comprehensive Docker interview preparation covers:
- **200 questions** across all skill levels
- **Real-world scenarios** from production environments
- **Hands-on examples** with code snippets
- **Best practices** for each topic area
- **Troubleshooting guides** for common issues

**Study Approach:**
1. Start with fundamentals and build up
2. Practice each example hands-on
3. Understand the "why" behind each concept
4. Focus on production-ready implementations
5. Stay updated with Docker ecosystem changes

**Interview Tips:**
- Demonstrate practical experience with examples
- Explain trade-offs and alternatives
- Show understanding of production challenges
- Ask clarifying questions about the specific use case
- Be honest about experience level and areas for growth

---

**Next**: Continue to `../Kubernetes/` for container orchestration interview questions.
