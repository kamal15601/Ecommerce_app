# Production-Ready E-commerce Application with DevOps 🛒

## Overview
This section contains a complete, production-ready e-commerce application that demonstrates all major DevOps tools and practices. The application is designed as a real-world example showcasing microservices architecture, cloud-native deployment, monitoring, security, and compliance. This project follows industry best practices updated for 2025.

## Table of Contents
- [Application Architecture](#application-architecture)
- [Technology Stack](#technology-stack)
- [DevOps Implementation](#devops-implementation)
- [Getting Started](#getting-started)
- [Deployment Guide](#deployment-guide)
- [Monitoring Setup](#monitoring-setup)
- [Security Implementation](#security-implementation)
- [Compliance & Governance](#compliance--governance)
- [Troubleshooting](#troubleshooting)

## Application Architecture

### Microservices Overview
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   API Gateway   │    │   User Service  │
│   (React)       │────│   (Kong/Nginx)  │────│   (Node.js)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                               │
           ┌───────────────────┼───────────────────┐
           │                   │                   │
  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
  │   Product       │  │   Order         │  │   Payment       │
  │   Service       │  │   Service       │  │   Service       │
  │   (Python)      │  │   (Java)        │  │   (Go)          │
  └─────────────────┘  └─────────────────┘  └─────────────────┘
           │                   │                   │
  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
  │   Product DB    │  │   Order DB      │  │   Payment DB    │
  │   (PostgreSQL)  │  │   (MongoDB)     │  │   (PostgreSQL)  │
  └─────────────────┘  └─────────────────┘  └─────────────────┘
```

### Infrastructure Components
- **Load Balancer**: AWS ALB / Azure Load Balancer / GCP Load Balancing
- **Container Registry**: Amazon ECR / Azure ACR / Google Artifact Registry
- **Orchestration**: Kubernetes (EKS/AKS/GKE)
- **Service Mesh**: Istio
- **Message Queue**: Redis / RabbitMQ
- **Caching**: Redis
- **CDN**: CloudFront / Azure CDN / Cloud CDN
- **DNS**: Route 53 / Azure DNS / Cloud DNS

## Technology Stack

### Frontend
- **Framework**: React 18 with TypeScript
- **State Management**: Redux Toolkit
- **UI Components**: Material-UI
- **Testing**: Jest, React Testing Library
- **Build Tool**: Vite

### Backend Services
- **User Service**: Node.js with Express
- **Product Service**: Python with FastAPI
- **Order Service**: Java with Spring Boot
- **Payment Service**: Go with Gin
- **Notification Service**: Node.js with Socket.io

### Databases
- **User Data**: PostgreSQL
- **Product Catalog**: PostgreSQL with Redis cache
- **Orders**: MongoDB
- **Payments**: PostgreSQL (encrypted)
- **Session Store**: Redis

### DevOps Tools
- **CI/CD**: GitHub Actions, Jenkins, Azure DevOps
- **IaC**: Terraform, Helm, Bicep
- **Configuration**: Ansible
- **Monitoring**: Prometheus, Grafana, Azure Monitor
- **Logging**: ELK Stack, Azure Log Analytics
- **Security**: Vault, Trivy, OWASP ZAP, Azure Defender
- **GitOps**: ArgoCD, Flux

## DevOps Implementation

### 1. Source Code Management
```bash
ecommerce-app/
├── frontend/                 # React frontend
├── services/
│   ├── user-service/        # Node.js microservice
│   ├── product-service/     # Python microservice
│   ├── order-service/       # Java microservice
│   ├── payment-service/     # Go microservice
│   └── notification-service/
├── infrastructure/
│   ├── terraform/           # Infrastructure as Code
│   ├── kubernetes/          # K8s manifests
│   ├── helm/               # Helm charts
│   └── ansible/            # Configuration management
├── ci-cd/
│   ├── github-actions/     # CI/CD workflows
│   ├── jenkins/           # Jenkinsfile pipelines
│   └── azure-devops/      # Azure Pipelines
├── monitoring/
│   ├── prometheus/         # Monitoring configs
│   ├── grafana/           # Dashboards
│   └── alerts/            # Alert rules
└── docs/                  # Documentation
```

### 2. Containerization
Each service includes optimized Dockerfiles:

**Example: User Service Dockerfile**
```dockerfile
# Multi-stage build for Node.js service
FROM node:18-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

FROM node:18-alpine AS runtime

# Create non-root user
RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001

WORKDIR /app

# Copy built application
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --chown=nodejs:nodejs . .

# Security: Run as non-root user
USER nodejs

EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

CMD ["npm", "start"]
```

### 3. Kubernetes Deployment
**User Service Deployment**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
  labels:
    app: user-service
    version: v1
spec:
  replicas: 3
  selector:
    matchLabels:
      app: user-service
  template:
    metadata:
      labels:
        app: user-service
        version: v1
    spec:
      serviceAccountName: user-service
      containers:
      - name: user-service
        image: your-registry/user-service:latest
        ports:
        - containerPort: 3000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: database-secret
              key: url
        - name: REDIS_URL
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: redis-url
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
        securityContext:
          allowPrivilegeEscalation: false
          runAsNonRoot: true
          runAsUser: 1001
```

### 4. Helm Charts
**Chart structure**:
```bash
helm-charts/
├── ecommerce/
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── values-dev.yaml
│   ├── values-staging.yaml
│   ├── values-prod.yaml
│   └── templates/
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── ingress.yaml
│       ├── configmap.yaml
│       ├── secret.yaml
│       └── hpa.yaml
```

### 5. CI/CD Pipelines
We implement multiple CI/CD solutions to demonstrate different approaches:

#### GitHub Actions Workflow
```yaml
name: E-commerce CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        service: [user-service, product-service, order-service, payment-service]
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Node.js
      if: contains(matrix.service, 'user-service')
      uses: actions/setup-node@v4
      with:
        node-version: '18'
        cache: 'npm'
        cache-dependency-path: services/${{ matrix.service }}/package-lock.json
    
    - name: Setup Python
      if: contains(matrix.service, 'product-service')
      uses: actions/setup-python@v4
      with:
        python-version: '3.11'
        cache: 'pip'
    
    - name: Setup Java
      if: contains(matrix.service, 'order-service')
      uses: actions/setup-java@v4
      with:
        java-version: '17'
        distribution: 'temurin'
        cache: 'maven'
    
    - name: Setup Go
      if: contains(matrix.service, 'payment-service')
      uses: actions/setup-go@v4
      with:
        go-version: '1.21'
        cache-dependency-path: services/${{ matrix.service }}/go.sum
    
    - name: Run tests
      run: |
        cd services/${{ matrix.service }}
        make test
    
    - name: Run security scan
      run: |
        cd services/${{ matrix.service }}
        make security-scan
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        file: services/${{ matrix.service }}/coverage.xml

  build:
    needs: test
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Docker Buildx
      uses: docker/setup-buildx-action@v3
    
    - name: Login to Container Registry
      uses: docker/login-action@v3
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
    
    - name: Build and push images
      run: |
        services=("user-service" "product-service" "order-service" "payment-service")
        for service in "${services[@]}"; do
          docker buildx build \
            --platform linux/amd64,linux/arm64 \
            --push \
            --tag ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}/$service:${{ github.sha }} \
            --tag ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}/$service:latest \
            services/$service
        done

  deploy-staging:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/develop'
    environment: staging
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        role-to-assume: ${{ secrets.AWS_ROLE_TO_ASSUME }}
        aws-region: us-west-2
    
    - name: Update kubeconfig
      run: |
        aws eks update-kubeconfig --name ecommerce-staging --region us-west-2
    
    - name: Deploy with Helm
      run: |
        helm upgrade --install ecommerce-staging ./helm-charts/ecommerce \
          --namespace staging \
          --create-namespace \
          --values ./helm-charts/ecommerce/values-staging.yaml \
          --set image.tag=${{ github.sha }}
    
    - name: Run smoke tests
      run: |
        kubectl wait --for=condition=ready pod -l app=user-service -n staging --timeout=300s
        ./scripts/smoke-tests.sh staging

  deploy-production:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment: production
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Deploy to production
      run: |
        # GitOps approach - update manifest repository
        git clone https://${{ secrets.GITOPS_TOKEN }}@github.com/your-org/k8s-manifests.git
        cd k8s-manifests
        
        # Update image tags
        yq e '.spec.template.spec.containers[0].image = "${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}/user-service:${{ github.sha }}"' \
          -i production/user-service-deployment.yaml
        
        git add .
        git commit -m "Update production images to ${{ github.sha }}"
        git push
```

#### Azure DevOps Pipeline
```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
    - main
    - develop
    - feature/*
  paths:
    exclude:
    - README.md
    - docs/*

variables:
  buildConfiguration: 'Release'
  vmImageName: 'ubuntu-latest'
  containerRegistry: 'ecommerceregistry.azurecr.io'
  backendImageName: 'ecommerce-backend'
  frontendImageName: 'ecommerce-frontend'

stages:
- stage: Build
  displayName: 'Build Application'
  jobs:
  - job: BuildBackend
    displayName: 'Build Backend'
    pool:
      vmImage: $(vmImageName)
    steps:
    - task: UsePythonVersion@0
      inputs:
        versionSpec: '3.9'
        addToPath: true
    
    - script: |
        python -m pip install --upgrade pip
        pip install -r services/product-service/requirements.txt
        pip install pytest pytest-cov pylint
      displayName: 'Install dependencies'
    
    - script: |
        cd services/product-service
        pylint --disable=C0111 app.py
        pytest --cov=. --cov-report=xml
      displayName: 'Run tests'
    
    - task: Docker@2
      inputs:
        containerRegistry: 'ecommerceAcr'
        repository: '$(backendImageName)'
        command: 'buildAndPush'
        Dockerfile: 'services/product-service/Dockerfile'
        tags: |
          $(Build.BuildId)
          latest
  
  - job: BuildFrontend
    displayName: 'Build Frontend'
    pool:
      vmImage: $(vmImageName)
    steps:
    - task: NodeTool@0
      inputs:
        versionSpec: '16.x'
    
    - script: |
        cd frontend
        npm install
        npm run build
      displayName: 'Build frontend'
    
    - task: Docker@2
      inputs:
        containerRegistry: 'ecommerceAcr'
        repository: '$(frontendImageName)'
        command: 'buildAndPush'
        Dockerfile: 'frontend/Dockerfile'
        tags: |
          $(Build.BuildId)
          latest

- stage: DeployToDev
  displayName: 'Deploy to Development'
  dependsOn: Build
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/develop'))
  jobs:
  - deployment: DeployToDev
    displayName: 'Deploy to Dev environment'
    environment: 'Development'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: HelmDeploy@0
            displayName: 'Deploy to AKS'
            inputs:
              connectionType: 'Azure Resource Manager'
              azureSubscriptionEndpoint: 'ecommerce-dev-connection'
              azureResourceGroup: 'ecommerce-dev-rg'
              kubernetesCluster: 'ecommerce-dev-aks'
              namespace: 'ecommerce-dev'
              command: 'upgrade'
              chartType: 'FilePath'
              chartPath: './helm-charts/ecommerce'
              releaseName: 'ecommerce-dev'
              valueFile: './helm-charts/ecommerce/values-dev.yaml'
              overrideValues: 'image.tag=$(Build.BuildId)'

- stage: DeployToProduction
  displayName: 'Deploy to Production'
  dependsOn: Build
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
  jobs:
  - deployment: DeployToProduction
    displayName: 'Deploy to Production environment'
    environment: 'Production'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: HelmDeploy@0
            displayName: 'Deploy to AKS'
            inputs:
              connectionType: 'Azure Resource Manager'
              azureSubscriptionEndpoint: 'ecommerce-prod-connection'
              azureResourceGroup: 'ecommerce-prod-rg'
              kubernetesCluster: 'ecommerce-prod-aks'
              namespace: 'ecommerce-prod'
              command: 'upgrade'
              chartType: 'FilePath'
              chartPath: './helm-charts/ecommerce'
              releaseName: 'ecommerce-prod'
              valueFile: './helm-charts/ecommerce/values-prod.yaml'
              overrideValues: 'image.tag=$(Build.BuildId)'
```

## Monitoring Setup

### 1. Prometheus Configuration
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "rules/*.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

scrape_configs:
  - job_name: 'kubernetes-apiservers'
    kubernetes_sd_configs:
    - role: endpoints
    scheme: https
    tls_config:
      ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
    relabel_configs:
    - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
      action: keep
      regex: default;kubernetes;https

  - job_name: 'ecommerce-services'
    kubernetes_sd_configs:
    - role: pod
    relabel_configs:
    - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
      action: keep
      regex: true
    - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
      action: replace
      target_label: __metrics_path__
      regex: (.+)
```

### 2. Grafana Dashboards
**Application Performance Dashboard**:
- Request rate and latency percentiles
- Error rate and success rate
- Database connection pools
- Cache hit rates
- Business metrics (orders, revenue)

**Infrastructure Dashboard**:
- CPU and memory utilization
- Network traffic
- Disk I/O and storage usage
- Kubernetes cluster health

### 3. Alert Rules
```yaml
groups:
- name: ecommerce-alerts
  rules:
  - alert: HighErrorRate
    expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.1
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "High error rate detected"
      description: "Error rate is {{ $value }} for {{ $labels.service }}"

  - alert: DatabaseConnectionHigh
    expr: sum(db_connections_active) / sum(db_connections_max) > 0.8
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Database connection pool utilization high"
```

## Security Implementation

### 1. Container Security
```yaml
# Security Context
securityContext:
  allowPrivilegeEscalation: false
  runAsNonRoot: true
  runAsUser: 1001
  capabilities:
    drop:
    - ALL
  readOnlyRootFilesystem: true
```

### 2. Network Policies
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: user-service-policy
spec:
  podSelector:
    matchLabels:
      app: user-service
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: api-gateway
    ports:
    - protocol: TCP
      port: 3000
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - protocol: TCP
      port: 5432
```

### 3. Secret Management
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: database-secret
type: Opaque
data:
  url: <base64-encoded-database-url>
  username: <base64-encoded-username>
  password: <base64-encoded-password>
```

### 4. RBAC Configuration
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: ecommerce
  name: service-reader
rules:
- apiGroups: [""]
  resources: ["pods", "services"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: service-reader-binding
  namespace: ecommerce
subjects:
- kind: ServiceAccount
  name: user-service
  namespace: ecommerce
roleRef:
  kind: Role
  name: service-reader
  apiGroup: rbac.authorization.k8s.io
```

## Infrastructure as Code

### 1. Terraform Infrastructure
```hcl
# EKS Cluster
module "eks" {
  source = "terraform-aws-modules/eks/aws"
  
  cluster_name    = "ecommerce-${var.environment}"
  cluster_version = "1.28"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  
  eks_managed_node_groups = {
    main = {
      desired_size = 3
      max_size     = 10
      min_size     = 1
      
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      
      k8s_labels = {
        Environment = var.environment
        Application = "ecommerce"
      }
    }
  }
  
  tags = local.common_tags
}

# RDS Database
module "database" {
  source = "terraform-aws-modules/rds/aws"
  
  identifier = "ecommerce-${var.environment}"
  
  engine         = "postgres"
  engine_version = "15.3"
  instance_class = "db.t3.micro"
  
  allocated_storage     = 20
  max_allocated_storage = 100
  
  db_name  = "ecommerce"
  username = var.db_username
  password = var.db_password
  
  vpc_security_group_ids = [aws_security_group.database.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  deletion_protection = var.environment == "prod" ? true : false
  
  tags = local.common_tags
}

# Redis Cache
resource "aws_elasticache_subnet_group" "main" {
  name       = "ecommerce-${var.environment}"
  subnet_ids = module.vpc.private_subnets
}

resource "aws_elasticache_replication_group" "main" {
  replication_group_id       = "ecommerce-${var.environment}"
  description                = "Redis cluster for ecommerce application"
  
  node_type            = "cache.t3.micro"
  port                 = 6379
  parameter_group_name = "default.redis7"
  
  num_cache_clusters = 2
  
  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.redis.id]
  
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  
  tags = local.common_tags
}
```

### 2. Ansible Configuration
```yaml
---
- name: Configure Kubernetes cluster
  hosts: localhost
  connection: local
  tasks:
    - name: Install Prometheus operator
      kubernetes.core.helm:
        name: prometheus-operator
        chart_ref: prometheus-community/kube-prometheus-stack
        release_namespace: monitoring
        create_namespace: true
        values:
          grafana:
            adminPassword: "{{ grafana_admin_password }}"
            persistence:
              enabled: true
              size: 10Gi
          prometheus:
            prometheusSpec:
              retention: 30d
              storageSpec:
                volumeClaimTemplate:
                  spec:
                    storageClassName: gp2
                    accessModes: ["ReadWriteOnce"]
                    resources:
                      requests:
                        storage: 50Gi

    - name: Install Istio
      kubernetes.core.helm:
        name: istio-base
        chart_ref: istio/base
        release_namespace: istio-system
        create_namespace: true

    - name: Configure ingress
      kubernetes.core.k8s:
        definition:
          apiVersion: networking.k8s.io/v1
          kind: Ingress
          metadata:
            name: ecommerce-ingress
            namespace: default
            annotations:
              kubernetes.io/ingress.class: nginx
              cert-manager.io/cluster-issuer: letsencrypt-prod
          spec:
            tls:
            - hosts:
              - ecommerce.example.com
              secretName: ecommerce-tls
            rules:
            - host: ecommerce.example.com
              http:
                paths:
                - path: /
                  pathType: Prefix
                  backend:
                    service:
                      name: frontend-service
                      port:
                        number: 80
```

## GitOps with ArgoCD

### 1. Application Configuration
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ecommerce-production
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/k8s-manifests
    targetRevision: HEAD
    path: production/ecommerce
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

### 2. Multi-Environment Setup
```bash
k8s-manifests/
├── base/
│   ├── user-service/
│   ├── product-service/
│   ├── order-service/
│   └── payment-service/
├── environments/
│   ├── development/
│   ├── staging/
│   └── production/
└── argocd/
    ├── applications/
    └── projects/
```

## Performance Optimization

### 1. Horizontal Pod Autoscaler
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: user-service-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: user-service
  minReplicas: 2
  maxReplicas: 10
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
```

### 2. Vertical Pod Autoscaler
```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: user-service-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: user-service
  updatePolicy:
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
    - containerName: user-service
      maxAllowed:
        cpu: 1
        memory: 2Gi
      minAllowed:
        cpu: 100m
        memory: 128Mi
```

## Getting Started

### Prerequisites
- Docker and Docker Compose
- Kubernetes cluster (local or cloud)
- Helm 3.x
- Terraform
- kubectl configured

### Local Development Setup
```bash
# Clone the repository
git clone https://github.com/your-org/ecommerce-app.git
cd ecommerce-app

# Start local development environment
docker-compose up -d

# Install dependencies for all services
make install-deps

# Run tests
make test

# Start all services
make dev
```

### Cloud Deployment
```bash
# Deploy infrastructure
cd infrastructure/terraform
terraform init
terraform plan -var-file="environments/prod.tfvars"
terraform apply

# Deploy applications
cd ../../
helm upgrade --install ecommerce ./helm-charts/ecommerce \
  --namespace production \
  --create-namespace \
  --values ./helm-charts/ecommerce/values-prod.yaml
```

This comprehensive e-commerce application demonstrates real-world DevOps implementation with production-ready practices, security, monitoring, and automation.
