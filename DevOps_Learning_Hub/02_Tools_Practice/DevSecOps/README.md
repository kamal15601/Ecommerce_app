# 🛡️ DevSecOps: Security in the DevOps Pipeline

Welcome to the DevSecOps section of the DevOps Learning Hub! This guide focuses on integrating security throughout the DevOps lifecycle.

## 📋 Table of Contents

1. [Introduction to DevSecOps](#introduction-to-devsecops)
2. [Security Principles in DevOps](#security-principles-in-devops)
3. [Security in the CI/CD Pipeline](#security-in-the-cicd-pipeline)
4. [Infrastructure Security](#infrastructure-security)
5. [Container Security](#container-security)
6. [Kubernetes Security](#kubernetes-security)
7. [Application Security](#application-security)
8. [Compliance as Code](#compliance-as-code)
9. [Security Monitoring and Response](#security-monitoring-and-response)
10. [Hands-On Labs](#hands-on-labs)
11. [Tools and Resources](#tools-and-resources)

## Introduction to DevSecOps

DevSecOps integrates security practices within the DevOps process, creating a 'security as code' culture. It embeds security into every part of the development lifecycle, rather than being a separate stage performed before deployment.

### Key Principles

- **Shift Left Security**: Move security earlier in the development process
- **Automate Security**: Implement security checks in automated pipelines
- **Continuous Security**: Make security a continuous process
- **Security as Code**: Define security policies as code
- **Collaboration**: Foster cooperation between development, operations, and security teams

### The DevSecOps Lifecycle

1. **Plan**: Include security requirements in planning
2. **Code**: Follow secure coding practices
3. **Build**: Static application security testing (SAST)
4. **Test**: Dynamic application security testing (DAST)
5. **Deploy**: Infrastructure security validation
6. **Operate**: Runtime application protection
7. **Monitor**: Security monitoring and incident response

## Security Principles in DevOps

### Defense in Depth

Implement multiple layers of security controls throughout the application, infrastructure, and network to protect against various attack vectors.

### Least Privilege

Grant only the permissions necessary for a user, process, or system to perform its required functions, limiting potential damage from compromise.

### Zero Trust Architecture

Treat all network traffic as untrusted, requiring verification for all users, devices, and network flows, regardless of location.

### Immutable Infrastructure

Treat infrastructure as immutable (unchangeable) and rebuild instead of updating, ensuring consistent, known-good states.

### Secure Defaults

Configure systems with secure defaults to minimize the attack surface and reduce the risk of misconfiguration.

## Security in the CI/CD Pipeline

### Security Scanning Tools

Integrate security scanning tools into your CI/CD pipeline:

- **SAST (Static Application Security Testing)**: Analyze source code for security vulnerabilities
- **DAST (Dynamic Application Security Testing)**: Test running applications for vulnerabilities
- **IAST (Interactive Application Security Testing)**: Combine SAST and DAST for real-time analysis
- **SCA (Software Composition Analysis)**: Identify vulnerabilities in third-party dependencies
- **Container Scanning**: Detect vulnerabilities in container images
- **Infrastructure as Code Scanning**: Identify security issues in infrastructure definitions

### Example Jenkins Pipeline with Security Integration

```groovy
pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Dependencies') {
            steps {
                sh 'npm ci'
            }
        }
        
        stage('SAST') {
            steps {
                sh 'npm run lint'
                sh 'sonar-scanner'
            }
        }
        
        stage('SCA') {
            steps {
                sh 'npm audit --audit-level=high'
                sh 'snyk test'
            }
        }
        
        stage('Build') {
            steps {
                sh 'npm run build'
                sh 'docker build -t myapp:${BUILD_NUMBER} .'
            }
        }
        
        stage('Container Scan') {
            steps {
                sh 'trivy image myapp:${BUILD_NUMBER}'
                sh 'docker scout cves myapp:${BUILD_NUMBER}'
            }
        }
        
        stage('DAST') {
            steps {
                sh 'docker run -d -p 3000:3000 --name myapp myapp:${BUILD_NUMBER}'
                sh 'zap-cli quick-scan --self-contained --start-options "-config api.disablekey=true" http://localhost:3000'
                sh 'docker stop myapp && docker rm myapp'
            }
        }
        
        stage('IaC Scan') {
            steps {
                sh 'checkov -d terraform/'
                sh 'tfsec terraform/'
            }
        }
        
        stage('Deploy') {
            when {
                branch 'main'
            }
            steps {
                sh 'docker tag myapp:${BUILD_NUMBER} myregistry/myapp:latest'
                sh 'docker push myregistry/myapp:latest'
            }
        }
    }
    
    post {
        always {
            archiveArtifacts artifacts: 'reports/**/*', allowEmptyArchive: true
            junit 'reports/junit/*.xml'
        }
    }
}
```

### GitHub Actions Workflow with Security Scanning

```yaml
name: CI/CD with Security

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          
      - name: Install dependencies
        run: npm ci
        
      - name: Run SAST
        run: |
          npm run lint
          npm install -g sonarqube-scanner
          sonar-scanner
          
      - name: Run SCA
        run: |
          npm audit --audit-level=high
          npm install -g snyk
          snyk test
          
      - name: Build application
        run: |
          npm run build
          docker build -t myapp:${{ github.sha }} .
          
      - name: Scan container image
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: 'myapp:${{ github.sha }}'
          format: 'sarif'
          output: 'trivy-results.sarif'
          
      - name: Upload Trivy scan results
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: 'trivy-results.sarif'
          
      - name: Scan IaC
        run: |
          pip install checkov
          checkov -d terraform/
          
      - name: Deploy
        if: github.ref == 'refs/heads/main'
        run: |
          docker tag myapp:${{ github.sha }} myregistry/myapp:latest
          echo ${{ secrets.DOCKER_PASSWORD }} | docker login -u ${{ secrets.DOCKER_USERNAME }} --password-stdin
          docker push myregistry/myapp:latest
```

## Infrastructure Security

### Secure Infrastructure as Code

Implement security best practices for infrastructure code:

- Use modules from trusted sources
- Keep infrastructure code in version control
- Enforce peer reviews for infrastructure changes
- Implement policy as code to validate infrastructure

### AWS Infrastructure Security

```terraform
# Example of secure AWS infrastructure with Terraform

provider "aws" {
  region = "us-west-2"
}

# Create a VPC with private and public subnets
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "3.14.0"

  name = "secure-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
  
  # VPC Flow Logs for network monitoring
  enable_flow_log = true
  flow_log_destination_type = "cloud-watch-logs"
  
  # DNS support
  enable_dns_hostnames = true
  enable_dns_support   = true
}

# Security group with least privilege
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Security group for web servers"
  vpc_id      = module.vpc.vpc_id

  # Allow HTTP from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP"
  }

  # Allow HTTPS from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS"
  }
  
  # Allow SSH only from specific IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Allow SSH from VPN only"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "web-sg"
  }
}

# S3 bucket with encryption
resource "aws_s3_bucket" "app_data" {
  bucket = "my-secure-app-data"
  
  tags = {
    Name = "AppData"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app_data" {
  bucket = aws_s3_bucket.app_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "app_data" {
  bucket = aws_s3_bucket.app_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

### Azure Infrastructure Security

```terraform
# Example of secure Azure infrastructure with Terraform

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "secure-resources"
  location = "East US"
}

# Virtual Network with NSGs
resource "azurerm_virtual_network" "example" {
  name                = "secure-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.Sql", "Microsoft.Storage"]
}

resource "azurerm_network_security_group" "example" {
  name                = "secure-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Attach NSG to subnet
resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.example.id
  network_security_group_id = azurerm_network_security_group.example.id
}

# Storage account with encryption
resource "azurerm_storage_account" "example" {
  name                     = "securestorage"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  min_tls_version          = "TLS1_2"
  
  # Enable blob encryption
  blob_properties {
    versioning_enabled = true
    
    container_delete_retention_policy {
      days = 7
    }
  }

  # Limit network access
  network_rules {
    default_action             = "Deny"
    ip_rules                   = ["203.0.113.0/24"]
    virtual_network_subnet_ids = [azurerm_subnet.example.id]
  }
}

# Key Vault with RBAC
resource "azurerm_key_vault" "example" {
  name                        = "secure-keyvault"
  location                    = azurerm_resource_group.example.location
  resource_group_name         = azurerm_resource_group.example.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true
  enable_rbac_authorization   = true
  sku_name                    = "standard"
  
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = ["203.0.113.0/24"]
    virtual_network_subnet_ids = [azurerm_subnet.example.id]
  }
}
```

## Container Security

### Secure Docker Images

Best practices for container security:

1. **Use minimal base images** (Alpine, distroless, scratch)
2. **Scan images for vulnerabilities**
3. **Don't run as root**
4. **Remove unnecessary tools and dependencies**
5. **Set filesystem to read-only where possible**
6. **Use multi-stage builds**
7. **Sign and verify images**

### Example Secure Dockerfile

```dockerfile
# Start with a builder stage
FROM node:18-alpine AS builder

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci

# Copy source and build
COPY . .
RUN npm run build

# Create a smaller production image
FROM node:18-alpine

# Create a non-root user
RUN addgroup -g 1001 appgroup && \
    adduser -u 1001 -G appgroup -s /bin/sh -D appuser

# Set working directory and switch to non-root user
WORKDIR /app
USER appuser

# Copy only what's needed from the builder stage
COPY --from=builder --chown=appuser:appgroup /app/package*.json ./
COPY --from=builder --chown=appuser:appgroup /app/node_modules ./node_modules
COPY --from=builder --chown=appuser:appgroup /app/dist ./dist

# Set environment variables
ENV NODE_ENV=production \
    PORT=3000

# Expose port
EXPOSE 3000

# Use a read-only filesystem where possible
RUN mkdir -p /app/logs && chown -R appuser:appgroup /app/logs
VOLUME ["/app/logs"]

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q -O - http://localhost:3000/health || exit 1

# Define the command to run
CMD ["node", "dist/server.js"]
```

### Container Security Tools

1. **Trivy**: Vulnerability scanner for containers
2. **Docker Scout**: Container analysis
3. **Clair**: Static analysis for vulnerabilities
4. **Anchore Engine**: Deep container inspection
5. **Docker Bench for Security**: Docker host security checking
6. **Falco**: Runtime security monitoring

## Kubernetes Security

### Kubernetes Security Principles

1. **Secure the API server**: Use strong authentication and authorization
2. **Secure etcd**: Encrypt etcd data and restrict access
3. **Use namespaces for isolation**: Separate workloads by namespace
4. **Implement RBAC**: Define granular roles and permissions
5. **Use network policies**: Restrict pod-to-pod communication
6. **Secure pod configurations**: Set security contexts and use PodSecurityPolicies/Standards
7. **Scan images**: Implement image scanning in the CI/CD pipeline
8. **Secure secrets management**: Use dedicated secrets management tools

### Example Secure Kubernetes Manifests

```yaml
# Example of a secure pod configuration
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    image: myapp:1.0.0
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
        - ALL
    resources:
      limits:
        cpu: "500m"
        memory: "512Mi"
      requests:
        cpu: "100m"
        memory: "128Mi"
    livenessProbe:
      httpGet:
        path: /health
        port: 8080
      initialDelaySeconds: 30
      periodSeconds: 10
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 5
```

```yaml
# Example of a network policy
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-specific-ingress
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          purpose: frontend
    - podSelector:
        matchLabels:
          app: api-gateway
    ports:
    - protocol: TCP
      port: 80
```

```yaml
# Example of RBAC configuration
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: production
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: production
subjects:
- kind: User
  name: jane
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

### Kubernetes Security Tools

1. **Kubesec**: Security risk analysis for Kubernetes resources
2. **Kube-bench**: CIS Kubernetes Benchmark checking
3. **Kube-hunter**: Kubernetes vulnerabilities hunting
4. **Polaris**: Best practices validation
5. **Falco**: Runtime security monitoring
6. **OPA Gatekeeper**: Policy enforcement
7. **Kyverno**: Policy management

## Application Security

### Secure Coding Practices

1. **Input validation**: Validate all user inputs
2. **Output encoding**: Encode outputs to prevent XSS
3. **Parameterized queries**: Prevent SQL injection
4. **Authentication**: Implement strong authentication
5. **Authorization**: Verify user permissions
6. **Session management**: Secure session handling
7. **Secrets management**: Secure storage of secrets
8. **Dependency management**: Use secure dependencies
9. **Error handling**: Implement secure error handling
10. **Logging**: Implement secure logging

### OWASP Top 10 Mitigation

1. **Broken Access Control**: Implement proper authorization
2. **Cryptographic Failures**: Use strong encryption
3. **Injection**: Use parameterized queries
4. **Insecure Design**: Security by design principles
5. **Security Misconfiguration**: Harden configurations
6. **Vulnerable and Outdated Components**: Regular dependency updates
7. **Identification and Authentication Failures**: Implement MFA
8. **Software and Data Integrity Failures**: Verify integrity
9. **Security Logging and Monitoring Failures**: Implement comprehensive logging
10. **Server-Side Request Forgery**: Validate and filter all client-supplied input data

### Secrets Management

Options for secure secrets management:

- **HashiCorp Vault**: Secrets management with dynamic secrets
- **AWS Secrets Manager**: AWS-integrated secrets management
- **Azure Key Vault**: Azure-integrated key and secret management
- **Google Secret Manager**: GCP-integrated secrets management
- **Kubernetes Secrets**: Basic Kubernetes secrets (preferably encrypted)
- **External Secrets Operator**: Kubernetes integration with external secret stores

## Compliance as Code

### Policy as Code

Define and enforce compliance policies as code:

- **OPA (Open Policy Agent)**: Policy engine for cloud-native environments
- **Conftest**: Testing tool for configuration files
- **HashiCorp Sentinel**: Policy as code framework
- **AWS Config Rules**: AWS compliance rules
- **Azure Policy**: Azure compliance rules
- **Kyverno**: Kubernetes-native policy management

### Example OPA Policy

```rego
# Policy to ensure all pods have resource limits
package kubernetes.admission

deny[msg] {
  input.request.kind.kind == "Pod"
  container := input.request.object.spec.containers[_]
  not container.resources.limits
  msg := sprintf("Container %s has no resource limits", [container.name])
}

# Policy to ensure no privileged containers
deny[msg] {
  input.request.kind.kind == "Pod"
  container := input.request.object.spec.containers[_]
  container.securityContext.privileged
  msg := sprintf("Privileged container %s is not allowed", [container.name])
}

# Policy to ensure no default namespaces
deny[msg] {
  input.request.kind.kind == "Deployment"
  input.request.object.metadata.namespace == "default"
  msg := "Deployments to the default namespace are not allowed"
}
```

### Compliance Frameworks

Implement controls for common compliance frameworks:

- **CIS Benchmarks**: System hardening standards
- **NIST 800-53**: Security and privacy controls
- **SOC 2**: Trust services criteria
- **HIPAA**: Health information security
- **PCI DSS**: Payment card security
- **GDPR**: Data protection regulations

## Security Monitoring and Response

### Security Monitoring

Components of a comprehensive security monitoring strategy:

- **SIEM (Security Information and Event Management)**: Centralized log analysis
- **IDS/IPS (Intrusion Detection/Prevention System)**: Network traffic analysis
- **File Integrity Monitoring**: Detect unauthorized changes
- **Container Runtime Security**: Monitor container behavior
- **Vulnerability Management**: Continuous vulnerability scanning
- **Cloud Security Posture Management**: Cloud configuration monitoring

### Incident Response

Steps in the incident response process:

1. **Preparation**: Establish incident response plans and capabilities
2. **Identification**: Detect and analyze potential security incidents
3. **Containment**: Isolate affected systems to prevent further damage
4. **Eradication**: Remove the cause of the incident
5. **Recovery**: Restore systems to normal operation
6. **Lessons Learned**: Analyze the incident and improve defenses

### Automated Response

Implement automated responses to security events:

- **Auto-scaling**: Scale resources in response to DoS attacks
- **Quarantine**: Isolate compromised resources
- **Rotation**: Automatically rotate compromised credentials
- **Remediation**: Automatically fix common misconfigurations
- **Blocking**: Automatically block malicious IP addresses

## Hands-On Labs

### Lab 1: Building a Secure CI/CD Pipeline

In this lab, you'll set up a complete CI/CD pipeline with security integration:

1. Set up a Jenkins or GitHub Actions pipeline
2. Integrate SAST tools (SonarQube, ESLint)
3. Implement SCA scanning (OWASP Dependency Check, Snyk)
4. Configure container scanning (Trivy, Docker Scout)
5. Implement IaC scanning (Checkov, tfsec)
6. Set up DAST testing (OWASP ZAP)
7. Implement compliance checking (OPA, Conftest)

### Lab 2: Kubernetes Security Hardening

In this lab, you'll implement security best practices for a Kubernetes cluster:

1. Secure the Kubernetes API server
2. Implement RBAC for different user roles
3. Set up network policies for pod isolation
4. Configure secure pod security contexts
5. Implement secret management with HashiCorp Vault
6. Set up runtime security monitoring with Falco
7. Implement policy enforcement with Gatekeeper

### Lab 3: Building a Secure Cloud Infrastructure

In this lab, you'll create a secure infrastructure on AWS or Azure:

1. Set up a secure network architecture with private subnets
2. Implement secure IAM policies and roles
3. Configure encryption for data at rest and in transit
4. Set up secure storage with access controls
5. Implement security monitoring and logging
6. Set up automated compliance checking
7. Create an incident response plan

## Tools and Resources

### Security Scanning Tools

- **SonarQube**: Static code analysis
- **Snyk**: Dependencies and container scanning
- **OWASP ZAP**: Dynamic application security testing
- **Trivy**: Container vulnerability scanning
- **Checkov**: Infrastructure as code scanning
- **Kube-bench**: Kubernetes security benchmarking
- **Terrascan**: IaC security scanning

### Security Monitoring Tools

- **Falco**: Container runtime security
- **Wazuh**: Security monitoring platform
- **Prometheus + Grafana**: Metrics monitoring
- **ELK Stack**: Log collection and analysis
- **Sysdig Secure**: Container security platform
- **Prisma Cloud**: Cloud security posture management
- **AWS GuardDuty**: Threat detection service

### Recommended Reading

- **"DevSecOps: A leader's guide to producing secure software without compromising flow, feedback, and continuous improvement"** by Robert Wood
- **"Practical Cloud Security: A Guide for Secure Design and Deployment"** by Chris Dotson
- **"Securing DevOps: Security in the Cloud"** by Julien Vehent
- **"Container Security: Fundamental Technology Concepts that Protect Containerized Applications"** by Liz Rice
- **"Kubernetes Security: Operating Kubernetes Clusters and Applications Safely"** by Liz Rice and Michael Hausenblas

### Training and Certification

- **Certified Kubernetes Security Specialist (CKS)**
- **AWS Certified Security – Specialty**
- **Microsoft Certified: Azure Security Engineer Associate**
- **Certified Cloud Security Professional (CCSP)**
- **SANS SEC540: Cloud Security and DevSecOps Automation**

---

This guide provides a comprehensive introduction to DevSecOps principles and practices. By integrating security throughout the DevOps lifecycle, you can build more secure applications and infrastructure while maintaining the speed and agility of DevOps.
