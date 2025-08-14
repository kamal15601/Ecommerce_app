# 🔬 DevSecOps Pipeline Lab: Integrating Security into CI/CD

This hands-on lab guides you through setting up a complete DevSecOps pipeline, integrating security at every stage of the development lifecycle.

## 🎯 Objectives

By the end of this lab, you will be able to:

1. Implement security scanning in a CI/CD pipeline
2. Integrate static code analysis (SAST)
3. Perform dependency scanning (SCA)
4. Implement container security scanning
5. Validate infrastructure as code (IaC) security
6. Execute dynamic application security testing (DAST)
7. Enforce security policies as code
8. Generate security reports and dashboards

## 🛠️ Prerequisites

- GitHub account
- Docker installed locally
- Basic understanding of CI/CD concepts
- A code editor (VS Code recommended)
- A sample application repository (we'll use a provided example)

## 🧪 Lab Setup

We'll create a complete DevSecOps pipeline using GitHub Actions. Our sample application will be a simple Node.js API with:

- Express.js backend
- MongoDB database
- Docker containerization
- Kubernetes deployment
- Terraform infrastructure

## 📋 Lab Steps

### Step 1: Fork the Sample Repository

Fork the sample repository from GitHub:

```
https://github.com/example/devsecops-pipeline-lab
```

Clone your forked repository:

```bash
git clone https://github.com/yourusername/devsecops-pipeline-lab.git
cd devsecops-pipeline-lab
```

### Step 2: Explore the Sample Application

The repository contains:

- `src/` - Node.js application code
- `Dockerfile` - Container definition
- `kubernetes/` - Kubernetes manifests
- `terraform/` - Infrastructure as code
- `.github/workflows/` - CI/CD pipeline definitions

### Step 3: Setting Up the Initial CI Pipeline

Create a basic GitHub Actions workflow:

```yaml
# .github/workflows/pipeline.yml
name: DevSecOps Pipeline

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          
      - name: Install dependencies
        run: npm ci
        
      - name: Run tests
        run: npm test
        
      - name: Build application
        run: npm run build
        
      - name: Build Docker image
        run: docker build -t devsecops-app:${{ github.sha }} .
```

Commit and push this change:

```bash
git add .github/workflows/pipeline.yml
git commit -m "Add initial CI pipeline"
git push
```

### Step 4: Implementing Static Application Security Testing (SAST)

Add ESLint with security plugins for JavaScript code analysis:

```bash
npm install --save-dev eslint eslint-plugin-security
```

Create an ESLint configuration file:

```js
// .eslintrc.js
module.exports = {
  env: {
    node: true,
    es2021: true,
  },
  extends: [
    'eslint:recommended',
    'plugin:security/recommended',
  ],
  plugins: [
    'security'
  ],
  rules: {
    // Add custom security rules
    'security/detect-eval-with-expression': 'error',
    'security/detect-non-literal-regexp': 'error',
    'security/detect-non-literal-require': 'error',
    'security/detect-object-injection': 'warn',
  },
};
```

Update the package.json with a lint script:

```json
"scripts": {
  "lint": "eslint .",
  "lint:fix": "eslint . --fix"
}
```

Update the GitHub Actions workflow to include SAST:

```yaml
# Add this to the jobs section in pipeline.yml
  sast:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          
      - name: Install dependencies
        run: npm ci
        
      - name: Run ESLint
        run: npm run lint
        
      - name: SonarCloud Scan
        uses: SonarSource/sonarcloud-github-action@master
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

Create a SonarCloud configuration file:

```
# sonar-project.properties
sonar.projectKey=yourusername_devsecops-pipeline-lab
sonar.organization=yourusername

# Source code path
sonar.sources=src
sonar.tests=test

# Exclusions
sonar.exclusions=node_modules/**,coverage/**

# Test coverage reports
sonar.javascript.lcov.reportPaths=coverage/lcov.info
```

Commit and push these changes:

```bash
git add .eslintrc.js package.json .github/workflows/pipeline.yml sonar-project.properties
git commit -m "Add SAST with ESLint and SonarCloud"
git push
```

### Step 5: Software Composition Analysis (SCA)

Add dependency scanning to detect vulnerable packages:

```yaml
# Add this to the jobs section in pipeline.yml
  sca:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          
      - name: Install dependencies
        run: npm ci
        
      - name: Run npm audit
        run: npm audit --audit-level=high
        
      - name: OWASP Dependency Check
        uses: dependency-check/Dependency-Check_Action@main
        with:
          project: 'devsecops-app'
          path: '.'
          format: 'HTML'
          out: 'reports'
          
      - name: Upload dependency check report
        uses: actions/upload-artifact@v3
        with:
          name: dependency-check-report
          path: reports
          
      - name: Snyk Security Scan
        uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --severity-threshold=high
```

Commit and push these changes:

```bash
git add .github/workflows/pipeline.yml
git commit -m "Add SCA with npm audit, OWASP Dependency Check, and Snyk"
git push
```

### Step 6: Container Security Scanning

Add container scanning to detect vulnerabilities in the Docker image:

```yaml
# Add this to the jobs section in pipeline.yml
  container-scan:
    runs-on: ubuntu-latest
    needs: build
    steps:
      - uses: actions/checkout@v3
      
      - name: Build Docker image
        run: docker build -t devsecops-app:${{ github.sha }} .
        
      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: 'devsecops-app:${{ github.sha }}'
          format: 'sarif'
          output: 'trivy-results.sarif'
          severity: 'CRITICAL,HIGH'
          
      - name: Upload Trivy scan results
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: 'trivy-results.sarif'
          
      - name: Docker Scout analysis
        run: |
          docker scout cves devsecops-app:${{ github.sha }} --exit-code
```

Optimize the Dockerfile for security:

```dockerfile
# Use a minimal base image
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

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q -O - http://localhost:3000/health || exit 1

# Define the command to run
CMD ["node", "dist/server.js"]
```

Commit and push these changes:

```bash
git add .github/workflows/pipeline.yml Dockerfile
git commit -m "Add container scanning with Trivy and Docker Scout"
git push
```

### Step 7: Infrastructure as Code (IaC) Security

Add security scanning for Terraform code:

```yaml
# Add this to the jobs section in pipeline.yml
  iac-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run tfsec
        uses: aquasecurity/tfsec-action@v1.0.0
        with:
          soft_fail: true
      
      - name: Run checkov
        uses: bridgecrewio/checkov-action@master
        with:
          directory: terraform/
          framework: terraform
          output_format: sarif
          output_file: checkov-results.sarif
          
      - name: Upload checkov scan results
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: checkov-results.sarif
          
      - name: Run Terraform validate
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.0.0
      - run: |
          cd terraform
          terraform init
          terraform validate
```

Update the Terraform files to follow security best practices:

```hcl
# terraform/main.tf
provider "aws" {
  region = var.region
}

# VPC with private and public subnets
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "3.14.0"

  name = "${var.project_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.region}a", "${var.region}b"]
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
  
  tags = var.tags
}

# Security group with least privilege
resource "aws_security_group" "app_sg" {
  name        = "${var.project_name}-app-sg"
  description = "Security group for application"
  vpc_id      = module.vpc.vpc_id

  # Allow HTTPS from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS"
  }
  
  # Allow only necessary outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = var.tags
}

# S3 bucket with encryption
resource "aws_s3_bucket" "app_data" {
  bucket = "${var.project_name}-data-${random_id.bucket_suffix.hex}"
  
  tags = var.tags
}

resource "random_id" "bucket_suffix" {
  byte_length = 8
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

Commit and push these changes:

```bash
git add .github/workflows/pipeline.yml terraform/
git commit -m "Add IaC security scanning with tfsec, checkov, and Terraform validate"
git push
```

### Step 8: Dynamic Application Security Testing (DAST)

Add DAST to test the running application:

```yaml
# Add this to the jobs section in pipeline.yml
  dast:
    runs-on: ubuntu-latest
    needs: [build, sast, sca, container-scan, iac-scan]
    steps:
      - uses: actions/checkout@v3
      
      - name: Build and run application container
        run: |
          docker build -t devsecops-app:${{ github.sha }} .
          docker run -d -p 3000:3000 --name devsecops-app devsecops-app:${{ github.sha }}
          sleep 10  # Wait for the application to start
      
      - name: Run OWASP ZAP scan
        uses: zaproxy/action-baseline@v0.7.0
        with:
          target: 'http://localhost:3000'
          rules_file_name: '.zap/rules.tsv'
          cmd_options: '-a'
          
      - name: Stop container
        if: always()
        run: docker stop devsecops-app && docker rm devsecops-app
```

Create ZAP rules configuration:

```
# .zap/rules.tsv
10016	IGNORE	Cookie No HttpOnly Flag
10049	IGNORE	Storable and Cacheable Content
10038	IGNORE	Content Security Policy Header Not Set
```

Commit and push these changes:

```bash
git add .github/workflows/pipeline.yml .zap/rules.tsv
git commit -m "Add DAST with OWASP ZAP"
git push
```

### Step 9: Security Policy as Code

Implement policy enforcement with OPA:

```yaml
# Add this to the jobs section in pipeline.yml
  policy-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Check Kubernetes manifests with Conftest
        uses: instrumenta/conftest-action@master
        with:
          files: kubernetes/
          policy: policy/kubernetes/
          
      - name: Check Dockerfile with Conftest
        uses: instrumenta/conftest-action@master
        with:
          files: Dockerfile
          policy: policy/docker/
```

Create OPA policies for Kubernetes:

```rego
# policy/kubernetes/security.rego
package main

deny[msg] {
  input.kind == "Deployment"
  not input.spec.template.spec.securityContext.runAsNonRoot
  msg = "Containers must not run as root"
}

deny[msg] {
  input.kind == "Deployment"
  container := input.spec.template.spec.containers[_]
  not container.resources.limits
  msg = sprintf("Container %s has no resource limits", [container.name])
}

deny[msg] {
  input.kind == "Deployment"
  container := input.spec.template.spec.containers[_]
  container.securityContext.privileged
  msg = sprintf("Container %s is running in privileged mode", [container.name])
}
```

Create OPA policies for Docker:

```rego
# policy/docker/security.rego
package main

deny[msg] {
  input[i].Cmd == "USER"
  not input[i].Value
  msg = "Dockerfile must have USER instruction"
}

deny[msg] {
  input[i].Cmd == "FROM"
  not endswith(input[i].Value[0], "-alpine")
  not endswith(input[i].Value[0], "-slim")
  msg = "Base image should use alpine or slim variants"
}
```

Commit and push these changes:

```bash
mkdir -p policy/kubernetes policy/docker
touch policy/kubernetes/security.rego policy/docker/security.rego
git add .github/workflows/pipeline.yml policy/
git commit -m "Add policy as code with OPA and Conftest"
git push
```

### Step 10: Security Reports and Dashboards

Add a security report generation job:

```yaml
# Add this to the jobs section in pipeline.yml
  security-report:
    runs-on: ubuntu-latest
    needs: [sast, sca, container-scan, iac-scan, dast, policy-check]
    if: always()
    steps:
      - uses: actions/checkout@v3
      
      - name: Download all workflow artifacts
        uses: actions/download-artifact@v3
        
      - name: Generate security report
        run: |
          mkdir -p security-reports
          # Combine reports and generate summary
          echo "# Security Scan Results" > security-reports/summary.md
          echo "## SAST Results" >> security-reports/summary.md
          # Add more report processing here
          
      - name: Upload combined security report
        uses: actions/upload-artifact@v3
        with:
          name: security-reports
          path: security-reports
```

Update the main workflow to add a deployment gate based on security results:

```yaml
# Add this to the pipeline.yml file
  deploy:
    runs-on: ubuntu-latest
    needs: [build, sast, sca, container-scan, iac-scan, dast, policy-check]
    if: success()
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy to development
        run: echo "Deploy to development environment"
        # In a real scenario, you would add actual deployment steps here
```

Commit and push these changes:

```bash
git add .github/workflows/pipeline.yml
git commit -m "Add security reports and deployment gate"
git push
```

## 🔍 Analyzing the Results

After completing the lab, your GitHub Actions workflow will execute all security checks when you push changes. To analyze the results:

1. Go to the "Actions" tab in your GitHub repository
2. Click on the latest workflow run
3. Review the results of each job
4. Download the security reports artifact
5. Review the security findings and recommendations

## 🎯 Continuous Improvement

To continue improving your DevSecOps pipeline:

1. **Set Security Thresholds**: Define acceptable thresholds for security issues
2. **Implement Automated Remediation**: Add auto-fix capabilities for common issues
3. **Security as Code Reviews**: Add security experts to code reviews
4. **Threat Modeling**: Add threat modeling as part of the design process
5. **Security Champions**: Designate security champions within development teams
6. **Continuous Training**: Provide ongoing security training for developers

## 📝 Additional Challenges

1. **Integrate Secret Scanning**: Add detection for hardcoded secrets
2. **Add License Compliance**: Check for open source license compliance
3. **Implement Runtime Security**: Add container runtime security monitoring
4. **Create Security Dashboards**: Build custom security dashboards
5. **Add Automated Remediation**: Implement auto-fix for common security issues

## 🔗 Resources

- [OWASP DevSecOps Guideline](https://owasp.org/www-project-devsecops-guideline/)
- [DevSecOps on GitHub](https://github.blog/2020-08-13-secure-at-every-step-putting-devsecops-into-practice-with-code-scanning/)
- [GitHub Advanced Security](https://docs.github.com/en/github/getting-started-with-github/learning-about-github/about-github-advanced-security)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [DevSecOps Maturity Model](https://dsomm.timo-pagel.de/)

This lab provides a comprehensive introduction to implementing DevSecOps in a CI/CD pipeline. By completing this lab, you'll have a solid foundation for integrating security into every phase of your development process.
