# Amazon ECS Fargate Deployment

This directory contains scripts and configurations for deploying the e-commerce application on Amazon ECS with Fargate.

## 📁 Files

- `infrastructure.yaml` - CloudFormation template for AWS infrastructure
- `task-definition.json` - ECS task definition for the application
- `deploy-ecs.sh` - Automated deployment script
- `README.md` - This file

## 🚀 Quick Deploy

```bash
# Make the script executable
chmod +x deploy-ecs.sh

# Run the deployment
./deploy-ecs.sh

# To cleanup resources
./deploy-ecs.sh cleanup
```

## 📋 Prerequisites

Before running the deployment, ensure you have:

1. **AWS CLI** configured with appropriate permissions
2. **Docker** installed
3. **jq** installed for JSON processing
4. Sufficient AWS permissions for:
   - ECS cluster and service management
   - CloudFormation stack operations
   - ECR repository operations
   - RDS and ElastiCache management
   - Secrets Manager access
   - IAM role creation

### Required AWS Permissions

Your AWS user/role should have the following managed policies:
- `AmazonECS_FullAccess`
- `AmazonEC2ContainerRegistryFullAccess`
- `CloudFormationFullAccess`
- `AmazonRDSFullAccess`
- `AmazonElastiCacheFullAccess`
- `SecretsManagerReadWrite`
- `IAMFullAccess`

## ⚙️ Configuration

### 1. Update task-definition.json

Replace the following placeholders:
- `YOUR-ACCOUNT` - Your AWS account ID
- `us-east-1` - Your preferred AWS region

### 2. Customize infrastructure.yaml

You can modify the CloudFormation template to:
- Change instance types
- Adjust security group rules
- Modify database configurations
- Update networking settings

## 🏗️ What Gets Deployed

The deployment creates:

### Networking
- VPC with public and private subnets
- Internet Gateway and NAT Gateway
- Route tables and security groups
- Application Load Balancer

### Compute
- ECS Fargate cluster
- ECS service with auto-scaling
- Application Load Balancer target group

### Storage
- RDS PostgreSQL database (encrypted)
- ElastiCache Redis cluster (encrypted)

### Security
- IAM roles for ECS tasks
- Secrets Manager for sensitive data
- Security groups with least privilege

### Monitoring
- CloudWatch log groups
- Container insights enabled

## 🔧 Manual Deployment Steps

If you prefer to deploy manually:

### Step 1: Create ECR Repository

```bash
# Create repository
aws ecr create-repository --repository-name ecommerce-backend --region us-east-1

# Get login token
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR-ACCOUNT.dkr.ecr.us-east-1.amazonaws.com

# Build and push image
cd ../../../backend
docker build -t ecommerce-backend .
docker tag ecommerce-backend:latest YOUR-ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/ecommerce-backend:latest
docker push YOUR-ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/ecommerce-backend:latest
```

### Step 2: Deploy Infrastructure

```bash
# Deploy CloudFormation stack
aws cloudformation deploy \
  --template-file infrastructure.yaml \
  --stack-name ecommerce-infrastructure \
  --parameter-overrides DatabasePassword=YourSecurePassword123! \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

### Step 3: Create Secrets

```bash
# Get infrastructure outputs
RDS_ENDPOINT=$(aws cloudformation describe-stacks --stack-name ecommerce-infrastructure --query 'Stacks[0].Outputs[?OutputKey==`RDSEndpoint`].OutputValue' --output text)
REDIS_ENDPOINT=$(aws cloudformation describe-stacks --stack-name ecommerce-infrastructure --query 'Stacks[0].Outputs[?OutputKey==`RedisEndpoint`].OutputValue' --output text)

# Create secrets
aws secretsmanager create-secret \
  --name "ecommerce/database" \
  --secret-string "{\"host\":\"$RDS_ENDPOINT\",\"password\":\"YourSecurePassword123!\"}"

aws secretsmanager create-secret \
  --name "ecommerce/redis" \
  --secret-string "{\"host\":\"$REDIS_ENDPOINT\"}"

aws secretsmanager create-secret \
  --name "ecommerce/app" \
  --secret-string "{\"secret_key\":\"$(openssl rand -base64 32)\"}"
```

### Step 4: Register Task Definition

```bash
# Update task definition with your account ID
sed 's/YOUR-ACCOUNT/123456789012/g' task-definition.json > task-definition-updated.json

# Register task definition
aws ecs register-task-definition --cli-input-json file://task-definition-updated.json
```

### Step 5: Create ECS Service

```bash
# Get infrastructure details
PRIVATE_SUBNETS=$(aws cloudformation describe-stacks --stack-name ecommerce-infrastructure --query 'Stacks[0].Outputs[?OutputKey==`PrivateSubnets`].OutputValue' --output text)
ECS_SECURITY_GROUP=$(aws cloudformation describe-stacks --stack-name ecommerce-infrastructure --query 'Stacks[0].Outputs[?OutputKey==`ECSSecurityGroup`].OutputValue' --output text)
TARGET_GROUP_ARN=$(aws cloudformation describe-stacks --stack-name ecommerce-infrastructure --query 'Stacks[0].Outputs[?OutputKey==`ALBTargetGroup`].OutputValue' --output text)

# Create service
aws ecs create-service \
  --cluster ecommerce-cluster \
  --service-name ecommerce-backend \
  --task-definition ecommerce-backend \
  --desired-count 3 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$PRIVATE_SUBNETS],securityGroups=[$ECS_SECURITY_GROUP]}" \
  --load-balancers "targetGroupArn=$TARGET_GROUP_ARN,containerName=ecommerce-backend,containerPort=5000"
```

## 🔍 Monitoring and Troubleshooting

### Check Service Status

```bash
# Check service
aws ecs describe-services --cluster ecommerce-cluster --services ecommerce-backend

# Check tasks
aws ecs list-tasks --cluster ecommerce-cluster --service-name ecommerce-backend

# View logs
aws logs tail /ecs/ecommerce-backend --follow
```

### Check Load Balancer

```bash
# Get load balancer URL
aws cloudformation describe-stacks --stack-name ecommerce-infrastructure --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerURL`].OutputValue' --output text

# Test health endpoint
curl http://YOUR-ALB-URL/health
```

### Database Connection

```bash
# Get RDS endpoint
aws cloudformation describe-stacks --stack-name ecommerce-infrastructure --query 'Stacks[0].Outputs[?OutputKey==`RDSEndpoint`].OutputValue' --output text

# Connect to database (if needed)
psql -h YOUR-RDS-ENDPOINT -U ecommerce_user -d ecommerce
```

## 📈 Scaling

### Manual Scaling

```bash
# Scale service
aws ecs update-service \
  --cluster ecommerce-cluster \
  --service ecommerce-backend \
  --desired-count 5
```

### Auto Scaling

Auto scaling is configured automatically with:
- Target CPU utilization: 70%
- Min capacity: 2 tasks
- Max capacity: 10 tasks

## 🔒 Security Features

### Network Security
- Private subnets for application and database
- Security groups with minimal required access
- NAT Gateway for outbound internet access

### Data Security
- RDS encryption at rest
- Redis encryption in transit and at rest
- Secrets stored in AWS Secrets Manager

### Access Control
- IAM roles with least privilege
- Task-specific permissions
- No hardcoded credentials

## 💰 Cost Optimization

### Fargate Pricing
- Uses Fargate Spot capacity when available
- Right-sized CPU and memory allocations
- Auto scaling to match demand

### Database Optimization
- db.t3.micro for development/testing
- gp3 storage for cost efficiency
- Automated backups with 7-day retention

### Networking
- Single NAT Gateway to reduce costs
- Efficient security group rules

## 🧹 Cleanup

To remove all resources:

```bash
./deploy-ecs.sh cleanup
```

Or manually:

```bash
# Delete ECS service
aws ecs update-service --cluster ecommerce-cluster --service ecommerce-backend --desired-count 0
aws ecs delete-service --cluster ecommerce-cluster --service ecommerce-backend

# Delete CloudFormation stack
aws cloudformation delete-stack --stack-name ecommerce-infrastructure
```

## 📖 Additional Resources

- [Amazon ECS Developer Guide](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/)
- [AWS Fargate User Guide](https://docs.aws.amazon.com/AmazonECS/latest/userguide/what-is-fargate.html)
- [Application Load Balancer Documentation](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/)
- [AWS Secrets Manager User Guide](https://docs.aws.amazon.com/secretsmanager/latest/userguide/)
