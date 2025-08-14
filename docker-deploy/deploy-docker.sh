#!/bin/bash

# Docker Deployment Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Get deployment mode
MODE=${1:-dev}

if [ "$MODE" != "dev" ] && [ "$MODE" != "prod" ]; then
    print_error "Usage: $0 [dev|prod]"
    exit 1
fi

print_status "🚀 Deploying E-commerce Application in $MODE mode"

# Set environment file based on mode
if [ "$MODE" = "prod" ]; then
    ENV_FILE=".env.docker.prod"
    COMPOSE_FILE="docker-compose.yml:docker-compose.prod.yml"
else
    ENV_FILE=".env.docker"
    COMPOSE_FILE="docker-compose.yml"
fi

# Check if environment file exists
if [ ! -f "$ENV_FILE" ]; then
    print_error "Environment file $ENV_FILE not found!"
    exit 1
fi

# Export environment variables
export COMPOSE_FILE
set -a
source "$ENV_FILE"
set +a

# Build images
print_status "🔨 Building Docker images..."
docker-compose build --no-cache

# Stop existing containers
print_status "🛑 Stopping existing containers..."
docker-compose down

# Start services
print_status "🚀 Starting services..."
docker-compose up -d

# Wait for services to be healthy
print_status "⏳ Waiting for services to be healthy..."
sleep 30

# Check service health
print_status "🏥 Checking service health..."

SERVICES=("backend" "database" "redis" "nginx")
for service in "${SERVICES[@]}"; do
    if docker-compose ps -q "$service" > /dev/null; then
        health=$(docker inspect --format='{{.State.Health.Status}}' "ecommerce-$service" 2>/dev/null || echo "no-health-check")
        if [ "$health" = "healthy" ] || [ "$health" = "no-health-check" ]; then
            print_status "✅ $service is healthy"
        else
            print_warning "⚠️ $service health status: $health"
        fi
    else
        print_error "❌ $service is not running"
    fi
done

# Show running containers
print_status "📋 Running containers:"
docker-compose ps

# Show application URLs
print_status "🌐 Application URLs:"
echo "  Frontend: http://localhost"
echo "  API: http://localhost/api"
echo "  Database: localhost:5432"
echo "  Redis: localhost:6379"

# Show logs command
print_status "📝 To view logs, run: ./logs.sh"
print_status "🛑 To stop services, run: docker-compose down"

print_status "✅ Deployment complete!"
