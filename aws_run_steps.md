# 🚀 AWS Deployment Guide - E-Commerce Application

This guide provides comprehensive step-by-step instructions for deploying the e-commerce application on various AWS services. The deployment scripts and configurations are organized in the `aws-deploy/` directory for easy access and management.

## �️ Deployment Structure

```
aws-deploy/
├── elastic-beanstalk/          # AWS Elastic Beanstalk deployment
├── eks/                        # Amazon EKS deployment  
├── ecs-fargate/                # Amazon ECS with Fargate deployment
├── cloudformation/             # Infrastructure as Code templates
├── scripts/                    # Utility scripts for AWS setup
└── monitoring/                 # Monitoring and logging configurations
```

## 🚀 Quick Start Options

### Option 1: One-Click Deployments
- **Elastic Beanstalk**: `cd aws-deploy/elastic-beanstalk && ./deploy-eb.sh`
- **Amazon EKS**: `cd aws-deploy/eks && ./deploy-eks.sh`
- **Amazon ECS Fargate**: `cd aws-deploy/ecs-fargate && ./deploy-ecs.sh`

### Option 2: Setup and Deploy
1. **Setup AWS CLI**: `cd aws-deploy/scripts && ./setup-aws-cli.sh`
2. **Create ECR Repositories**: `./create-ecr-repo.sh`
3. **Build and Push Images**: `./build-and-push.sh`
4. **Choose your deployment method** from the options below

## �📋 Table of Contents

1. [Prerequisites and Setup](#prerequisites-and-setup)
2. [AWS Elastic Beanstalk Deployment](#aws-elastic-beanstalk-deployment)
3. [Amazon EKS Deployment](#amazon-eks-deployment)
4. [Amazon ECS Fargate Deployment](#amazon-ecs-fargate-deployment)
5. [Individual AWS Services Deployment](#individual-aws-services-deployment)
6. [Monitoring and Cost Optimization](#monitoring-and-cost-optimization)
7. [Troubleshooting](#troubleshooting)

---

## 📋 Prerequisites and Setup

### Required Tools
- **AWS CLI** v2.x - [Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- **Docker** - [Installation Guide](https://docs.docker.com/get-docker/)
- **kubectl** (for EKS) - [Installation Guide](https://kubernetes.io/docs/tasks/tools/)
- **eksctl** (for EKS) - [Installation Guide](https://eksctl.io/introduction/#installation)
- **Helm** v3.x (for EKS) - [Installation Guide](https://helm.sh/docs/intro/install/)

### AWS Permissions Required
Your AWS user needs the following managed policies:
- `PowerUserAccess` (recommended) OR specific policies:
  - `AmazonECS_FullAccess`
  - `AmazonEKSClusterPolicy`
  - `AmazonElasticBeanstalkFullAccess`
  - `CloudFormationFullAccess`
  - `AmazonRDSFullAccess`
  - `AmazonElastiCacheFullAccess`
  - `AmazonEC2ContainerRegistryFullAccess`
  - `SecretsManagerReadWrite`
  - `IAMFullAccess`

### Automated Setup
Run the setup script to configure AWS CLI and check permissions:

```bash
cd aws-deploy/scripts
chmod +x setup-aws-cli.sh
./setup-aws-cli.sh
```

---

## 🌐 AWS Elastic Beanstalk Deployment

### Prerequisites:
- AWS CLI installed and configured
- EB CLI installed (`pip install awsebcli`)
- Docker installed locally

### Step 1: Prepare Application for Elastic Beanstalk

```bash
# 1. Create Elastic Beanstalk application directory
mkdir aws-ebs-deploy
cd aws-ebs-deploy

# 2. Copy backend application
cp -r ../backend/* .

# 3. Create Dockerrun.aws.json for multi-container deployment
cat > Dockerrun.aws.json << 'EOF'
{
  "AWSEBDockerrunVersion": 2,
  "containerDefinitions": [
    {
      "name": "backend",
      "image": "ecommerce-backend:latest",
      "essential": true,
      "memory": 512,
      "portMappings": [
        {
          "hostPort": 80,
          "containerPort": 5000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "DATABASE_HOST",
          "value": "your-rds-endpoint.region.rds.amazonaws.com"
        },
        {
          "name": "REDIS_HOST",
          "value": "your-elasticache-endpoint.cache.amazonaws.com"
        }
      ],
      "links": [],
      "mountPoints": [],
      "volumesFrom": []
    }
  ]
}
EOF

# 4. Create .ebextensions directory for configuration
mkdir .ebextensions

# 5. Create environment configuration
cat > .ebextensions/01-environment.config << 'EOF'
option_settings:
  aws:elasticbeanstalk:application:environment:
    FLASK_ENV: production
    DATABASE_URL: postgresql://username:password@your-rds-endpoint:5432/ecommerce
    REDIS_URL: redis://your-elasticache-endpoint:6379/0
  aws:autoscaling:launchconfiguration:
    InstanceType: t3.medium
    SecurityGroups: your-security-group-id
  aws:autoscaling:asg:
    MinSize: 2
    MaxSize: 10
  aws:elasticbeanstalk:environment:
    LoadBalancerType: application
EOF
```

### Step 2: Initialize and Deploy to Elastic Beanstalk

```bash
# 1. Initialize EB application
eb init ecommerce-app --platform docker --region us-east-1

# 2. Create environment
eb create production --instance-type t3.medium --min-instances 2 --max-instances 10

# 3. Set environment variables
eb setenv \
  FLASK_ENV=production \
  SECRET_KEY=your-production-secret-key \
  DATABASE_HOST=your-rds-endpoint.region.rds.amazonaws.com \
  DATABASE_NAME=ecommerce \
  DATABASE_USER=ecommerce_user \
  DATABASE_PASSWORD=your-secure-password \
  REDIS_HOST=your-elasticache-endpoint.cache.amazonaws.com

# 4. Deploy application
eb deploy

# 5. Open application in browser
eb open
```

### Step 3: Configure Auto Scaling

```bash
# Create auto scaling configuration
cat > .ebextensions/02-autoscaling.config << 'EOF'
option_settings:
  aws:autoscaling:asg:
    MinSize: 2
    MaxSize: 10
  aws:autoscaling:trigger:
    MeasureName: CPUUtilization
    Unit: Percent
    UpperThreshold: 80
    LowerThreshold: 20
    ScaleUpIncrement: 2
    ScaleDownIncrement: -1
EOF

# Redeploy with new configuration
eb deploy
```

---

## ☸️ Amazon EKS Deployment

### Prerequisites:
- AWS CLI configured
- kubectl installed
- eksctl installed
- Helm 3.x installed

### Step 1: Create EKS Cluster

```bash
# 1. Create cluster configuration
cat > eks-cluster.yaml << 'EOF'
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: ecommerce-cluster
  region: us-east-1
  version: "1.24"

nodeGroups:
  - name: worker-nodes
    instanceType: t3.medium
    desiredCapacity: 3
    minSize: 2
    maxSize: 10
    availabilityZones: ["us-east-1a", "us-east-1b", "us-east-1c"]
    ssh:
      allow: true
    iam:
      withAddonPolicies:
        imageBuilder: true
        autoScaler: true
        certManager: true
        efs: true
        ebs: true
        albIngress: true
        cloudWatch: true

addons:
  - name: vpc-cni
  - name: coredns
  - name: kube-proxy
  - name: aws-ebs-csi-driver

iam:
  withOIDC: true
EOF

# 2. Create the cluster
eksctl create cluster -f eks-cluster.yaml

# 3. Verify cluster
kubectl get nodes
```

### Step 2: Install Required Add-ons

```bash
# 1. Install AWS Load Balancer Controller
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.4/docs/install/iam_policy.json

aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

# Create service account
eksctl create iamserviceaccount \
  --cluster=ecommerce-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name "AmazonEKSLoadBalancerControllerRole" \
  --attach-policy-arn=arn:aws:iam::ACCOUNT-ID:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve

# Install load balancer controller
helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=ecommerce-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

# 2. Install metrics server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# 3. Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
```

### Step 3: Deploy Application to EKS

```bash
# 1. Create namespace
kubectl create namespace ecommerce-prod

# 2. Create AWS-specific values file
cat > values-aws-prod.yaml << 'EOF'
environment: production
replicaCount: 3

image:
  backend:
    repository: YOUR-ECR-REPO/ecommerce-backend
    tag: latest
    pullPolicy: Always

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: true
  className: "alb"
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-1:ACCOUNT:certificate/CERT-ID
    alb.ingress.kubernetes.io/ssl-redirect: '443'
  hosts:
    - host: ecommerce.yourdomain.com
      paths:
        - path: /
          pathType: Prefix

postgresql:
  enabled: false  # Using RDS
  external:
    host: your-rds-endpoint.region.rds.amazonaws.com
    port: 5432
    database: ecommerce
    username: ecommerce_user
    password: your-secure-password

redis:
  enabled: false  # Using ElastiCache
  external:
    host: your-elasticache-endpoint.cache.amazonaws.com
    port: 6379
    password: your-redis-password

persistence:
  enabled: true
  storageClass: gp3

resources:
  requests:
    memory: "512Mi"
    cpu: "250m"
  limits:
    memory: "1Gi"
    cpu: "500m"

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 20
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80
EOF

# 3. Deploy using Helm
helm upgrade --install ecommerce-prod ../k8s/helm/ecommerce \
  --namespace ecommerce-prod \
  --values values-aws-prod.yaml \
  --timeout 10m \
  --wait

# 4. Verify deployment
kubectl get pods -n ecommerce-prod
kubectl get services -n ecommerce-prod
kubectl get ingress -n ecommerce-prod
```

### Step 4: Configure Horizontal Pod Autoscaler

```bash
# Create HPA for backend
kubectl apply -f - << 'EOF'
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: ecommerce-backend-hpa
  namespace: ecommerce-prod
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: ecommerce-prod-backend
  minReplicas: 3
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
EOF
```

---

## � Amazon ECS Fargate Deployment

Amazon ECS with Fargate provides a serverless container platform that eliminates the need to manage EC2 instances. This deployment option is ideal for teams who want container orchestration without the complexity of managing the underlying infrastructure.

### Prerequisites:
- AWS CLI configured
- Docker installed
- jq installed (`sudo apt-get install jq` or `brew install jq`)

### Quick Deploy

```bash
# Navigate to ECS Fargate deployment directory
cd aws-deploy/ecs-fargate

# Make deployment script executable
chmod +x deploy-ecs.sh

# Run automated deployment
./deploy-ecs.sh

# To cleanup all resources
./deploy-ecs.sh cleanup
```

### What Gets Deployed

The ECS Fargate deployment creates:

#### Infrastructure
- **VPC with public/private subnets** across multiple AZs
- **Application Load Balancer** for traffic distribution
- **Security Groups** with least privilege access
- **NAT Gateways** for outbound connectivity

#### Compute
- **ECS Fargate cluster** with auto-scaling
- **ECS service** running the containerized application
- **Application Load Balancer target groups**

#### Storage
- **RDS PostgreSQL** with encryption and automated backups
- **ElastiCache Redis** for caching and sessions

#### Security
- **AWS Secrets Manager** for sensitive configuration
- **IAM roles** with minimal required permissions
- **VPC security groups** restricting network access

### Manual Deployment Steps

If you prefer manual control over the deployment:

#### Step 1: Create ECR Repository and Push Images

```bash
# Create ECR repository
aws ecr create-repository --repository-name ecommerce-backend --region us-east-1

# Get login credentials
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR-ACCOUNT.dkr.ecr.us-east-1.amazonaws.com

# Build and push backend image
cd ../../../backend
docker build -t ecommerce-backend .
docker tag ecommerce-backend:latest YOUR-ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/ecommerce-backend:latest
docker push YOUR-ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/ecommerce-backend:latest
cd ../aws-deploy/ecs-fargate
```

#### Step 2: Deploy Infrastructure with CloudFormation

```bash
# Deploy the infrastructure stack
aws cloudformation deploy \
  --template-file infrastructure.yaml \
  --stack-name ecommerce-infrastructure \
  --parameter-overrides DatabasePassword=YourSecurePassword123! \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

#### Step 3: Create Application Secrets

```bash
# Get infrastructure outputs
RDS_ENDPOINT=$(aws cloudformation describe-stacks --stack-name ecommerce-infrastructure --query 'Stacks[0].Outputs[?OutputKey==`RDSEndpoint`].OutputValue' --output text)
REDIS_ENDPOINT=$(aws cloudformation describe-stacks --stack-name ecommerce-infrastructure --query 'Stacks[0].Outputs[?OutputKey==`RedisEndpoint`].OutputValue' --output text)

# Store secrets in AWS Secrets Manager
aws secretsmanager create-secret \
  --name "ecommerce/database" \
  --description "Database credentials for ecommerce application" \
  --secret-string "{\"host\":\"$RDS_ENDPOINT\",\"password\":\"YourSecurePassword123!\"}"

aws secretsmanager create-secret \
  --name "ecommerce/redis" \
  --description "Redis configuration for ecommerce application" \
  --secret-string "{\"host\":\"$REDIS_ENDPOINT\"}"

aws secretsmanager create-secret \
  --name "ecommerce/app" \
  --description "Application secrets for ecommerce application" \
  --secret-string "{\"secret_key\":\"$(openssl rand -base64 32)\"}"
```

#### Step 4: Register ECS Task Definition

```bash
# Update task definition with your account ID
sed 's/YOUR-ACCOUNT/123456789012/g' task-definition.json > task-definition-updated.json

# Register the task definition
aws ecs register-task-definition --cli-input-json file://task-definition-updated.json
```

#### Step 5: Create ECS Service

```bash
# Get required infrastructure details
PRIVATE_SUBNETS=$(aws cloudformation describe-stacks --stack-name ecommerce-infrastructure --query 'Stacks[0].Outputs[?OutputKey==`PrivateSubnets`].OutputValue' --output text)
ECS_SECURITY_GROUP=$(aws cloudformation describe-stacks --stack-name ecommerce-infrastructure --query 'Stacks[0].Outputs[?OutputKey==`ECSSecurityGroup`].OutputValue' --output text)
TARGET_GROUP_ARN=$(aws cloudformation describe-stacks --stack-name ecommerce-infrastructure --query 'Stacks[0].Outputs[?OutputKey==`ALBTargetGroup`].OutputValue' --output text)

# Create the ECS service
aws ecs create-service \
  --cluster ecommerce-cluster \
  --service-name ecommerce-backend \
  --task-definition ecommerce-backend \
  --desired-count 3 \
  --launch-type FARGATE \
  --platform-version LATEST \
  --network-configuration "awsvpcConfiguration={subnets=[$PRIVATE_SUBNETS],securityGroups=[$ECS_SECURITY_GROUP],assignPublicIp=DISABLED}" \
  --load-balancers "targetGroupArn=$TARGET_GROUP_ARN,containerName=ecommerce-backend,containerPort=5000" \
  --health-check-grace-period-seconds 300
```

### Monitoring and Scaling

#### Auto Scaling Configuration

The deployment includes automatic scaling based on CPU utilization:

```bash
# Register scalable target
aws application-autoscaling register-scalable-target \
  --service-namespace ecs \
  --resource-id service/ecommerce-cluster/ecommerce-backend \
  --scalable-dimension ecs:service:DesiredCount \
  --min-capacity 2 \
  --max-capacity 10

# Create auto scaling policy
aws application-autoscaling put-scaling-policy \
  --service-namespace ecs \
  --resource-id service/ecommerce-cluster/ecommerce-backend \
  --scalable-dimension ecs:service:DesiredCount \
  --policy-name ecommerce-cpu-scaling \
  --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration "TargetValue=70.0,PredefinedMetricSpecification={PredefinedMetricType=ECSServiceAverageCPUUtilization}"
```

#### Monitoring Commands

```bash
# Check service status
aws ecs describe-services --cluster ecommerce-cluster --services ecommerce-backend

# View service logs
aws logs tail /ecs/ecommerce-backend --follow

# Check load balancer health
aws elbv2 describe-target-health --target-group-arn $TARGET_GROUP_ARN
```

### Cost Optimization Features

- **Fargate Spot Integration**: Uses spot capacity for cost savings
- **Auto Scaling**: Scales down during low traffic periods
- **Right-Sized Resources**: Optimized CPU and memory allocation
- **Efficient Storage**: Uses gp3 storage for RDS and optimized instance types

---

## �🔧 Individual AWS Services Deployment

### Step 1: Create VPC and Security Groups

```bash
# 1. Create VPC
aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=ecommerce-vpc}]'

# Get VPC ID
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=ecommerce-vpc" --query 'Vpcs[0].VpcId' --output text)

# 2. Create Internet Gateway
aws ec2 create-internet-gateway \
  --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=ecommerce-igw}]'

IGW_ID=$(aws ec2 describe-internet-gateways --filters "Name=tag:Name,Values=ecommerce-igw" --query 'InternetGateways[0].InternetGatewayId' --output text)

# Attach IGW to VPC
aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID

# 3. Create Public Subnets
aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.1.0/24 \
  --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=ecommerce-public-1a}]'

aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.2.0/24 \
  --availability-zone us-east-1b \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=ecommerce-public-1b}]'

# 4. Create Private Subnets
aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.3.0/24 \
  --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=ecommerce-private-1a}]'

aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.4.0/24 \
  --availability-zone us-east-1b \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=ecommerce-private-1b}]'

# 5. Create Security Groups
# ALB Security Group
aws ec2 create-security-group \
  --group-name ecommerce-alb-sg \
  --description "Security group for ALB" \
  --vpc-id $VPC_ID

ALB_SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=ecommerce-alb-sg" --query 'SecurityGroups[0].GroupId' --output text)

# Allow HTTP and HTTPS
aws ec2 authorize-security-group-ingress \
  --group-id $ALB_SG_ID \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
  --group-id $ALB_SG_ID \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0

# ECS Security Group
aws ec2 create-security-group \
  --group-name ecommerce-ecs-sg \
  --description "Security group for ECS tasks" \
  --vpc-id $VPC_ID

ECS_SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=ecommerce-ecs-sg" --query 'SecurityGroups[0].GroupId' --output text)

# Allow traffic from ALB
aws ec2 authorize-security-group-ingress \
  --group-id $ECS_SG_ID \
  --protocol tcp \
  --port 5000 \
  --source-group $ALB_SG_ID

# RDS Security Group
aws ec2 create-security-group \
  --group-name ecommerce-rds-sg \
  --description "Security group for RDS" \
  --vpc-id $VPC_ID

RDS_SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=ecommerce-rds-sg" --query 'SecurityGroups[0].GroupId' --output text)

# Allow database access from ECS
aws ec2 authorize-security-group-ingress \
  --group-id $RDS_SG_ID \
  --protocol tcp \
  --port 5432 \
  --source-group $ECS_SG_ID
```

### Step 2: Setup Amazon RDS (PostgreSQL)

```bash
# 1. Create DB Subnet Group
aws rds create-db-subnet-group \
  --db-subnet-group-name ecommerce-db-subnet-group \
  --db-subnet-group-description "Subnet group for ecommerce database" \
  --subnet-ids subnet-xxx subnet-yyy

# 2. Create RDS Instance
aws rds create-db-instance \
  --db-instance-identifier ecommerce-db \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version 15.4 \
  --master-username ecommerce_user \
  --master-user-password YourSecurePassword123! \
  --allocated-storage 20 \
  --storage-type gp3 \
  --vpc-security-group-ids $RDS_SG_ID \
  --db-subnet-group-name ecommerce-db-subnet-group \
  --db-name ecommerce \
  --backup-retention-period 7 \
  --storage-encrypted \
  --multi-az \
  --publicly-accessible false \
  --tags Key=Name,Value=ecommerce-database

# 3. Wait for RDS to be available
aws rds wait db-instance-available --db-instance-identifier ecommerce-db

# 4. Get RDS endpoint
RDS_ENDPOINT=$(aws rds describe-db-instances --db-instance-identifier ecommerce-db --query 'DBInstances[0].Endpoint.Address' --output text)
echo "RDS Endpoint: $RDS_ENDPOINT"
```

### Step 3: Setup Amazon ElastiCache (Redis)

```bash
# 1. Create ElastiCache Subnet Group
aws elasticache create-cache-subnet-group \
  --cache-subnet-group-name ecommerce-cache-subnet-group \
  --cache-subnet-group-description "Subnet group for ecommerce cache" \
  --subnet-ids subnet-xxx subnet-yyy

# 2. Create ElastiCache Security Group
aws ec2 create-security-group \
  --group-name ecommerce-cache-sg \
  --description "Security group for ElastiCache" \
  --vpc-id $VPC_ID

CACHE_SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=ecommerce-cache-sg" --query 'SecurityGroups[0].GroupId' --output text)

# Allow Redis access from ECS
aws ec2 authorize-security-group-ingress \
  --group-id $CACHE_SG_ID \
  --protocol tcp \
  --port 6379 \
  --source-group $ECS_SG_ID

# 3. Create ElastiCache Cluster
aws elasticache create-cache-cluster \
  --cache-cluster-id ecommerce-redis \
  --engine redis \
  --cache-node-type cache.t3.micro \
  --num-cache-nodes 1 \
  --cache-subnet-group-name ecommerce-cache-subnet-group \
  --security-group-ids $CACHE_SG_ID \
  --engine-version 7.0 \
  --tags Key=Name,Value=ecommerce-cache

# 4. Get Redis endpoint
REDIS_ENDPOINT=$(aws elasticache describe-cache-clusters --cache-cluster-id ecommerce-redis --show-cache-node-info --query 'CacheClusters[0].CacheNodes[0].Endpoint.Address' --output text)
echo "Redis Endpoint: $REDIS_ENDPOINT"
```

### Step 4: Setup Amazon ECS with Fargate

```bash
# 1. Create ECS Cluster
aws ecs create-cluster \
  --cluster-name ecommerce-cluster \
  --capacity-providers FARGATE \
  --default-capacity-provider-strategy capacityProvider=FARGATE,weight=1 \
  --tags key=Name,value=ecommerce-cluster

# 2. Create Task Definition
cat > task-definition.json << EOF
{
  "family": "ecommerce-backend",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "arn:aws:iam::ACCOUNT-ID:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::ACCOUNT-ID:role/ecsTaskRole",
  "containerDefinitions": [
    {
      "name": "backend",
      "image": "YOUR-ECR-REPO/ecommerce-backend:latest",
      "portMappings": [
        {
          "containerPort": 5000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "FLASK_ENV",
          "value": "production"
        },
        {
          "name": "DATABASE_HOST",
          "value": "$RDS_ENDPOINT"
        },
        {
          "name": "DATABASE_NAME",
          "value": "ecommerce"
        },
        {
          "name": "DATABASE_USER",
          "value": "ecommerce_user"
        },
        {
          "name": "REDIS_HOST",
          "value": "$REDIS_ENDPOINT"
        }
      ],
      "secrets": [
        {
          "name": "DATABASE_PASSWORD",
          "valueFrom": "arn:aws:secretsmanager:us-east-1:ACCOUNT-ID:secret:ecommerce-db-password"
        },
        {
          "name": "SECRET_KEY",
          "valueFrom": "arn:aws:secretsmanager:us-east-1:ACCOUNT-ID:secret:ecommerce-secret-key"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/ecommerce-backend",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "healthCheck": {
        "command": ["CMD-SHELL", "curl -f http://localhost:5000/health || exit 1"],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 60
      }
    }
  ]
}
EOF

# 3. Register Task Definition
aws ecs register-task-definition --cli-input-json file://task-definition.json

# 4. Create Application Load Balancer
aws elbv2 create-load-balancer \
  --name ecommerce-alb \
  --subnets subnet-xxx subnet-yyy \
  --security-groups $ALB_SG_ID \
  --scheme internet-facing \
  --tags Key=Name,Value=ecommerce-alb

ALB_ARN=$(aws elbv2 describe-load-balancers --names ecommerce-alb --query 'LoadBalancers[0].LoadBalancerArn' --output text)

# 5. Create Target Group
aws elbv2 create-target-group \
  --name ecommerce-tg \
  --protocol HTTP \
  --port 5000 \
  --vpc-id $VPC_ID \
  --target-type ip \
  --health-check-path /health \
  --health-check-interval-seconds 30 \
  --health-check-timeout-seconds 5 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 3

TG_ARN=$(aws elbv2 describe-target-groups --names ecommerce-tg --query 'TargetGroups[0].TargetGroupArn' --output text)

# 6. Create Listener
aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn=$TG_ARN

# 7. Create ECS Service
aws ecs create-service \
  --cluster ecommerce-cluster \
  --service-name ecommerce-backend-service \
  --task-definition ecommerce-backend:1 \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx,subnet-yyy],securityGroups=[$ECS_SG_ID],assignPublicIp=ENABLED}" \
  --load-balancers targetGroupArn=$TG_ARN,containerName=backend,containerPort=5000 \
  --tags key=Name,value=ecommerce-backend-service
```

### Step 5: Setup Auto Scaling

```bash
# 1. Create Auto Scaling Target
aws application-autoscaling register-scalable-target \
  --service-namespace ecs \
  --resource-id service/ecommerce-cluster/ecommerce-backend-service \
  --scalable-dimension ecs:service:DesiredCount \
  --min-capacity 2 \
  --max-capacity 10

# 2. Create Scaling Policy
aws application-autoscaling put-scaling-policy \
  --service-namespace ecs \
  --resource-id service/ecommerce-cluster/ecommerce-backend-service \
  --scalable-dimension ecs:service:DesiredCount \
  --policy-name ecommerce-cpu-scaling \
  --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration '{
    "TargetValue": 70.0,
    "PredefinedMetricSpecification": {
      "PredefinedMetricType": "ECSServiceAverageCPUUtilization"
    },
    "ScaleOutCooldown": 300,
    "ScaleInCooldown": 300
  }'
```

---

## 🔐 AWS Secrets Manager Setup

```bash
# 1. Create database password secret
aws secretsmanager create-secret \
  --name ecommerce-db-password \
  --description "Database password for ecommerce application" \
  --secret-string "YourSecurePassword123!"

# 2. Create application secret key
aws secretsmanager create-secret \
  --name ecommerce-secret-key \
  --description "Secret key for ecommerce application" \
  --secret-string "your-very-secure-secret-key-for-production"

# 3. Create Redis password secret
aws secretsmanager create-secret \
  --name ecommerce-redis-password \
  --description "Redis password for ecommerce application" \
  --secret-string "your-redis-secure-password"
```

---

## 📊 AWS CloudWatch Setup

```bash
# 1. Create CloudWatch Log Group
aws logs create-log-group \
  --log-group-name /ecs/ecommerce-backend \
  --tags key=Name,value=ecommerce-logs

# 2. Create CloudWatch Dashboard
cat > dashboard.json << 'EOF'
{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/ECS", "CPUUtilization", "ServiceName", "ecommerce-backend-service", "ClusterName", "ecommerce-cluster"],
          [".", "MemoryUtilization", ".", ".", ".", "."]
        ],
        "period": 300,
        "stat": "Average",
        "region": "us-east-1",
        "title": "ECS Service Metrics"
      }
    },
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "ecommerce-alb"],
          [".", "TargetResponseTime", ".", "."],
          [".", "HTTPCode_Target_2XX_Count", ".", "."],
          [".", "HTTPCode_Target_5XX_Count", ".", "."]
        ],
        "period": 300,
        "stat": "Sum",
        "region": "us-east-1",
        "title": "ALB Metrics"
      }
    }
  ]
}
EOF

aws cloudwatch put-dashboard \
  --dashboard-name ecommerce-dashboard \
  --dashboard-body file://dashboard.json
```

---

## 🚀 AWS CodePipeline Setup

```bash
# 1. Create S3 bucket for artifacts
aws s3 mb s3://ecommerce-pipeline-artifacts-$(date +%s)

# 2. Create CodeCommit repository
aws codecommit create-repository \
  --repository-name ecommerce-app \
  --repository-description "E-commerce application repository"

# 3. Create buildspec.yml for CodeBuild
cat > buildspec.yml << 'EOF'
version: 0.2

phases:
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
      - REPOSITORY_URI=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME
      - COMMIT_HASH=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)
      - IMAGE_TAG=${COMMIT_HASH:=latest}
  build:
    commands:
      - echo Build started on `date`
      - echo Building the Docker image...
      - docker build -t $REPOSITORY_URI:latest backend/
      - docker tag $REPOSITORY_URI:latest $REPOSITORY_URI:$IMAGE_TAG
  post_build:
    commands:
      - echo Build completed on `date`
      - echo Pushing the Docker images...
      - docker push $REPOSITORY_URI:latest
      - docker push $REPOSITORY_URI:$IMAGE_TAG
      - echo Writing image definitions file...
      - printf '[{"name":"backend","imageUri":"%s"}]' $REPOSITORY_URI:$IMAGE_TAG > imagedefinitions.json

artifacts:
  files:
    - imagedefinitions.json
EOF

# 4. Create ECR repository
aws ecr create-repository --repository-name ecommerce-backend

# 5. Create CodePipeline
# (This would involve creating IAM roles, CodeBuild projects, and the pipeline itself)
```

---

## 🔍 Monitoring and Troubleshooting

### CloudWatch Alarms

```bash
# CPU Utilization Alarm
aws cloudwatch put-metric-alarm \
  --alarm-name ecommerce-high-cpu \
  --alarm-description "Alarm when CPU exceeds 80%" \
  --metric-name CPUUtilization \
  --namespace AWS/ECS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=ServiceName,Value=ecommerce-backend-service Name=ClusterName,Value=ecommerce-cluster \
  --evaluation-periods 2

# Memory Utilization Alarm
aws cloudwatch put-metric-alarm \
  --alarm-name ecommerce-high-memory \
  --alarm-description "Alarm when Memory exceeds 80%" \
  --metric-name MemoryUtilization \
  --namespace AWS/ECS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=ServiceName,Value=ecommerce-backend-service Name=ClusterName,Value=ecommerce-cluster \
  --evaluation-periods 2
```

### Common Commands

```bash
# Check ECS service status
aws ecs describe-services \
  --cluster ecommerce-cluster \
  --services ecommerce-backend-service

# View ECS service logs
aws logs tail /ecs/ecommerce-backend --follow

# Check RDS status
aws rds describe-db-instances \
  --db-instance-identifier ecommerce-db

# Check ElastiCache status
aws elasticache describe-cache-clusters \
  --cache-cluster-id ecommerce-redis \
  --show-cache-node-info

# Check ALB target health
aws elbv2 describe-target-health \
  --target-group-arn $TG_ARN
```

---

## 💰 Cost Optimization

### Reserved Instances
```bash
# Purchase RDS Reserved Instance
aws rds purchase-reserved-db-instances-offering \
  --reserved-db-instances-offering-id your-offering-id \
  --reserved-db-instance-id ecommerce-db-reserved

# Purchase ElastiCache Reserved Instance
aws elasticache purchase-reserved-cache-nodes-offering \
  --reserved-cache-nodes-offering-id your-offering-id \
  --reserved-cache-node-id ecommerce-cache-reserved
```

### Cleanup Commands
```bash
# Stop ECS service
aws ecs update-service \
  --cluster ecommerce-cluster \
  --service ecommerce-backend-service \
  --desired-count 0

# Delete ECS service
aws ecs delete-service \
  --cluster ecommerce-cluster \
  --service ecommerce-backend-service \
  --force

# Delete RDS instance
aws rds delete-db-instance \
  --db-instance-identifier ecommerce-db \
  --skip-final-snapshot

# Delete ElastiCache cluster
aws elasticache delete-cache-cluster \
  --cache-cluster-id ecommerce-redis
```

---

## 📊 Monitoring and Cost Optimization

### CloudWatch Monitoring Setup

#### Application Performance Monitoring

```bash
# Create custom CloudWatch dashboard
aws cloudwatch put-dashboard \
  --dashboard-name "Ecommerce-Application-Dashboard" \
  --dashboard-body '{
    "widgets": [
      {
        "type": "metric",
        "properties": {
          "metrics": [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", "your-alb-name"],
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "your-alb-name"],
            ["AWS/ECS", "CPUUtilization", "ServiceName", "ecommerce-backend", "ClusterName", "ecommerce-cluster"],
            ["AWS/ECS", "MemoryUtilization", "ServiceName", "ecommerce-backend", "ClusterName", "ecommerce-cluster"]
          ],
          "period": 300,
          "stat": "Average",
          "region": "us-east-1",
          "title": "Application Performance"
        }
      }
    ]
  }'

# Set up critical alarms
aws cloudwatch put-metric-alarm \
  --alarm-name "High-Response-Time" \
  --alarm-description "Application response time is high" \
  --metric-name TargetResponseTime \
  --namespace AWS/ApplicationELB \
  --statistic Average \
  --period 300 \
  --threshold 2 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --alarm-actions arn:aws:sns:us-east-1:ACCOUNT:ecommerce-alerts

aws cloudwatch put-metric-alarm \
  --alarm-name "High-Error-Rate" \
  --alarm-description "Application error rate is high" \
  --metric-name HTTPCode_Target_5XX_Count \
  --namespace AWS/ApplicationELB \
  --statistic Sum \
  --period 300 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --alarm-actions arn:aws:sns:us-east-1:ACCOUNT:ecommerce-alerts
```

#### Database Monitoring

```bash
# RDS Performance Insights
aws rds modify-db-instance \
  --db-instance-identifier ecommerce-db \
  --enable-performance-insights \
  --performance-insights-retention-period 7

# Create RDS alarms
aws cloudwatch put-metric-alarm \
  --alarm-name "RDS-High-CPU" \
  --alarm-description "RDS CPU utilization is high" \
  --metric-name CPUUtilization \
  --namespace AWS/RDS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=DBInstanceIdentifier,Value=ecommerce-db \
  --evaluation-periods 2

aws cloudwatch put-metric-alarm \
  --alarm-name "RDS-High-Connections" \
  --alarm-description "RDS connection count is high" \
  --metric-name DatabaseConnections \
  --namespace AWS/RDS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=DBInstanceIdentifier,Value=ecommerce-db \
  --evaluation-periods 2
```

### Cost Optimization Strategies

#### 1. Right-Sizing Resources

```bash
# Use AWS Compute Optimizer recommendations
aws compute-optimizer get-ecs-service-recommendations \
  --service-arns arn:aws:ecs:us-east-1:ACCOUNT:service/ecommerce-cluster/ecommerce-backend

# Implement Reserved Instances for RDS
aws rds describe-reserved-db-instances-offerings \
  --db-instance-class db.t3.micro \
  --product-description postgresql
```

#### 2. Automated Resource Management

```bash
# Schedule non-production environments to shut down
# Create Lambda function for resource scheduling
cat > schedule-resources.py << 'EOF'
import boto3
import json

def lambda_handler(event, context):
    ecs = boto3.client('ecs')
    
    # Scale down non-production services at night
    if event['action'] == 'scale_down':
        ecs.update_service(
            cluster='ecommerce-cluster-dev',
            service='ecommerce-backend',
            desiredCount=0
        )
    elif event['action'] == 'scale_up':
        ecs.update_service(
            cluster='ecommerce-cluster-dev',
            service='ecommerce-backend',
            desiredCount=2
        )
    
    return {'statusCode': 200}
EOF
```

#### 3. Storage Optimization

```bash
# Use gp3 volumes for better cost/performance
aws rds modify-db-instance \
  --db-instance-identifier ecommerce-db \
  --storage-type gp3 \
  --allocated-storage 20

# Enable S3 Intelligent Tiering for static assets
aws s3api put-bucket-intelligent-tiering-configuration \
  --bucket ecommerce-static-assets \
  --id EntireBucket \
  --intelligent-tiering-configuration Id=EntireBucket,Status=Enabled,OptionalFields=BucketKeyStatus
```

### Security Best Practices

#### 1. Network Security

```bash
# Enable VPC Flow Logs
aws ec2 create-flow-logs \
  --resource-type VPC \
  --resource-ids vpc-12345678 \
  --traffic-type ALL \
  --log-destination-type cloud-watch-logs \
  --log-group-name VPCFlowLogs

# Enable GuardDuty
aws guardduty create-detector \
  --enable \
  --finding-publishing-frequency FIFTEEN_MINUTES
```

#### 2. Application Security

```bash
# Enable AWS WAF for ALB
aws wafv2 create-web-acl \
  --scope REGIONAL \
  --default-action Allow={} \
  --rules file://waf-rules.json \
  --name ecommerce-waf

# Enable AWS Config for compliance monitoring
aws configservice put-configuration-recorder \
  --configuration-recorder name=ecommerce-recorder,roleARN=arn:aws:iam::ACCOUNT:role/aws-config-role \
  --recording-group allSupportedResourceTypes=true,includeGlobalResourceTypes=true
```

---

## 🔧 Troubleshooting Guide

### Common Deployment Issues

#### 1. ECS Tasks Not Starting

**Symptoms**: Tasks stuck in PENDING state

**Solutions**:
```bash
# Check task definition
aws ecs describe-task-definition --task-definition ecommerce-backend

# Check service events
aws ecs describe-services --cluster ecommerce-cluster --services ecommerce-backend

# Check CloudWatch logs
aws logs describe-log-streams --log-group-name /ecs/ecommerce-backend

# Common fixes:
# - Ensure ECR image exists and is accessible
# - Check IAM permissions for task execution role
# - Verify subnet has internet access for image pulls
# - Check security group rules
```

#### 2. Database Connection Issues

**Symptoms**: Application can't connect to RDS

**Solutions**:
```bash
# Check RDS instance status
aws rds describe-db-instances --db-instance-identifier ecommerce-db

# Test connectivity from ECS task
aws ecs run-task \
  --cluster ecommerce-cluster \
  --task-definition ecommerce-debug \
  --overrides '{
    "containerOverrides": [{
      "name": "debug",
      "command": ["nc", "-zv", "RDS-ENDPOINT", "5432"]
    }]
  }'

# Common fixes:
# - Check security group rules (port 5432 from ECS security group)
# - Verify RDS is in same VPC
# - Check secrets in AWS Secrets Manager
# - Ensure RDS is not publicly accessible
```

#### 3. Load Balancer Health Check Failures

**Symptoms**: Targets showing unhealthy in ALB

**Solutions**:
```bash
# Check target group health
aws elbv2 describe-target-health --target-group-arn TARGET-GROUP-ARN

# Check application logs
aws logs tail /ecs/ecommerce-backend --follow

# Test health endpoint directly
curl -v http://CONTAINER-IP:5000/health

# Common fixes:
# - Ensure health endpoint returns 200 status
# - Check health check path in target group
# - Verify application is listening on correct port
# - Adjust health check timeout and interval
```

#### 4. Performance Issues

**Symptoms**: Slow response times, high CPU usage

**Solutions**:
```bash
# Check application metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=ecommerce-backend \
  --start-time 2023-01-01T00:00:00Z \
  --end-time 2023-01-01T23:59:59Z \
  --period 3600 \
  --statistics Average

# Check database performance
aws rds describe-db-instances \
  --db-instance-identifier ecommerce-db \
  --query 'DBInstances[0].{CPU:CpuUtilization,Connections:DatabaseConnections}'

# Performance optimization:
# - Scale up ECS service desired count
# - Increase task CPU/memory
# - Optimize database queries
# - Implement Redis caching
# - Use CDN for static assets
```

### Monitoring Commands

```bash
# Real-time application monitoring
watch -n 5 'aws ecs describe-services --cluster ecommerce-cluster --services ecommerce-backend --query "services[0].{Running:runningCount,Desired:desiredCount,Status:status}"'

# Check recent application logs
aws logs tail /ecs/ecommerce-backend --since 10m

# Monitor ALB metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name RequestCount \
  --dimensions Name=LoadBalancer,Value=app/ecommerce-alb/1234567890abcdef \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Sum

# Database monitoring
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name CPUUtilization \
  --dimensions Name=DBInstanceIdentifier,Value=ecommerce-db \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Average
```

---

## 📝 Summary and Best Practices

### Deployment Options Comparison

| Feature | Elastic Beanstalk | EKS | ECS Fargate |
|---------|------------------|-----|-------------|
| **Complexity** | Low | High | Medium |
| **Control** | Limited | Full | High |
| **Kubernetes** | No | Yes | No |
| **Auto Scaling** | Built-in | Manual setup | Built-in |
| **Cost** | Low | Medium-High | Medium |
| **Best For** | Simple apps | Complex apps | Container apps |

### Production Readiness Checklist

#### Security
- [ ] VPC with private subnets for application/database
- [ ] Security groups with least privilege access
- [ ] Secrets stored in AWS Secrets Manager
- [ ] SSL/TLS certificates from AWS Certificate Manager
- [ ] WAF enabled for web application protection
- [ ] GuardDuty enabled for threat detection

#### Monitoring
- [ ] CloudWatch alarms for critical metrics
- [ ] Application and infrastructure logging
- [ ] Performance monitoring dashboard
- [ ] Database performance insights enabled
- [ ] Cost monitoring and budgets configured

#### High Availability
- [ ] Multi-AZ deployment
- [ ] Auto-scaling configured
- [ ] Database backups enabled
- [ ] Disaster recovery plan documented
- [ ] Health checks properly configured

#### Performance
- [ ] CDN configured for static assets
- [ ] Redis caching implemented
- [ ] Database query optimization
- [ ] Connection pooling configured
- [ ] Resource right-sizing completed

### Cost Optimization Recommendations

1. **Use Reserved Instances** for predictable workloads
2. **Implement auto-scaling** to match demand
3. **Use Spot Instances** for non-critical workloads
4. **Regular resource review** and right-sizing
5. **Enable cost allocation tags** for better tracking
6. **Set up billing alerts** and budgets

### Next Steps

1. **Choose your deployment method** based on requirements
2. **Run the appropriate deployment script**
3. **Configure monitoring and alerting**
4. **Set up CI/CD pipeline** for automated deployments
5. **Implement security best practices**
6. **Monitor costs and optimize** regularly

Each deployment method provides a production-ready environment with:
- **High availability** across multiple AZs
- **Auto-scaling** based on demand
- **Security** with proper network isolation
- **Monitoring** and alerting capabilities
- **Cost optimization** features

Choose the method that best fits your team's expertise and requirements.
