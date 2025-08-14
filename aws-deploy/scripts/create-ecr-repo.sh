#!/bin/bash

# ECR Repository Creation Script for E-commerce Application

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
REPOSITORIES=("ecommerce-backend" "ecommerce-nginx" "ecommerce-worker")

# Check prerequisites
check_prerequisites() {
    print_status "🔍 Checking prerequisites..."
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI not found. Please install AWS CLI first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Please run 'aws configure'."
        exit 1
    fi
    
    print_status "✅ Prerequisites met"
}

# Create ECR repositories
create_repositories() {
    print_status "🐳 Creating ECR repositories..."
    
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    
    for repo in "${REPOSITORIES[@]}"; do
        print_status "Creating repository: $repo"
        
        # Check if repository already exists
        if aws ecr describe-repositories --repository-names "$repo" --region "$REGION" &> /dev/null; then
            print_warning "Repository '$repo' already exists"
            continue
        fi
        
        # Create repository
        aws ecr create-repository \
            --repository-name "$repo" \
            --region "$REGION" \
            --image-scanning-configuration scanOnPush=true \
            --encryption-configuration encryptionType=AES256 \
            --tags Key=Project,Value=ecommerce Key=Environment,Value=production
        
        # Set lifecycle policy
        cat > lifecycle-policy.json << EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep last 10 images",
      "selection": {
        "tagStatus": "tagged",
        "countType": "imageCountMoreThan",
        "countNumber": 10
      },
      "action": {
        "type": "expire"
      }
    },
    {
      "rulePriority": 2,
      "description": "Delete untagged images older than 1 day",
      "selection": {
        "tagStatus": "untagged",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 1
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
        
        aws ecr put-lifecycle-policy \
            --repository-name "$repo" \
            --lifecycle-policy-text file://lifecycle-policy.json \
            --region "$REGION"
        
        rm lifecycle-policy.json
        
        print_status "✅ Repository '$repo' created successfully"
    done
    
    print_status "📊 Repository URLs:"
    for repo in "${REPOSITORIES[@]}"; do
        echo "  $repo: $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$repo"
    done
}

# Set repository permissions
set_permissions() {
    print_status "🔐 Setting repository permissions..."
    
    for repo in "${REPOSITORIES[@]}"; do
        # Create a policy that allows pull access from ECS and other AWS services
        cat > repo-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowPull",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ecs-tasks.amazonaws.com",
          "ec2.amazonaws.com"
        ]
      },
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability"
      ]
    }
  ]
}
EOF
        
        aws ecr set-repository-policy \
            --repository-name "$repo" \
            --policy-text file://repo-policy.json \
            --region "$REGION" || true
        
        rm repo-policy.json
    done
    
    print_status "✅ Repository permissions set"
}

# Get login credentials
get_login_credentials() {
    print_status "🔑 Getting ECR login credentials..."
    
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    ECR_ENDPOINT="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"
    
    # Get login token
    aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ECR_ENDPOINT"
    
    print_status "✅ Docker logged in to ECR successfully"
    
    # Save login command for future use
    cat > ecr-login.sh << EOF
#!/bin/bash
# ECR Login Script
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_ENDPOINT
EOF
    chmod +x ecr-login.sh
    
    print_status "📝 Login script saved as 'ecr-login.sh'"
}

# Show repository information
show_repository_info() {
    print_status "📋 Repository Information"
    print_status "========================"
    
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    
    for repo in "${REPOSITORIES[@]}"; do
        echo ""
        print_status "Repository: $repo"
        echo "  URI: $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$repo"
        echo "  Region: $REGION"
        
        # Get repository details
        REPO_INFO=$(aws ecr describe-repositories --repository-names "$repo" --region "$REGION" 2>/dev/null || echo "null")
        if [ "$REPO_INFO" != "null" ]; then
            CREATED_AT=$(echo "$REPO_INFO" | jq -r '.repositories[0].createdAt')
            IMAGE_COUNT=$(aws ecr describe-images --repository-name "$repo" --region "$REGION" --query 'length(imageDetails)' --output text 2>/dev/null || echo "0")
            echo "  Created: $CREATED_AT"
            echo "  Images: $IMAGE_COUNT"
        fi
    done
}

# Build and push sample image
build_and_push_sample() {
    echo ""
    echo -n "Do you want to build and push the backend image now? (y/N): "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        return 0
    fi
    
    print_status "🔨 Building and pushing backend image..."
    
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    BACKEND_URI="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/ecommerce-backend"
    
    # Check if backend directory exists
    if [ ! -d "../../backend" ]; then
        print_error "Backend directory not found at ../../backend"
        return 1
    fi
    
    # Build image
    cd ../../backend
    docker build -t ecommerce-backend .
    docker tag ecommerce-backend:latest "$BACKEND_URI:latest"
    docker tag ecommerce-backend:latest "$BACKEND_URI:$(date +%Y%m%d-%H%M%S)"
    
    # Push image
    docker push "$BACKEND_URI:latest"
    docker push "$BACKEND_URI:$(date +%Y%m%d-%H%M%S)"
    
    cd ../aws-deploy/scripts
    
    print_status "✅ Backend image built and pushed successfully"
    print_status "Image URI: $BACKEND_URI:latest"
}

# Cleanup repositories
cleanup_repositories() {
    print_warning "⚠️ This will delete all ECR repositories and their images!"
    echo -n "Are you sure you want to continue? (y/N): "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        return 0
    fi
    
    print_status "🧹 Cleaning up ECR repositories..."
    
    for repo in "${REPOSITORIES[@]}"; do
        if aws ecr describe-repositories --repository-names "$repo" --region "$REGION" &> /dev/null; then
            # Force delete repository with all images
            aws ecr delete-repository \
                --repository-name "$repo" \
                --region "$REGION" \
                --force
            print_status "🗑️ Deleted repository: $repo"
        else
            print_warning "Repository '$repo' does not exist"
        fi
    done
    
    print_status "✅ Cleanup completed"
}

# Main execution
main() {
    print_status "🚀 ECR Repository Setup for E-commerce Application"
    print_status "================================================="
    
    check_prerequisites
    create_repositories
    set_permissions
    get_login_credentials
    show_repository_info
    build_and_push_sample
    
    print_status ""
    print_status "🎉 ECR setup completed successfully!"
    print_status ""
    print_status "📋 Next steps:"
    print_status "  1. Use the repository URIs in your deployment scripts"
    print_status "  2. Build and push your application images"
    print_status "  3. Update your ECS task definitions or Kubernetes manifests"
    print_status ""
    print_status "🔧 Useful commands:"
    print_status "  ./ecr-login.sh                     # Login to ECR"
    print_status "  aws ecr list-images --repository-name ecommerce-backend --region $REGION"
    print_status "  docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/ecommerce-backend:latest"
}

# Usage function
usage() {
    echo "Usage: $0 [create|info|cleanup]"
    echo ""
    echo "Commands:"
    echo "  create   - Create ECR repositories (default)"
    echo "  info     - Show repository information"
    echo "  cleanup  - Delete all repositories"
    echo ""
    echo "Environment Variables:"
    echo "  AWS_DEFAULT_REGION - AWS region (default: us-east-1)"
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-create}" in
        create)
            main
            ;;
        info)
            check_prerequisites
            show_repository_info
            ;;
        cleanup)
            check_prerequisites
            cleanup_repositories
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
