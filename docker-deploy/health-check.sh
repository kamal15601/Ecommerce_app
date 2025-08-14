#!/bin/bash

# Docker Services Health Check Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_service_health() {
    local service_name=$1
    local container_name=$2
    local health_check=$3
    
    print_status "🔍 Checking $service_name health..."
    
    # Check if container is running
    if ! docker ps --format "table {{.Names}}" | grep -q "$container_name"; then
        print_error "❌ $service_name container '$container_name' is not running"
        return 1
    fi
    
    # Check container health
    local health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "no-health-check")
    
    if [ "$health_status" = "healthy" ]; then
        print_status "✅ $service_name is healthy"
        return 0
    elif [ "$health_status" = "no-health-check" ]; then
        # Manual health check
        if eval "$health_check"; then
            print_status "✅ $service_name is responding"
            return 0
        else
            print_error "❌ $service_name is not responding"
            return 1
        fi
    else
        print_warning "⚠️ $service_name health status: $health_status"
        return 1
    fi
}

check_all_services() {
    local failed_services=0
    
    print_status "🏥 Checking all E-commerce application services..."
    
    # Check Backend Service
    check_service_health "Backend" "ecommerce-backend" "curl -f http://localhost:5000/health" || ((failed_services++))
    
    # Check Database Service
    check_service_health "Database" "ecommerce-db" "docker exec ecommerce-db pg_isready -U ecommerce_user -d ecommerce" || ((failed_services++))
    
    # Check Redis Service
    check_service_health "Redis" "ecommerce-redis" "docker exec ecommerce-redis redis-cli ping" || ((failed_services++))
    
    # Check Nginx Service
    check_service_health "Nginx" "ecommerce-nginx" "curl -f http://localhost/health" || ((failed_services++))
    
    return $failed_services
}

show_service_logs() {
    local service=$1
    local lines=${2:-50}
    
    print_status "📝 Last $lines lines of $service logs:"
    docker-compose logs --tail=$lines "$service"
}

main() {
    print_status "🚀 E-commerce Application Health Check"
    
    check_all_services
    local result=$?
    
    if [ $result -eq 0 ]; then
        print_status "🎉 All services are healthy!"
        
        # Show service status
        print_status "📊 Service Status:"
        docker-compose ps
        
    else
        print_error "💥 $result service(s) are unhealthy"
        
        print_status "📋 Container Status:"
        docker-compose ps
        
        print_warning "Use './logs.sh [service_name]' to view logs"
        
        exit 1
    fi
}

# Show logs if requested
if [ "$1" = "logs" ]; then
    if [ -n "$2" ]; then
        show_service_logs "$2" "$3"
    else
        print_status "📝 All service logs:"
        docker-compose logs --tail=20
    fi
    exit 0
fi

# Show usage
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 [logs [service_name] [lines]]"
    echo ""
    echo "Examples:"
    echo "  $0                    # Check all services health"
    echo "  $0 logs               # Show all service logs"
    echo "  $0 logs backend       # Show backend service logs"
    echo "  $0 logs database 100  # Show last 100 lines of database logs"
    exit 0
fi

main
