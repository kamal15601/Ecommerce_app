#!/bin/bash

# Amazon ECS Fargate Deployment Script for E-commerce Application

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
CLUSTER_NAME="ecommerce-cluster"
SERVICE_NAME="ecommerce-backend"
TASK_FAMILY="ecommerce-backend"
REGION="us-east-1"
STACK_NAME="ecommerce-infrastructure"

# Check prerequisites
check_prerequisites() {
    print_status "🔍 Checking prerequisites..."
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI not found. Please install AWS CLI."
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker not found. Please install Docker."
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        print_error "jq not found. Installing..."
        # Install jq based on OS
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            sudo apt-get update && sudo apt-get install -y jq
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            brew install jq
        else
            print_error "Please install jq manually"
            exit 1
        fi
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Please run 'aws configure'."
        exit 1
    fi
    
    print_status "✅ All prerequisites met"
}

# Create ECR repository and push image
setup_ecr() {
    print_status "🐳 Setting up ECR repository..."
    
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    ECR_URI="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/ecommerce-backend"
    
    # Create ECR repository
    aws ecr create-repository \
        --repository-name ecommerce-backend \
        --region $REGION \
        --image-scanning-configuration scanOnPush=true || true
    
    # Get login token
    aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com
    
    # Build and push image
    print_status "🔨 Building and pushing Docker image..."
    cd ../../../backend
    
    docker build -t ecommerce-backend .
    docker tag ecommerce-backend:latest $ECR_URI:latest
    docker push $ECR_URI:latest
    
    cd ../aws-deploy/ecs-fargate
    
    print_status "✅ ECR setup complete. Image URI: $ECR_URI:latest"
}

# Deploy infrastructure using CloudFormation
deploy_infrastructure() {
    print_status "🏗️ Deploying infrastructure with CloudFormation..."
    
    # Generate a secure password
    DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    
    # Deploy CloudFormation stack
    aws cloudformation deploy \
        --template-file infrastructure.yaml \
        --stack-name $STACK_NAME \
        --parameter-overrides DatabasePassword=$DB_PASSWORD \
        --capabilities CAPABILITY_NAMED_IAM \
        --region $REGION
    
    # Get outputs
    VPC_ID=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query 'Stacks[0].Outputs[?OutputKey==`VPC`].OutputValue' --output text)
    PRIVATE_SUBNETS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query 'Stacks[0].Outputs[?OutputKey==`PrivateSubnets`].OutputValue' --output text)
    ECS_SECURITY_GROUP=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query 'Stacks[0].Outputs[?OutputKey==`ECSSecurityGroup`].OutputValue' --output text)
    TARGET_GROUP_ARN=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query 'Stacks[0].Outputs[?OutputKey==`ALBTargetGroup`].OutputValue' --output text)
    RDS_ENDPOINT=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query 'Stacks[0].Outputs[?OutputKey==`RDSEndpoint`].OutputValue' --output text)
    REDIS_ENDPOINT=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query 'Stacks[0].Outputs[?OutputKey==`RedisEndpoint`].OutputValue' --output text)
    
    print_status "✅ Infrastructure deployed successfully"
    print_status "📊 VPC ID: $VPC_ID"
    print_status "📊 RDS Endpoint: $RDS_ENDPOINT"
    print_status "📊 Redis Endpoint: $REDIS_ENDPOINT"
    
    # Store database password in Secrets Manager
    print_status "🔐 Storing secrets in AWS Secrets Manager..."
    
    # Create secrets
    aws secretsmanager create-secret \
        --name "ecommerce/database" \
        --description "Database credentials for ecommerce application" \
        --secret-string "{\"host\":\"$RDS_ENDPOINT\",\"password\":\"$DB_PASSWORD\"}" \
        --region $REGION || \
    aws secretsmanager update-secret \
        --secret-id "ecommerce/database" \
        --secret-string "{\"host\":\"$RDS_ENDPOINT\",\"password\":\"$DB_PASSWORD\"}" \
        --region $REGION
    
    aws secretsmanager create-secret \
        --name "ecommerce/redis" \
        --description "Redis credentials for ecommerce application" \
        --secret-string "{\"host\":\"$REDIS_ENDPOINT\"}" \
        --region $REGION || \
    aws secretsmanager update-secret \
        --secret-id "ecommerce/redis" \
        --secret-string "{\"host\":\"$REDIS_ENDPOINT\"}" \
        --region $REGION
    
    aws secretsmanager create-secret \
        --name "ecommerce/app" \
        --description "Application secrets for ecommerce application" \
        --secret-string "{\"secret_key\":\"$(openssl rand -base64 32)\"}" \
        --region $REGION || \
    aws secretsmanager update-secret \
        --secret-id "ecommerce/app" \
        --secret-string "{\"secret_key\":\"$(openssl rand -base64 32)\"}" \
        --region $REGION
}

# Register ECS task definition
register_task_definition() {
    print_status "📋 Registering ECS task definition..."
    
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    
    # Update task definition with actual values
    sed -e "s/YOUR-ACCOUNT/$ACCOUNT_ID/g" \
        -e "s/us-east-1/$REGION/g" \
        task-definition.json > task-definition-updated.json
    
    # Register task definition
    aws ecs register-task-definition \
        --cli-input-json file://task-definition-updated.json \
        --region $REGION
    
    print_status "✅ Task definition registered"
}

# Create and start ECS service
create_ecs_service() {
    print_status "🚀 Creating ECS service..."
    
    # Get infrastructure outputs
    PRIVATE_SUBNETS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query 'Stacks[0].Outputs[?OutputKey==`PrivateSubnets`].OutputValue' --output text)
    ECS_SECURITY_GROUP=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query 'Stacks[0].Outputs[?OutputKey==`ECSSecurityGroup`].OutputValue' --output text)
    TARGET_GROUP_ARN=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query 'Stacks[0].Outputs[?OutputKey==`ALBTargetGroup`].OutputValue' --output text)
    
    # Convert comma-separated subnets to array format
    SUBNET_ARRAY=$(echo $PRIVATE_SUBNETS | sed 's/,/","/g' | sed 's/^/"/' | sed 's/$/"/')
    
    # Create service
    aws ecs create-service \
        --cluster $CLUSTER_NAME \
        --service-name $SERVICE_NAME \
        --task-definition $TASK_FAMILY \
        --desired-count 3 \
        --launch-type FARGATE \
        --platform-version LATEST \
        --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_ARRAY],securityGroups=[$ECS_SECURITY_GROUP],assignPublicIp=DISABLED}" \
        --load-balancers "targetGroupArn=$TARGET_GROUP_ARN,containerName=ecommerce-backend,containerPort=5000" \
        --health-check-grace-period-seconds 300 \
        --region $REGION || \
    aws ecs update-service \
        --cluster $CLUSTER_NAME \
        --service $SERVICE_NAME \
        --desired-count 3 \
        --task-definition $TASK_FAMILY \
        --region $REGION
    
    print_status "✅ ECS service created/updated"
}

# Setup auto scaling
setup_auto_scaling() {
    print_status "📈 Setting up auto scaling..."
    
    # Register scalable target
    aws application-autoscaling register-scalable-target \
        --service-namespace ecs \
        --resource-id service/$CLUSTER_NAME/$SERVICE_NAME \
        --scalable-dimension ecs:service:DesiredCount \
        --min-capacity 2 \
        --max-capacity 10 \
        --region $REGION || true
    
    # Create scaling policy
    aws application-autoscaling put-scaling-policy \
        --service-namespace ecs \
        --resource-id service/$CLUSTER_NAME/$SERVICE_NAME \
        --scalable-dimension ecs:service:DesiredCount \
        --policy-name ecommerce-cpu-scaling \
        --policy-type TargetTrackingScaling \
        --target-tracking-scaling-policy-configuration "TargetValue=70.0,PredefinedMetricSpecification={PredefinedMetricType=ECSServiceAverageCPUUtilization}" \
        --region $REGION || true
    
    print_status "✅ Auto scaling configured"
}

# Wait for service to stabilize
wait_for_service() {
    print_status "⏳ Waiting for service to stabilize..."
    
    aws ecs wait services-stable \
        --cluster $CLUSTER_NAME \
        --services $SERVICE_NAME \
        --region $REGION
    
    print_status "✅ Service is stable"
}

# Verify deployment
verify_deployment() {
    print_status "🔍 Verifying deployment..."
    
    # Get service status
    SERVICE_STATUS=$(aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --region $REGION --query 'services[0].status' --output text)
    RUNNING_COUNT=$(aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --region $REGION --query 'services[0].runningCount' --output text)
    DESIRED_COUNT=$(aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --region $REGION --query 'services[0].desiredCount' --output text)
    
    print_status "📊 Service Status: $SERVICE_STATUS"
    print_status "📊 Running Tasks: $RUNNING_COUNT/$DESIRED_COUNT"
    
    # Get load balancer URL
    LB_URL=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerURL`].OutputValue' --output text)
    
    if [ ! -z "$LB_URL" ]; then
        print_status "🌐 Application URL: $LB_URL"
        print_status "⏳ Testing application health..."
        
        # Wait a bit for load balancer to be ready
        sleep 30
        
        # Test health endpoint
        if curl -f "$LB_URL/health" &> /dev/null; then
            print_status "✅ Application is healthy!"
        else
            print_warning "⚠️ Application health check failed. It may still be starting up."
        fi
    else
        print_warning "Load balancer URL not available"
    fi
    
    print_status "✅ Deployment verification complete"
}

# Main execution
main() {
    print_status "🚀 Starting ECS Fargate deployment for E-commerce Application"
    
    check_prerequisites
    setup_ecr
    deploy_infrastructure
    register_task_definition
    create_ecs_service
    setup_auto_scaling
    wait_for_service
    verify_deployment
    
    print_status "🎉 ECS Fargate deployment completed successfully!"
    print_status "📋 Next steps:"
    print_status "  1. Configure your domain name to point to the load balancer"
    print_status "  2. Set up SSL certificate in AWS Certificate Manager"
    print_status "  3. Update the load balancer listener to use HTTPS"
    print_status "  4. Set up monitoring and alerting"
    print_status "  5. Configure backup strategies for RDS and application data"
}

# Cleanup function
cleanup() {
    print_status "🧹 Cleaning up resources..."
    
    # Delete ECS service
    aws ecs update-service \
        --cluster $CLUSTER_NAME \
        --service $SERVICE_NAME \
        --desired-count 0 \
        --region $REGION || true
    
    aws ecs delete-service \
        --cluster $CLUSTER_NAME \
        --service $SERVICE_NAME \
        --region $REGION || true
    
    # Delete CloudFormation stack
    aws cloudformation delete-stack \
        --stack-name $STACK_NAME \
        --region $REGION || true
    
    print_status "✅ Cleanup initiated"
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-deploy}" in
        deploy)
            main "$@"
            ;;
        cleanup)
            cleanup
            ;;
        *)
            echo "Usage: $0 [deploy|cleanup]"
            exit 1
            ;;
    esac
fi
