# Amazon EKS Deployment

This directory contains scripts and configurations for deploying the e-commerce application on Amazon EKS (Elastic Kubernetes Service).

## 📁 Files

- `cluster-config.yaml` - EKS cluster configuration for eksctl
- `values-aws.yaml` - Helm values file optimized for AWS
- `deploy-eks.sh` - Automated deployment script
- `README.md` - This file

## 🚀 Quick Deploy

```bash
# Make the script executable
chmod +x deploy-eks.sh

# Run the deployment
./deploy-eks.sh
```

## 📋 Prerequisites

Before running the deployment, ensure you have:

1. **AWS CLI** configured with appropriate permissions
2. **eksctl** installed
3. **kubectl** installed
4. **Helm 3.x** installed
5. **Docker** installed
6. An AWS key pair for EC2 instances

### Install Prerequisites

```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

## ⚙️ Configuration

### 1. Update cluster-config.yaml

Edit the following values in `cluster-config.yaml`:

- `metadata.name` - Your cluster name
- `metadata.region` - Your preferred AWS region
- `nodeGroups[].ssh.publicKeyName` - Your EC2 key pair name
- `secretsEncryption.keyARN` - Your KMS key ARN (optional)

### 2. Update values-aws.yaml

Edit the following values in `values-aws.yaml`:

- `image.backend.repository` - Your ECR repository URL
- `ingress.annotations.alb.ingress.kubernetes.io/certificate-arn` - Your ACM certificate ARN
- `ingress.hosts[].host` - Your domain name
- `aws.accountId` - Your AWS account ID

### 3. Create ECR Repository

```bash
# Create ECR repository for the backend image
aws ecr create-repository --repository-name ecommerce-backend --region us-east-1

# Get login token and login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR-ACCOUNT.dkr.ecr.us-east-1.amazonaws.com

# Build and push the backend image
cd ../../../backend
docker build -t ecommerce-backend .
docker tag ecommerce-backend:latest YOUR-ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/ecommerce-backend:latest
docker push YOUR-ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/ecommerce-backend:latest
```

## 🔧 Manual Deployment Steps

If you prefer to deploy manually, follow these steps:

### Step 1: Create EKS Cluster

```bash
eksctl create cluster --config-file cluster-config.yaml
```

### Step 2: Install AWS Load Balancer Controller

```bash
# Download IAM policy
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.6.2/docs/install/iam_policy.json

# Create IAM policy
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

# Create service account
eksctl create iamserviceaccount \
  --cluster=ecommerce-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name "AmazonEKSLoadBalancerControllerRole" \
  --attach-policy-arn=arn:aws:iam::YOUR-ACCOUNT:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve

# Install controller with Helm
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=ecommerce-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

### Step 3: Deploy Application

```bash
# Create namespace
kubectl create namespace ecommerce-prod

# Deploy with Helm
helm upgrade --install ecommerce ../../k8s/helm/ecommerce \
  --namespace ecommerce-prod \
  --values values-aws.yaml
```

## 🔍 Monitoring and Troubleshooting

### Check Cluster Status

```bash
# Check cluster info
kubectl cluster-info

# Check nodes
kubectl get nodes

# Check pods
kubectl get pods -n ecommerce-prod

# Check services
kubectl get services -n ecommerce-prod

# Check ingress
kubectl get ingress -n ecommerce-prod
```

### View Logs

```bash
# View application logs
kubectl logs -n ecommerce-prod -l app.kubernetes.io/name=ecommerce

# View load balancer controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

### Access Application

```bash
# Get load balancer URL
kubectl get ingress -n ecommerce-prod -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'
```

## 🧹 Cleanup

To delete all resources:

```bash
# Delete Helm release
helm uninstall ecommerce -n ecommerce-prod

# Delete namespace
kubectl delete namespace ecommerce-prod

# Delete cluster
eksctl delete cluster --name ecommerce-cluster --region us-east-1
```

## 💰 Cost Optimization

The configuration includes several cost optimization features:

1. **Spot Instances** - Managed node group uses spot instances
2. **Single NAT Gateway** - Reduces networking costs
3. **Appropriate Instance Types** - t3.medium for most workloads
4. **Auto Scaling** - Scales down during low usage

## 🔒 Security Best Practices

- **RBAC** - Role-based access control configured
- **Network Policies** - Restrict pod-to-pod communication
- **Secrets Management** - Sensitive data stored in Kubernetes secrets
- **Image Scanning** - Use ECR image scanning
- **Private Subnets** - Worker nodes in private subnets

## 📖 Additional Resources

- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [AWS Load Balancer Controller Documentation](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [Cluster Autoscaler Documentation](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler)
