#!/bin/bash

# Amazon EKS Deployment Script for E-commerce Application

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
REGION="us-east-1"
NAMESPACE="ecommerce-prod"
APP_NAME="ecommerce"

# Check prerequisites
check_prerequisites() {
    print_status "🔍 Checking prerequisites..."
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI not found. Please install AWS CLI."
        exit 1
    fi
    
    if ! command -v eksctl &> /dev/null; then
        print_error "eksctl not found. Please install eksctl."
        print_status "Install with: curl --silent --location \"https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_\$(uname -s)_amd64.tar.gz\" | tar xz -C /tmp && sudo mv /tmp/eksctl /usr/local/bin"
        exit 1
    fi
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl not found. Please install kubectl."
        exit 1
    fi
    
    if ! command -v helm &> /dev/null; then
        print_error "Helm not found. Please install Helm 3.x."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Please run 'aws configure'."
        exit 1
    fi
    
    print_status "✅ All prerequisites met"
}

# Create EKS cluster
create_cluster() {
    print_status "🚀 Creating EKS cluster..."
    
    # Check if cluster exists
    if eksctl get cluster --name $CLUSTER_NAME --region $REGION &> /dev/null; then
        print_warning "Cluster '$CLUSTER_NAME' already exists. Updating configuration..."
        eksctl update cluster --name $CLUSTER_NAME --region $REGION --config-file cluster-config.yaml
    else
        print_status "Creating new EKS cluster (this may take 15-20 minutes)..."
        eksctl create cluster --config-file cluster-config.yaml
    fi
    
    # Update kubeconfig
    aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME
    
    print_status "✅ EKS cluster created successfully"
}

# Install AWS Load Balancer Controller
install_alb_controller() {
    print_status "🔧 Installing AWS Load Balancer Controller..."
    
    # Download IAM policy
    curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.6.2/docs/install/iam_policy.json
    
    # Get AWS account ID
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    
    # Create IAM policy
    aws iam create-policy \
        --policy-name AWSLoadBalancerControllerIAMPolicy \
        --policy-document file://iam_policy.json || true
    
    # Create service account
    eksctl create iamserviceaccount \
        --cluster=$CLUSTER_NAME \
        --namespace=kube-system \
        --name=aws-load-balancer-controller \
        --role-name "AmazonEKSLoadBalancerControllerRole" \
        --attach-policy-arn=arn:aws:iam::$ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy \
        --approve \
        --region $REGION || true
    
    # Add eks helm repo
    helm repo add eks https://aws.github.io/eks-charts
    helm repo update
    
    # Install load balancer controller
    helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
        -n kube-system \
        --set clusterName=$CLUSTER_NAME \
        --set serviceAccount.create=false \
        --set serviceAccount.name=aws-load-balancer-controller \
        --set region=$REGION \
        --set vpcId=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query "cluster.resourcesVpcConfig.vpcId" --output text)
    
    print_status "✅ AWS Load Balancer Controller installed"
}

# Install additional controllers
install_addons() {
    print_status "📦 Installing additional add-ons..."
    
    # Install metrics server
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    
    # Install cluster autoscaler
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
    
    # Patch cluster autoscaler deployment
    kubectl -n kube-system annotate deployment.apps/cluster-autoscaler cluster-autoscaler.kubernetes.io/safe-to-evict="false"
    kubectl -n kube-system patch deployment cluster-autoscaler -p '{"spec":{"template":{"metadata":{"annotations":{"cluster-autoscaler.kubernetes.io/safe-to-evict":"false"}}}}}'
    kubectl -n kube-system set image deployment.apps/cluster-autoscaler cluster-autoscaler=k8s.gcr.io/autoscaling/cluster-autoscaler:v1.21.0
    
    # Add cluster name to cluster autoscaler
    kubectl -n kube-system patch deployment cluster-autoscaler --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/command/-", "value": "--node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/'$CLUSTER_NAME'"}]'
    
    print_status "✅ Add-ons installed successfully"
}

# Setup RDS database
setup_rds() {
    print_status "🗄️ Setting up RDS PostgreSQL database..."
    
    # Check if RDS instance exists
    if aws rds describe-db-instances --db-instance-identifier ecommerce-db --region $REGION &> /dev/null; then
        print_warning "RDS instance 'ecommerce-db' already exists"
        RDS_ENDPOINT=$(aws rds describe-db-instances --db-instance-identifier ecommerce-db --region $REGION --query 'DBInstances[0].Endpoint.Address' --output text)
    else
        print_status "Creating RDS cluster..."
        
        # Get VPC and subnets from EKS cluster
        VPC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query "cluster.resourcesVpcConfig.vpcId" --output text)
        SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:kubernetes.io/role/internal-elb,Values=1" --region $REGION --query 'Subnets[].SubnetId' --output text)
        
        # Create DB subnet group
        aws rds create-db-subnet-group \
            --db-subnet-group-name ecommerce-db-subnet-group \
            --db-subnet-group-description "Subnet group for ecommerce database" \
            --subnet-ids $SUBNET_IDS \
            --region $REGION || true
        
        # Create RDS cluster
        aws rds create-db-cluster \
            --db-cluster-identifier ecommerce-cluster \
            --engine aurora-postgresql \
            --engine-version 15.4 \
            --master-username ecommerce_user \
            --master-user-password EcommercePass123! \
            --database-name ecommerce \
            --backup-retention-period 7 \
            --storage-encrypted \
            --vpc-security-group-ids $(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=default" --region $REGION --query 'SecurityGroups[0].GroupId' --output text) \
            --db-subnet-group-name ecommerce-db-subnet-group \
            --region $REGION
        
        # Create DB instance
        aws rds create-db-instance \
            --db-instance-identifier ecommerce-db \
            --db-instance-class db.r6g.large \
            --engine aurora-postgresql \
            --db-cluster-identifier ecommerce-cluster \
            --region $REGION
        
        print_status "⏳ Waiting for RDS cluster to be available..."
        aws rds wait db-cluster-available --db-cluster-identifier ecommerce-cluster --region $REGION
        
        RDS_ENDPOINT=$(aws rds describe-db-clusters --db-cluster-identifier ecommerce-cluster --region $REGION --query 'DBClusters[0].Endpoint' --output text)
    fi
    
    print_status "📊 RDS endpoint: $RDS_ENDPOINT"
}

# Setup ElastiCache
setup_elasticache() {
    print_status "🔄 Setting up ElastiCache Redis..."
    
    # Check if ElastiCache cluster exists
    if aws elasticache describe-replication-groups --replication-group-id ecommerce-redis --region $REGION &> /dev/null; then
        print_warning "ElastiCache cluster 'ecommerce-redis' already exists"
        REDIS_ENDPOINT=$(aws elasticache describe-replication-groups --replication-group-id ecommerce-redis --region $REGION --query 'ReplicationGroups[0].NodeGroups[0].PrimaryEndpoint.Address' --output text)
    else
        # Get VPC and subnets from EKS cluster
        VPC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query "cluster.resourcesVpcConfig.vpcId" --output text)
        SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:kubernetes.io/role/internal-elb,Values=1" --region $REGION --query 'Subnets[].SubnetId' --output text)
        
        # Create cache subnet group
        aws elasticache create-cache-subnet-group \
            --cache-subnet-group-name ecommerce-cache-subnet-group \
            --cache-subnet-group-description "Subnet group for ecommerce cache" \
            --subnet-ids $SUBNET_IDS \
            --region $REGION || true
        
        # Create ElastiCache cluster
        aws elasticache create-replication-group \
            --replication-group-id ecommerce-redis \
            --description "Redis cluster for ecommerce application" \
            --num-cache-clusters 2 \
            --cache-node-type cache.r6g.large \
            --engine redis \
            --engine-version 7.0 \
            --cache-parameter-group default.redis7 \
            --cache-subnet-group-name ecommerce-cache-subnet-group \
            --security-group-ids $(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=default" --region $REGION --query 'SecurityGroups[0].GroupId' --output text) \
            --at-rest-encryption-enabled \
            --transit-encryption-enabled \
            --region $REGION
        
        print_status "⏳ Waiting for ElastiCache cluster to be available..."
        aws elasticache wait replication-group-available --replication-group-id ecommerce-redis --region $REGION
        
        REDIS_ENDPOINT=$(aws elasticache describe-replication-groups --replication-group-id ecommerce-redis --region $REGION --query 'ReplicationGroups[0].NodeGroups[0].PrimaryEndpoint.Address' --output text)
    fi
    
    print_status "🔄 Redis endpoint: $REDIS_ENDPOINT"
}

# Create Kubernetes secrets
create_secrets() {
    print_status "🔐 Creating Kubernetes secrets..."
    
    # Create namespace
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    
    # Create secrets
    kubectl create secret generic ecommerce-secrets \
        --from-literal=database-host="$RDS_ENDPOINT" \
        --from-literal=database-password="EcommercePass123!" \
        --from-literal=redis-host="$REDIS_ENDPOINT" \
        --from-literal=redis-password="" \
        --from-literal=secret-key="$(openssl rand -base64 32)" \
        --namespace=$NAMESPACE \
        --dry-run=client -o yaml | kubectl apply -f -
    
    print_status "✅ Secrets created successfully"
}

# Deploy application using Helm
deploy_application() {
    print_status "🚀 Deploying application using Helm..."
    
    # Add ECR login helper
    aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.$REGION.amazonaws.com
    
    # Deploy using Helm
    helm upgrade --install $APP_NAME ../../k8s/helm/ecommerce \
        --namespace $NAMESPACE \
        --values values-aws.yaml \
        --set image.backend.repository=$(aws sts get-caller-identity --query Account --output text).dkr.ecr.$REGION.amazonaws.com/ecommerce-backend \
        --set postgresql.external.host="$RDS_ENDPOINT" \
        --set redis.external.host="$REDIS_ENDPOINT" \
        --set aws.accountId=$(aws sts get-caller-identity --query Account --output text) \
        --timeout 10m \
        --wait
    
    print_status "✅ Application deployed successfully"
}

# Verify deployment
verify_deployment() {
    print_status "🔍 Verifying deployment..."
    
    # Check pods
    kubectl get pods -n $NAMESPACE
    
    # Check services
    kubectl get services -n $NAMESPACE
    
    # Check ingress
    kubectl get ingress -n $NAMESPACE
    
    # Get load balancer URL
    LB_URL=$(kubectl get ingress -n $NAMESPACE -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')
    
    if [ ! -z "$LB_URL" ]; then
        print_status "🌐 Application URL: https://$LB_URL"
    else
        print_warning "Load balancer URL not yet available. Check back in a few minutes."
    fi
    
    print_status "✅ Deployment verification complete"
}

# Main execution
main() {
    print_status "🚀 Starting EKS deployment for E-commerce Application"
    
    check_prerequisites
    create_cluster
    install_alb_controller
    install_addons
    setup_rds
    setup_elasticache
    create_secrets
    deploy_application
    verify_deployment
    
    print_status "🎉 EKS deployment completed successfully!"
    print_status "📋 Next steps:"
    print_status "  1. Configure your domain name to point to the load balancer"
    print_status "  2. Set up SSL certificate in AWS Certificate Manager"
    print_status "  3. Update the ingress configuration with your domain and certificate ARN"
    print_status "  4. Set up monitoring and alerting"
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
