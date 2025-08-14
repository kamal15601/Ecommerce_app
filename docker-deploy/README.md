# Docker Deployment

This folder contains all files needed to run the application using Docker containers.

## Files in this folder:

### Docker Compose Files
- `docker-compose.yml` - Main Docker Compose file for development
- `docker-compose.prod.yml` - Production Docker Compose configuration
- `docker-compose.override.yml` - Local overrides for development

### Docker Configuration
- `backend.Dockerfile` - Dockerfile for the Flask backend
- `nginx.Dockerfile` - Dockerfile for Nginx reverse proxy
- `redis.Dockerfile` - Dockerfile for Redis cache
- `nginx.conf` - Nginx configuration
- `redis.conf` - Redis configuration

### Environment Files
- `.env.docker` - Environment variables for Docker deployment
- `.env.docker.prod` - Production environment variables

### Scripts
- `deploy-docker.sh` - Deploy using Docker Compose
- `build-images.sh` - Build all Docker images
- `logs.sh` - View application logs
- `cleanup.sh` - Clean up Docker resources

## Services included:

1. **Backend** (Flask Application)
   - Port: 5000
   - Health check enabled
   - Auto-restart on failure

2. **Database** (PostgreSQL)
   - Port: 5432
   - Persistent volume for data
   - Automatic initialization

3. **Cache** (Redis)
   - Port: 6379
   - Persistent volume for data
   - Password protected

4. **Reverse Proxy** (Nginx)
   - Port: 80
   - Load balancing
   - Static file serving

## How to use:

### Development:
```bash
./deploy-docker.sh dev
```

### Production:
```bash
./deploy-docker.sh prod
```

### View logs:
```bash
./logs.sh
```

### Clean up:
```bash
./cleanup.sh
```

## Requirements:
- Docker 20.10+
- Docker Compose 2.0+
