# AWS Deployment Scripts

This folder contains scripts and configurations for deploying the## 🚀 Quick Start Guide

### Option 1: Master Deployment Script (Recommended)
```bash
# Navigate to aws-deploy directory
cd aws-deploy

# Interactive deployment with menu selection
./deploy-aws.sh

# Direct deployment to specific service
./deploy-aws.sh --method elastic-beanstalk --region us-east-1

# Setup monitoring only
NOTIFICATION_EMAIL=admin@example.com ./deploy-aws.sh --method monitoring
```

### Option 2: Manual Step-by-Step Deployment

#### Step 1: Prepare Environmentcommerce application on AWS.

## 📁 Folder Structure

```
aws-deploy/
├── elastic-beanstalk/          # Elastic Beanstalk deployment
│   ├── Dockerrun.aws.json      # EB Docker configuration
│   ├── .ebextensions/          # EB configuration files
│   ├── deploy-eb.sh            # EB deployment script
│   └── README.md
│
├── eks/                        # Amazon EKS deployment
│   ├── cluster-config.yaml     # EKS cluster configuration
│   ├── values-aws.yaml         # Helm values for AWS
│   ├── deploy-eks.sh           # EKS deployment script
│   └── README.md
│
├── ecs-fargate/                # ECS with Fargate deployment
│   ├── task-definition.json    # ECS task definition
│   ├── infrastructure.yaml     # CloudFormation template
│   ├── deploy-ecs.sh           # ECS deployment script
│   └── README.md
│
├── cloudformation/             # Infrastructure as Code
│   ├── vpc-template.yaml       # VPC and networking
│   ├── rds-template.yaml       # RDS PostgreSQL
│   ├── elasticache-template.yaml # ElastiCache Redis
│   ├── ecs-template.yaml       # ECS cluster and services
│   └── master-template.yaml    # Master template
│
├── scripts/                    # Utility scripts
│   ├── setup-aws-cli.sh        # AWS CLI configuration
│   ├── create-ecr-repo.sh      # ECR repository setup
│   ├── build-and-push.sh       # Build and push Docker images
│   ├── setup-secrets.sh        # AWS Secrets Manager setup
│   └── cleanup-resources.sh    # Resource cleanup
│
└── monitoring/                 # Monitoring and logging
    ├── cloudwatch-dashboard.json # CloudWatch dashboard
    ├── alarms.yaml             # CloudWatch alarms
    └── log-groups.yaml         # Log group configurations
```

# AWS Deployment Scripts

This folder contains comprehensive scripts and configurations for deploying the e-commerce application on AWS using multiple deployment strategies.

## � Complete Folder Structure

```
aws-deploy/
├── elastic-beanstalk/          # AWS Elastic Beanstalk deployment
│   ├── deploy-eb.sh            # ✅ Automated EB deployment script
│   └── README.md               # ✅ EB deployment guide
│
├── eks/                        # Amazon EKS deployment
│   ├── cluster-config.yaml     # ✅ EKS cluster configuration
│   ├── values-aws.yaml         # ✅ Helm values for AWS
│   ├── deploy-eks.sh           # ✅ EKS deployment script
│   └── README.md               # ✅ EKS deployment guide
│
├── ecs-fargate/                # ECS with Fargate deployment
│   ├── task-definition.json    # ✅ ECS task definition
│   ├── infrastructure.yaml     # ✅ CloudFormation template
│   ├── deploy-ecs.sh           # ✅ ECS deployment script
│   └── README.md               # ✅ ECS deployment guide
│
├── cloudformation/             # Infrastructure as Code
│   ├── vpc-template.yaml       # ✅ VPC and networking
│   ├── rds-template.yaml       # RDS PostgreSQL
│   ├── elasticache-template.yaml # ElastiCache Redis
│   ├── ecs-template.yaml       # ECS cluster and services
│   └── master-template.yaml    # Master template
│
├── scripts/                    # Utility scripts
│   ├── setup-aws-cli.sh        # ✅ AWS CLI configuration
│   ├── create-ecr-repo.sh      # ✅ ECR repository setup
│   ├── build-and-push.sh       # ✅ Build and push Docker images
│   ├── setup-secrets.sh        # AWS Secrets Manager setup
│   └── cleanup-resources.sh    # Resource cleanup
│
├── monitoring/                 # Monitoring and logging
│   ├── cloudwatch-dashboard.json # ✅ CloudWatch dashboard
│   ├── setup-alarms.sh         # ✅ CloudWatch alarms setup
│   ├── xray-config.json        # ✅ X-Ray tracing configuration
│   └── README.md               # ✅ Monitoring setup guide
│
├── deploy-aws.sh               # ✅ Master deployment script
├── make-executable.sh          # ✅ Make all scripts executable
└── README.md                   # ✅ This file
```

## �🚀 Quick Start Guide

### Step 1: Prepare Environment

```bash
# Navigate to aws-deploy directory
cd aws-deploy

# Make all scripts executable
chmod +x make-executable.sh
./make-executable.sh

# Setup AWS CLI (if not already configured)
./scripts/setup-aws-cli.sh
```

### Step 2: Choose Deployment Method

#### Option A: Elastic Beanstalk (Easiest)
```bash
cd elastic-beanstalk
./deploy-eb.sh
```

#### Option B: Amazon EKS (Most Flexible)
```bash
cd eks
./deploy-eks.sh
```

#### Option C: Amazon ECS Fargate (Serverless Containers)
```bash
cd ecs-fargate
./deploy-ecs.sh
```

### Step 3: Setup Monitoring (Optional but Recommended)

```bash
# Setup CloudWatch dashboards and alarms
cd monitoring
export NOTIFICATION_EMAIL=your-email@example.com
./setup-alarms.sh
```

### Step 4: Post-Deployment

1. **Verify deployment** using the provided verification commands
2. **Configure domain name** to point to load balancer
3. **Set up SSL certificate** in AWS Certificate Manager
4. **Review monitoring dashboards** in CloudWatch
5. **Test application** functionality and performance
6. **Review security** settings and access controls

## 📋 Deployment Comparison

| Feature | Elastic Beanstalk | EKS | ECS Fargate |
|---------|------------------|-----|-------------|
| **Setup Complexity** | ⭐ Low | ⭐⭐⭐ High | ⭐⭐ Medium |
| **Control Level** | ⭐⭐ Limited | ⭐⭐⭐ Full | ⭐⭐⭐ High |
| **Kubernetes** | ❌ No | ✅ Yes | ❌ No |
| **Auto Scaling** | ✅ Built-in | ⚙️ Manual setup | ✅ Built-in |
| **Cost** | 💰 Low | 💰💰 Medium-High | 💰💰 Medium |
| **Best For** | Simple deployments | Complex microservices | Container apps |
| **Learning Curve** | Easy | Steep | Moderate |

## 🛠️ What Each Deployment Creates

### Common Components (All Deployments)
- **VPC** with public/private subnets
- **Application Load Balancer** for traffic distribution
- **RDS PostgreSQL** database with encryption
- **ElastiCache Redis** for caching and sessions
- **Security Groups** with least privilege access
- **AWS Secrets Manager** for sensitive data
- **CloudWatch** logging and monitoring

### Elastic Beanstalk Specific
- **EB Application** and environment
- **Auto Scaling Group** for EC2 instances
- **Elastic Load Balancer** (Classic or ALB)
- **EB Health Monitoring**

### EKS Specific
- **EKS Cluster** with managed node groups
- **AWS Load Balancer Controller**
- **Cluster Autoscaler**
- **Helm charts** for application deployment
- **Kubernetes RBAC** and service accounts

### ECS Fargate Specific
- **ECS Cluster** with Fargate capacity
- **ECS Service** with auto scaling
- **CloudFormation** stack for infrastructure
- **Application Auto Scaling** policies

## � Monitoring and Observability

### Built-in Monitoring Features
All deployments include comprehensive monitoring:

- **CloudWatch Dashboards** - Visual metrics and performance data
- **CloudWatch Alarms** - Automated alerting for critical issues
- **Application Logs** - Centralized logging with structured data
- **X-Ray Tracing** - Distributed request tracing (optional)
- **Performance Insights** - Database performance monitoring

### Key Metrics Monitored
- **Application Performance**: Response time, error rate, throughput
- **Infrastructure Health**: CPU, memory, network, disk utilization
- **Database Performance**: Connection count, query latency, CPU usage
- **Cache Performance**: Hit rate, memory usage, connection count
- **Load Balancer**: Request count, target health, latency

### Automated Alerts
Preconfigured alarms for:
- High CPU utilization (>80%)
- High memory usage (>85%)
- Application errors (>10 5xx errors)
- Database connection exhaustion (>50 connections)
- High response time (>2 seconds)

### Monitoring Setup
```bash
# Setup monitoring (after deployment)
cd monitoring
export NOTIFICATION_EMAIL=admin@example.com
./setup-alarms.sh

# View CloudWatch dashboard
# https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:
```

## �🔧 Utility Scripts

### AWS CLI Setup (`scripts/setup-aws-cli.sh`)
- Installs AWS CLI if not present
- Configures credentials and profiles
- Checks required permissions
- Validates configuration

### ECR Repository Setup (`scripts/create-ecr-repo.sh`)
- Creates ECR repositories for all images
- Sets up lifecycle policies
- Configures repository permissions
- Provides login credentials

### Build and Push (`scripts/build-and-push.sh`)
- Builds Docker images for all components
- Tags images with build date and git commit
- Pushes to ECR repositories
- Scans for vulnerabilities
- Generates build reports

## 🔒 Security Features

### Network Security
- **VPC isolation** with private subnets
- **Security Groups** with minimal required access
- **NAT Gateways** for secure outbound connectivity
- **VPC Flow Logs** for network monitoring

### Data Security
- **Encryption at rest** for RDS and ElastiCache
- **Encryption in transit** for all communications
- **AWS Secrets Manager** for credential management
- **IAM roles** with least privilege principles

### Application Security
- **Container image scanning** in ECR
- **WAF integration** for web application protection
- **GuardDuty** for threat detection
- **AWS Config** for compliance monitoring

## 💰 Cost Optimization Features

### Resource Optimization
- **Auto scaling** to match demand
- **Spot instances** where applicable
- **Right-sized resources** based on requirements
- **gp3 storage** for cost-effective performance

### Monitoring and Alerts
- **Cost allocation tags** for tracking
- **CloudWatch billing alarms**
- **Resource utilization monitoring**
- **Automated scaling policies**

## 📊 Monitoring and Observability

### Application Monitoring
- **CloudWatch metrics** for performance tracking
- **Application logs** centralized in CloudWatch
- **Custom dashboards** for key metrics
- **Alerting** for critical issues

### Infrastructure Monitoring
- **Resource utilization** tracking
- **Database performance** insights
- **Load balancer** health monitoring
- **Auto scaling** activity logs

## 🔄 CI/CD Integration

All deployment methods support integration with:
- **AWS CodePipeline** for automated deployments
- **GitHub Actions** for CI/CD workflows
- **Jenkins** for on-premises CI/CD
- **GitLab CI/CD** for integrated pipelines

## 🆘 Support and Troubleshooting

### Common Issues
1. **Permission errors** - Check IAM policies and roles
2. **Network connectivity** - Verify security groups and routes
3. **Image pull failures** - Ensure ECR authentication and permissions
4. **Health check failures** - Verify application endpoints and responses

### Getting Help
- Check the deployment-specific README files
- Review CloudWatch logs for detailed error messages
- Use AWS CLI commands provided in troubleshooting sections
- Refer to the comprehensive troubleshooting guide in `aws_run_steps.md`

## 📚 Additional Resources

- **Main Deployment Guide**: `../aws_run_steps.md`
- **AWS Well-Architected Framework**: [AWS Documentation](https://aws.amazon.com/architecture/well-architected/)
- **AWS Cost Optimization**: [AWS Cost Management](https://aws.amazon.com/aws-cost-management/)
- **AWS Security Best Practices**: [AWS Security Center](https://aws.amazon.com/security/)

---

**Created**: 2025-01-13  
**Version**: 1.0  
**Supports**: Elastic Beanstalk, EKS, ECS Fargate deployments

### 1. Elastic Beanstalk (Recommended for beginners)
```bash
cd elastic-beanstalk
./deploy-eb.sh
```

### 2. Amazon EKS (Recommended for production)
```bash
cd eks
./deploy-eks.sh
```

### 3. ECS with Fargate (Custom architecture)
```bash
cd ecs-fargate
./deploy-ecs.sh
```

## ⚡ Prerequisites

1. AWS CLI configured with appropriate permissions
2. Docker installed locally
3. For EKS: kubectl and eksctl installed
4. For EKS: Helm 3.x installed

## 🔧 Configuration

Before deploying, update the configuration files:

1. **AWS Account Settings**: Update account ID and region in scripts
2. **Domain Names**: Update domain names in ingress configurations
3. **Security**: Review security group rules and IAM policies
4. **Resources**: Adjust instance types and scaling parameters

## 💰 Cost Considerations

- **Development**: Use t3.micro instances and minimal resources
- **Staging**: Use t3.small instances with basic monitoring
- **Production**: Use appropriate instance types with full monitoring

## 📊 Monitoring

All deployments include:
- CloudWatch metrics and logs
- Health checks and alarms
- Auto-scaling configurations
- Performance monitoring dashboards
