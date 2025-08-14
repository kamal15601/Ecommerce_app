#!/bin/bash
# Master AWS Deployment Script
# Comprehensive deployment automation for the e-commerce application on AWS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION=${AWS_REGION:-us-east-1}
APP_NAME=${APP_NAME:-ecommerce-app}
ENVIRONMENT=${ENVIRONMENT:-dev}
DEPLOYMENT_METHOD=${DEPLOYMENT_METHOD}

echo -e "${BLUE}🚀 E-Commerce AWS Deployment Master Script${NC}"
echo -e "${BLUE}===========================================${NC}"
echo ""

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        echo "Visit: https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS CLI is not configured. Please run 'aws configure'"
        exit 1
    fi
    
    # Check Docker (for container deployments)
    if ! command -v docker &> /dev/null; then
        print_warning "Docker is not installed. Required for ECS/EKS deployments."
    fi
    
    # Check kubectl (for EKS)
    if ! command -v kubectl &> /dev/null; then
        print_warning "kubectl is not installed. Required for EKS deployment."
    fi
    
    print_status "Prerequisites check completed"
}

# Display deployment options
show_deployment_options() {
    echo ""
    print_info "Available AWS Deployment Methods:"
    echo ""
    echo "1. 🌱 Elastic Beanstalk (Recommended for beginners)"
    echo "   - Easy setup and management"
    echo "   - Automatic scaling and load balancing"
    echo "   - Built-in monitoring"
    echo ""
    echo "2. ☸️  Amazon EKS (Kubernetes)"
    echo "   - Production-ready Kubernetes"
    echo "   - High scalability and flexibility"
    echo "   - Advanced orchestration features"
    echo ""
    echo "3. 🐳 Amazon ECS with Fargate"
    echo "   - Serverless containers"
    echo "   - No infrastructure management"
    echo "   - Pay-per-use pricing"
    echo ""
    echo "4. 📊 Setup Monitoring Only"
    echo "   - CloudWatch dashboards and alarms"
    echo "   - Application performance monitoring"
    echo ""
}

# Setup monitoring
setup_monitoring() {
    print_info "Setting up AWS monitoring..."
    
    cd monitoring
    
    # Make scripts executable
    chmod +x setup-alarms.sh
    
    # Setup CloudWatch alarms
    if [ ! -z "$NOTIFICATION_EMAIL" ]; then
        export NOTIFICATION_EMAIL
        ./setup-alarms.sh
    else
        print_warning "NOTIFICATION_EMAIL not set. Skipping email notifications."
        ./setup-alarms.sh
    fi
    
    print_status "Monitoring setup completed"
    cd ..
}

# Deploy to Elastic Beanstalk
deploy_elastic_beanstalk() {
    print_info "Deploying to AWS Elastic Beanstalk..."
    
    cd elastic-beanstalk
    chmod +x deploy-eb.sh
    ./deploy-eb.sh
    
    print_status "Elastic Beanstalk deployment completed"
    cd ..
}

# Deploy to EKS
deploy_eks() {
    print_info "Deploying to Amazon EKS..."
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is required for EKS deployment"
        exit 1
    fi
    
    cd eks
    chmod +x deploy-eks.sh
    ./deploy-eks.sh
    
    print_status "EKS deployment completed"
    cd ..
}

# Deploy to ECS Fargate
deploy_ecs_fargate() {
    print_info "Deploying to Amazon ECS with Fargate..."
    
    cd ecs-fargate
    chmod +x deploy-ecs.sh
    ./deploy-ecs.sh
    
    print_status "ECS Fargate deployment completed"
    cd ..
}

# Setup AWS infrastructure
setup_infrastructure() {
    print_info "Setting up AWS infrastructure..."
    
    # Setup AWS CLI and dependencies
    cd scripts
    chmod +x *.sh
    ./setup-aws-cli.sh
    
    # Create ECR repository
    ./create-ecr-repo.sh
    
    # Build and push Docker image
    ./build-and-push.sh
    
    print_status "Infrastructure setup completed"
    cd ..
}

# Main deployment logic
main() {
    check_prerequisites
    
    # Make all scripts executable
    print_info "Making all deployment scripts executable..."
    chmod +x make-executable.sh
    ./make-executable.sh
    
    # If deployment method is not specified, show options
    if [ -z "$DEPLOYMENT_METHOD" ]; then
        show_deployment_options
        echo ""
        read -p "Choose deployment method (1-4): " choice
        
        case $choice in
            1) DEPLOYMENT_METHOD="elastic-beanstalk" ;;
            2) DEPLOYMENT_METHOD="eks" ;;
            3) DEPLOYMENT_METHOD="ecs-fargate" ;;
            4) DEPLOYMENT_METHOD="monitoring" ;;
            *) print_error "Invalid choice. Exiting."; exit 1 ;;
        esac
    fi
    
    # Execute deployment
    case $DEPLOYMENT_METHOD in
        "elastic-beanstalk")
            setup_infrastructure
            deploy_elastic_beanstalk
            setup_monitoring
            ;;
        "eks")
            setup_infrastructure
            deploy_eks
            setup_monitoring
            ;;
        "ecs-fargate")
            setup_infrastructure
            deploy_ecs_fargate
            setup_monitoring
            ;;
        "monitoring")
            setup_monitoring
            ;;
        *)
            print_error "Unknown deployment method: $DEPLOYMENT_METHOD"
            exit 1
            ;;
    esac
    
    print_status "Deployment completed successfully!"
    echo ""
    print_info "Next steps:"
    echo "1. Check AWS Console for deployed resources"
    echo "2. Verify application is running and accessible"
    echo "3. Monitor CloudWatch dashboards and alarms"
    echo "4. Configure custom domain (if needed)"
    echo ""
    print_info "Useful commands:"
    echo "- View AWS resources: aws cloudformation list-stacks"
    echo "- Check ECS services: aws ecs list-services --cluster ${APP_NAME}"
    echo "- Monitor logs: aws logs describe-log-groups"
}

# Script usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -m, --method METHOD     Deployment method (elastic-beanstalk|eks|ecs-fargate|monitoring)"
    echo "  -r, --region REGION     AWS region (default: us-east-1)"
    echo "  -n, --name NAME         Application name (default: ecommerce-app)"
    echo "  -e, --env ENVIRONMENT   Environment (dev|staging|prod) (default: dev)"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  AWS_REGION              AWS region"
    echo "  APP_NAME                Application name"
    echo "  ENVIRONMENT             Deployment environment"
    echo "  NOTIFICATION_EMAIL      Email for CloudWatch alerts"
    echo ""
    echo "Examples:"
    echo "  $0 --method elastic-beanstalk --region us-west-2"
    echo "  $0 -m eks -e prod"
    echo "  NOTIFICATION_EMAIL=admin@example.com $0 -m monitoring"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--method)
            DEPLOYMENT_METHOD="$2"
            shift 2
            ;;
        -r|--region)
            AWS_REGION="$2"
            shift 2
            ;;
        -n|--name)
            APP_NAME="$2"
            shift 2
            ;;
        -e|--env)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Export variables
export AWS_REGION
export APP_NAME
export ENVIRONMENT

# Run main function
main
