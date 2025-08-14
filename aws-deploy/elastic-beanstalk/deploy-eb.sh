#!/bin/bash

# AWS Elastic Beanstalk Deployment Script for E-commerce Application

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
APP_NAME="ecommerce-app"
ENVIRONMENT_NAME="ecommerce-prod"
PLATFORM="64bit Amazon Linux 2 v3.4.0 running Docker"
REGION="us-east-1"
INSTANCE_TYPE="t3.medium"

# Check prerequisites
check_prerequisites() {
    print_status "🔍 Checking prerequisites..."
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI not found. Please install AWS CLI."
        exit 1
    fi
    
    if ! command -v eb &> /dev/null; then
        print_error "EB CLI not found. Installing..."
        pip install awsebcli
    fi
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker not found. Please install Docker."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Please run 'aws configure'."
        exit 1
    fi
    
    print_status "✅ All prerequisites met"
}

# Setup RDS database
setup_rds() {
    print_status "🗄️ Setting up RDS PostgreSQL database..."
    
    # Check if RDS instance exists
    if aws rds describe-db-instances --db-instance-identifier ecommerce-db --region $REGION &> /dev/null; then
        print_warning "RDS instance 'ecommerce-db' already exists"
        RDS_ENDPOINT=$(aws rds describe-db-instances --db-instance-identifier ecommerce-db --region $REGION --query 'DBInstances[0].Endpoint.Address' --output text)
    else
        print_status "Creating RDS instance..."
        
        # Create DB subnet group
        aws rds create-db-subnet-group \
            --db-subnet-group-name ecommerce-db-subnet-group \
            --db-subnet-group-description "Subnet group for ecommerce database" \
            --subnet-ids $(aws ec2 describe-subnets --region $REGION --query 'Subnets[?State==`available`].SubnetId' --output text | head -2) \
            --region $REGION || true
        
        # Create RDS instance
        aws rds create-db-instance \
            --db-instance-identifier ecommerce-db \
            --db-instance-class db.t3.micro \
            --engine postgres \
            --engine-version 15.4 \
            --master-username ecommerce_user \
            --master-user-password EcommercePass123! \
            --allocated-storage 20 \
            --storage-type gp3 \
            --db-name ecommerce \
            --backup-retention-period 7 \
            --storage-encrypted \
            --publicly-accessible true \
            --region $REGION \
            --tags Key=Name,Value=ecommerce-database
        
        print_status "⏳ Waiting for RDS instance to be available (this may take 10-15 minutes)..."
        aws rds wait db-instance-available --db-instance-identifier ecommerce-db --region $REGION
        
        RDS_ENDPOINT=$(aws rds describe-db-instances --db-instance-identifier ecommerce-db --region $REGION --query 'DBInstances[0].Endpoint.Address' --output text)
    fi
    
    print_status "✅ RDS setup complete. Endpoint: $RDS_ENDPOINT"
}

# Setup ElastiCache Redis
setup_elasticache() {
    print_status "🔴 Setting up ElastiCache Redis..."
    
    # Check if ElastiCache cluster exists
    if aws elasticache describe-cache-clusters --cache-cluster-id ecommerce-redis --region $REGION &> /dev/null; then
        print_warning "ElastiCache cluster 'ecommerce-redis' already exists"
        REDIS_ENDPOINT=$(aws elasticache describe-cache-clusters --cache-cluster-id ecommerce-redis --show-cache-node-info --region $REGION --query 'CacheClusters[0].CacheNodes[0].Endpoint.Address' --output text)
    else
        print_status "Creating ElastiCache cluster..."
        
        aws elasticache create-cache-cluster \
            --cache-cluster-id ecommerce-redis \
            --engine redis \
            --cache-node-type cache.t3.micro \
            --num-cache-nodes 1 \
            --engine-version 7.0 \
            --region $REGION \
            --tags Key=Name,Value=ecommerce-cache
        
        print_status "⏳ Waiting for ElastiCache cluster to be available..."
        aws elasticache wait cache-cluster-available --cache-cluster-id ecommerce-redis --region $REGION
        
        REDIS_ENDPOINT=$(aws elasticache describe-cache-clusters --cache-cluster-id ecommerce-redis --show-cache-node-info --region $REGION --query 'CacheClusters[0].CacheNodes[0].Endpoint.Address' --output text)
    fi
    
    print_status "✅ ElastiCache setup complete. Endpoint: $REDIS_ENDPOINT"
}

# Prepare application for deployment
prepare_application() {
    print_status "📦 Preparing application for Elastic Beanstalk..."
    
    # Create deployment directory
    rm -rf deploy-temp
    mkdir deploy-temp
    cd deploy-temp
    
    # Copy backend application
    cp -r ../../../backend/* .
    
    # Create Dockerrun.aws.json
    cat > Dockerrun.aws.json << EOF
{
  "AWSEBDockerrunVersion": "1",
  "Image": {
    "Name": "ecommerce-backend:latest",
    "Update": "true"
  },
  "Ports": [
    {
      "ContainerPort": "5000"
    }
  ]
}
EOF
    
    # Create .ebextensions directory
    mkdir -p .ebextensions
    
    # Create environment configuration
    cat > .ebextensions/01-environment.config << EOF
option_settings:
  aws:elasticbeanstalk:application:environment:
    FLASK_ENV: production
    DATABASE_HOST: $RDS_ENDPOINT
    DATABASE_PORT: 5432
    DATABASE_NAME: ecommerce
    DATABASE_USER: ecommerce_user
    DATABASE_PASSWORD: EcommercePass123!
    REDIS_HOST: $REDIS_ENDPOINT
    REDIS_PORT: 6379
    SECRET_KEY: eb-production-secret-key-12345
    JWT_SECRET_KEY: eb-production-jwt-secret-12345
  aws:autoscaling:launchconfiguration:
    InstanceType: $INSTANCE_TYPE
  aws:autoscaling:asg:
    MinSize: 2
    MaxSize: 10
  aws:elasticbeanstalk:environment:
    LoadBalancerType: application
    ServiceRole: aws-elasticbeanstalk-service-role
  aws:elasticbeanstalk:healthreporting:system:
    SystemType: enhanced
EOF
    
    # Create auto scaling configuration
    cat > .ebextensions/02-autoscaling.config << EOF
option_settings:
  aws:autoscaling:trigger:
    MeasureName: CPUUtilization
    Unit: Percent
    UpperThreshold: 80
    LowerThreshold: 20
    ScaleUpIncrement: 2
    ScaleDownIncrement: -1
    BreachDuration: 5
    Period: 5
    EvaluationPeriods: 1
    Statistic: Average
EOF
    
    # Create health check configuration
    cat > .ebextensions/03-healthcheck.config << EOF
option_settings:
  aws:elasticbeanstalk:application:
    Application Healthcheck URL: /health
  aws:elasticbeanstalk:healthreporting:system:
    SystemType: enhanced
  aws:elasticbeanstalk:cloudwatch:logs:
    StreamLogs: true
    DeleteOnTerminate: false
    RetentionInDays: 7
EOF
    
    print_status "✅ Application prepared for deployment"
}

# Initialize Elastic Beanstalk
initialize_eb() {
    print_status "🚀 Initializing Elastic Beanstalk application..."
    
    # Initialize EB application
    if [ ! -f .elasticbeanstalk/config.yml ]; then
        eb init $APP_NAME --platform docker --region $REGION --keyname
    fi
    
    print_status "✅ Elastic Beanstalk initialized"
}

# Deploy to Elastic Beanstalk
deploy_application() {
    print_status "🚀 Deploying to Elastic Beanstalk..."
    
    # Check if environment exists
    if aws elasticbeanstalk describe-environments --application-name $APP_NAME --environment-names $ENVIRONMENT_NAME --region $REGION &> /dev/null; then
        print_warning "Environment '$ENVIRONMENT_NAME' already exists. Updating..."
        eb deploy $ENVIRONMENT_NAME
    else
        print_status "Creating new environment '$ENVIRONMENT_NAME'..."
        eb create $ENVIRONMENT_NAME \
            --instance_type $INSTANCE_TYPE \
            --min-instances 2 \
            --max-instances 10 \
            --timeout 20
    fi
    
    print_status "✅ Deployment complete!"
}

# Get application URL
get_app_url() {
    print_status "🌐 Getting application URL..."
    
    APP_URL=$(aws elasticbeanstalk describe-environments \
        --application-name $APP_NAME \
        --environment-names $ENVIRONMENT_NAME \
        --region $REGION \
        --query 'Environments[0].CNAME' \
        --output text)
    
    if [ "$APP_URL" != "None" ] && [ -n "$APP_URL" ]; then
        print_status "✅ Application deployed successfully!"
        print_status "🔗 Application URL: http://$APP_URL"
        print_status "🔗 Admin URL: http://$APP_URL/admin"
        print_status "🔗 API URL: http://$APP_URL/api"
    else
        print_error "Could not retrieve application URL"
    fi
}

# Cleanup function
cleanup() {
    if [ -d "deploy-temp" ]; then
        cd ..
        rm -rf deploy-temp
        print_status "🧹 Cleaned up temporary files"
    fi
}

# Show monitoring information
show_monitoring() {
    print_status "📊 Monitoring Information:"
    echo "  • Environment Health: eb health"
    echo "  • Application Logs: eb logs"
    echo "  • Environment Status: eb status"
    echo "  • Open Application: eb open"
    echo "  • SSH to Instance: eb ssh"
    
    print_status "🔍 CloudWatch Monitoring:"
    echo "  • Application Metrics: https://console.aws.amazon.com/cloudwatch/home?region=$REGION"
    echo "  • RDS Monitoring: https://console.aws.amazon.com/rds/home?region=$REGION"
    echo "  • ElastiCache Monitoring: https://console.aws.amazon.com/elasticache/home?region=$REGION"
}

# Main execution
main() {
    print_status "🚀 Starting Elastic Beanstalk deployment for E-commerce Application"
    
    # Set trap for cleanup
    trap cleanup EXIT
    
    check_prerequisites
    setup_rds
    setup_elasticache
    prepare_application
    initialize_eb
    deploy_application
    get_app_url
    show_monitoring
    
    print_status "🎉 Deployment completed successfully!"
}

# Show help
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "AWS Elastic Beanstalk Deployment Script"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "This script will:"
    echo "  1. Set up RDS PostgreSQL database"
    echo "  2. Set up ElastiCache Redis cluster"
    echo "  3. Prepare the application for deployment"
    echo "  4. Initialize Elastic Beanstalk application"
    echo "  5. Deploy the application"
    echo ""
    echo "Prerequisites:"
    echo "  • AWS CLI configured with appropriate permissions"
    echo "  • EB CLI installed (will be installed automatically)"
    echo "  • Docker installed"
    echo ""
    echo "Environment variables you can set:"
    echo "  • APP_NAME (default: ecommerce-app)"
    echo "  • ENVIRONMENT_NAME (default: ecommerce-prod)"
    echo "  • REGION (default: us-east-1)"
    echo "  • INSTANCE_TYPE (default: t3.medium)"
    exit 0
fi

# Run main function
main
