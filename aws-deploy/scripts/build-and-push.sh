#!/bin/bash

# Build and Push Docker Images Script for E-commerce Application

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Configuration
REGION=${AWS_DEFAULT_REGION:-us-east-1}
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DATE=$(date +%Y%m%d-%H%M%S)
GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# Check prerequisites
check_prerequisites() {
    print_status "🔍 Checking prerequisites..."
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI not found. Please install AWS CLI first."
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker not found. Please install Docker first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Please run 'aws configure'."
        exit 1
    fi
    
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running. Please start Docker."
        exit 1
    fi
    
    print_status "✅ Prerequisites met"
}

# Login to ECR
ecr_login() {
    print_status "🔑 Logging in to ECR..."
    
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    ECR_ENDPOINT="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"
    
    aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ECR_ENDPOINT"
    
    print_status "✅ Successfully logged in to ECR"
}

# Build backend image
build_backend() {
    print_status "🔨 Building backend image..."
    
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    BACKEND_URI="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/ecommerce-backend"
    
    # Check if backend directory exists
    if [ ! -d "$PROJECT_ROOT/backend" ]; then
        print_error "Backend directory not found at $PROJECT_ROOT/backend"
        return 1
    fi
    
    cd "$PROJECT_ROOT/backend"
    
    # Build multi-stage Docker image
    print_status "Building backend image with tags: latest, $BUILD_DATE, $GIT_COMMIT"
    
    docker build \
        --build-arg BUILD_DATE="$BUILD_DATE" \
        --build-arg GIT_COMMIT="$GIT_COMMIT" \
        --tag ecommerce-backend:latest \
        --tag ecommerce-backend:"$BUILD_DATE" \
        --tag ecommerce-backend:"$GIT_COMMIT" \
        .
    
    # Tag for ECR
    docker tag ecommerce-backend:latest "$BACKEND_URI:latest"
    docker tag ecommerce-backend:"$BUILD_DATE" "$BACKEND_URI:$BUILD_DATE"
    docker tag ecommerce-backend:"$GIT_COMMIT" "$BACKEND_URI:$GIT_COMMIT"
    
    print_status "✅ Backend image built successfully"
    
    # Push images
    print_status "📤 Pushing backend images to ECR..."
    docker push "$BACKEND_URI:latest"
    docker push "$BACKEND_URI:$BUILD_DATE"
    docker push "$BACKEND_URI:$GIT_COMMIT"
    
    print_status "✅ Backend images pushed successfully"
    print_status "📋 Image URIs:"
    print_status "  Latest: $BACKEND_URI:latest"
    print_status "  Build: $BACKEND_URI:$BUILD_DATE"
    print_status "  Commit: $BACKEND_URI:$GIT_COMMIT"
}

# Build nginx image
build_nginx() {
    print_status "🔨 Building nginx image..."
    
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    NGINX_URI="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/ecommerce-nginx"
    
    # Check if nginx dockerfile exists
    if [ ! -f "$PROJECT_ROOT/docker-compose/nginx.Dockerfile" ]; then
        print_warning "Nginx Dockerfile not found. Skipping nginx build."
        return 0
    fi
    
    cd "$PROJECT_ROOT"
    
    # Build nginx image
    docker build \
        --file docker-compose/nginx.Dockerfile \
        --build-arg BUILD_DATE="$BUILD_DATE" \
        --build-arg GIT_COMMIT="$GIT_COMMIT" \
        --tag ecommerce-nginx:latest \
        --tag ecommerce-nginx:"$BUILD_DATE" \
        --tag ecommerce-nginx:"$GIT_COMMIT" \
        .
    
    # Tag for ECR
    docker tag ecommerce-nginx:latest "$NGINX_URI:latest"
    docker tag ecommerce-nginx:"$BUILD_DATE" "$NGINX_URI:$BUILD_DATE"
    docker tag ecommerce-nginx:"$GIT_COMMIT" "$NGINX_URI:$GIT_COMMIT"
    
    print_status "✅ Nginx image built successfully"
    
    # Push images
    print_status "📤 Pushing nginx images to ECR..."
    docker push "$NGINX_URI:latest"
    docker push "$NGINX_URI:$BUILD_DATE"
    docker push "$NGINX_URI:$GIT_COMMIT"
    
    print_status "✅ Nginx images pushed successfully"
    print_status "📋 Image URIs:"
    print_status "  Latest: $NGINX_URI:latest"
    print_status "  Build: $NGINX_URI:$BUILD_DATE"
    print_status "  Commit: $NGINX_URI:$GIT_COMMIT"
}

# Build worker image (if exists)
build_worker() {
    print_status "🔨 Building worker image..."
    
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    WORKER_URI="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/ecommerce-worker"
    
    # Check if worker directory or dockerfile exists
    if [ ! -d "$PROJECT_ROOT/worker" ] && [ ! -f "$PROJECT_ROOT/backend/Dockerfile.worker" ]; then
        print_warning "Worker Dockerfile not found. Skipping worker build."
        return 0
    fi
    
    # Use worker directory if it exists, otherwise use backend with worker dockerfile
    if [ -d "$PROJECT_ROOT/worker" ]; then
        cd "$PROJECT_ROOT/worker"
        DOCKERFILE="Dockerfile"
    else
        cd "$PROJECT_ROOT/backend"
        DOCKERFILE="Dockerfile.worker"
    fi
    
    if [ ! -f "$DOCKERFILE" ]; then
        print_warning "Worker Dockerfile not found. Skipping worker build."
        return 0
    fi
    
    # Build worker image
    docker build \
        --file "$DOCKERFILE" \
        --build-arg BUILD_DATE="$BUILD_DATE" \
        --build-arg GIT_COMMIT="$GIT_COMMIT" \
        --tag ecommerce-worker:latest \
        --tag ecommerce-worker:"$BUILD_DATE" \
        --tag ecommerce-worker:"$GIT_COMMIT" \
        .
    
    # Tag for ECR
    docker tag ecommerce-worker:latest "$WORKER_URI:latest"
    docker tag ecommerce-worker:"$BUILD_DATE" "$WORKER_URI:$BUILD_DATE"
    docker tag ecommerce-worker:"$GIT_COMMIT" "$WORKER_URI:$GIT_COMMIT"
    
    print_status "✅ Worker image built successfully"
    
    # Push images
    print_status "📤 Pushing worker images to ECR..."
    docker push "$WORKER_URI:latest"
    docker push "$WORKER_URI:$BUILD_DATE"
    docker push "$WORKER_URI:$GIT_COMMIT"
    
    print_status "✅ Worker images pushed successfully"
    print_status "📋 Image URIs:"
    print_status "  Latest: $WORKER_URI:latest"
    print_status "  Build: $WORKER_URI:$BUILD_DATE"
    print_status "  Commit: $WORKER_URI:$GIT_COMMIT"
}

# Clean up local images
cleanup_local_images() {
    echo ""
    echo -n "Do you want to clean up local Docker images? (y/N): "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        return 0
    fi
    
    print_status "🧹 Cleaning up local Docker images..."
    
    # Remove local images (keep the latest)
    docker rmi ecommerce-backend:"$BUILD_DATE" ecommerce-backend:"$GIT_COMMIT" 2>/dev/null || true
    docker rmi ecommerce-nginx:"$BUILD_DATE" ecommerce-nginx:"$GIT_COMMIT" 2>/dev/null || true
    docker rmi ecommerce-worker:"$BUILD_DATE" ecommerce-worker:"$GIT_COMMIT" 2>/dev/null || true
    
    # Clean up dangling images
    docker image prune -f
    
    print_status "✅ Local cleanup completed"
}

# Scan images for vulnerabilities
scan_images() {
    echo ""
    echo -n "Do you want to scan images for vulnerabilities? (y/N): "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        return 0
    fi
    
    print_status "🔍 Scanning images for vulnerabilities..."
    
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    
    # Scan backend image
    print_status "Scanning backend image..."
    aws ecr start-image-scan \
        --repository-name ecommerce-backend \
        --image-id imageTag=latest \
        --region "$REGION" || true
    
    # Wait for scan to complete
    sleep 10
    
    # Get scan results
    SCAN_RESULTS=$(aws ecr describe-image-scan-findings \
        --repository-name ecommerce-backend \
        --image-id imageTag=latest \
        --region "$REGION" 2>/dev/null || echo '{"imageScanFindings":{"findings":[]}}')
    
    CRITICAL_COUNT=$(echo "$SCAN_RESULTS" | jq -r '.imageScanFindings.findingCounts.CRITICAL // 0')
    HIGH_COUNT=$(echo "$SCAN_RESULTS" | jq -r '.imageScanFindings.findingCounts.HIGH // 0')
    MEDIUM_COUNT=$(echo "$SCAN_RESULTS" | jq -r '.imageScanFindings.findingCounts.MEDIUM // 0')
    
    print_status "📊 Vulnerability scan results:"
    print_status "  Critical: $CRITICAL_COUNT"
    print_status "  High: $HIGH_COUNT"
    print_status "  Medium: $MEDIUM_COUNT"
    
    if [ "$CRITICAL_COUNT" != "0" ] || [ "$HIGH_COUNT" != "0" ]; then
        print_warning "⚠️ High or critical vulnerabilities found. Consider updating base images."
    else
        print_status "✅ No critical or high vulnerabilities found"
    fi
}

# Generate build report
generate_build_report() {
    print_status "📄 Generating build report..."
    
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    REPORT_FILE="build-report-$BUILD_DATE.json"
    
    cat > "$REPORT_FILE" << EOF
{
  "buildInfo": {
    "buildDate": "$BUILD_DATE",
    "gitCommit": "$GIT_COMMIT",
    "awsAccount": "$ACCOUNT_ID",
    "awsRegion": "$REGION",
    "builder": "$(whoami)",
    "buildHost": "$(hostname)"
  },
  "images": {
    "backend": {
      "repository": "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/ecommerce-backend",
      "tags": ["latest", "$BUILD_DATE", "$GIT_COMMIT"]
    },
    "nginx": {
      "repository": "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/ecommerce-nginx",
      "tags": ["latest", "$BUILD_DATE", "$GIT_COMMIT"]
    },
    "worker": {
      "repository": "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/ecommerce-worker",
      "tags": ["latest", "$BUILD_DATE", "$GIT_COMMIT"]
    }
  }
}
EOF
    
    print_status "✅ Build report generated: $REPORT_FILE"
}

# Main execution
main() {
    print_status "🚀 Building and Pushing Docker Images for E-commerce Application"
    print_status "=============================================================="
    
    check_prerequisites
    ecr_login
    build_backend
    build_nginx
    build_worker
    scan_images
    generate_build_report
    cleanup_local_images
    
    print_status ""
    print_status "🎉 Build and push completed successfully!"
    print_status ""
    print_status "📋 Summary:"
    print_status "  Build Date: $BUILD_DATE"
    print_status "  Git Commit: $GIT_COMMIT"
    print_status "  AWS Region: $REGION"
    print_status ""
    print_status "🔧 Next steps:"
    print_status "  1. Update your deployment configurations with the new image URIs"
    print_status "  2. Deploy to your target environment (EKS, ECS, or Elastic Beanstalk)"
    print_status "  3. Monitor the deployment and application health"
}

# Usage function
usage() {
    echo "Usage: $0 [backend|nginx|worker|all]"
    echo ""
    echo "Commands:"
    echo "  backend  - Build and push backend image only"
    echo "  nginx    - Build and push nginx image only"
    echo "  worker   - Build and push worker image only"
    echo "  all      - Build and push all images (default)"
    echo ""
    echo "Environment Variables:"
    echo "  AWS_DEFAULT_REGION - AWS region (default: us-east-1)"
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-all}" in
        backend)
            check_prerequisites
            ecr_login
            build_backend
            ;;
        nginx)
            check_prerequisites
            ecr_login
            build_nginx
            ;;
        worker)
            check_prerequisites
            ecr_login
            build_worker
            ;;
        all)
            main
            ;;
        -h|--help|help)
            usage
            ;;
        *)
            echo "Unknown command: $1"
            usage
            exit 1
            ;;
    esac
fi
