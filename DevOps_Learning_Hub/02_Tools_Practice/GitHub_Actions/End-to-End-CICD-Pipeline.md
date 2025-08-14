# End-to-End CI/CD Pipeline with GitHub Actions

This guide provides a comprehensive walkthrough for creating a complete end-to-end CI/CD pipeline using GitHub Actions, covering all stages from code commit to production deployment.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Pipeline Overview](#pipeline-overview)
3. [GitHub Actions Setup](#github-actions-setup)
4. [Workflow File Structure](#workflow-file-structure)
5. [Pipeline Stages in Detail](#pipeline-stages-in-detail)
6. [Environment Management](#environment-management)
7. [Secrets and Configuration](#secrets-and-configuration)
8. [Advanced GitHub Actions Features](#advanced-github-actions-features)
9. [Monitoring Your Pipeline](#monitoring-your-pipeline)
10. [Hands-on Exercises](#hands-on-exercises)
11. [Troubleshooting](#troubleshooting)

## Prerequisites

Before getting started, ensure you have:

- GitHub repository
- Basic understanding of YAML
- Docker and/or Kubernetes environment
- Access to cloud resources (if deploying to cloud)

## Pipeline Overview

Our end-to-end CI/CD pipeline consists of the following stages:

```
Code Commit → Build → Test → Static Analysis → Security Scan → Artifact Creation → Deploy to Dev → Integration Tests → Deploy to Staging → Performance Tests → Manual Approval → Deploy to Production → Monitoring
```

![GitHub Actions Pipeline Flow](https://example.com/github-actions-pipeline-diagram.png)

## GitHub Actions Setup

### 1. Creating Workflow Files

Create a `.github/workflows` directory in your repository and add your workflow files there:

```bash
mkdir -p .github/workflows
touch .github/workflows/ci-cd.yml
```

### 2. Setting Up Environments

In your GitHub repository:

1. Go to Settings > Environments
2. Create environments for `development`, `staging`, and `production`
3. Configure environment protection rules and secrets

### 3. Configuring Secrets

1. Go to Settings > Secrets and variables > Actions
2. Add repository secrets:
   - `DOCKER_USERNAME`
   - `DOCKER_PASSWORD`
   - `KUBECONFIG`
   - `SONAR_TOKEN`
   - `SLACK_WEBHOOK_URL`

## Workflow File Structure

Create a `.github/workflows/ci-cd.yml` file:

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]
  workflow_dispatch:

env:
  DOCKER_REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}
  VERSION: ${{ github.sha }}

jobs:
  build:
    name: Build and Test
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
        
      - name: Set up JDK
        uses: actions/setup-java@v3
        with:
          distribution: 'temurin'
          java-version: '17'
          cache: 'maven'
      
      - name: Build with Maven
        run: mvn -B compile
      
      - name: Run unit tests
        run: mvn -B test
      
      - name: Generate test report
        run: mvn surefire-report:report
      
      - name: Upload test results
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: target/surefire-reports/
      
      - name: Code coverage
        run: mvn jacoco:report
      
      - name: Upload coverage results
        uses: actions/upload-artifact@v3
        with:
          name: code-coverage
          path: target/site/jacoco/
  
  static-analysis:
    name: Static Code Analysis
    runs-on: ubuntu-latest
    needs: build
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
        with:
          fetch-depth: 0
      
      - name: Set up JDK
        uses: actions/setup-java@v3
        with:
          distribution: 'temurin'
          java-version: '17'
          cache: 'maven'
      
      - name: SonarQube Scan
        uses: sonarsource/sonarcloud-github-action@master
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
        with:
          args: >
            -Dsonar.projectKey=${{ github.repository_owner }}_${{ github.event.repository.name }}
            -Dsonar.organization=${{ github.repository_owner }}
  
  security-scan:
    name: Security Scan
    runs-on: ubuntu-latest
    needs: build
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Set up JDK
        uses: actions/setup-java@v3
        with:
          distribution: 'temurin'
          java-version: '17'
          cache: 'maven'
      
      - name: Dependency Check
        run: mvn org.owasp:dependency-check-maven:check
      
      - name: Upload vulnerability report
        uses: actions/upload-artifact@v3
        with:
          name: vulnerability-report
          path: target/dependency-check-report.html
  
  package:
    name: Package Application
    runs-on: ubuntu-latest
    needs: [static-analysis, security-scan]
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Set up JDK
        uses: actions/setup-java@v3
        with:
          distribution: 'temurin'
          java-version: '17'
          cache: 'maven'
      
      - name: Package application
        run: mvn -B package -DskipTests
      
      - name: Upload JAR artifact
        uses: actions/upload-artifact@v3
        with:
          name: app-jar
          path: target/*.jar
  
  build-image:
    name: Build and Push Docker Image
    runs-on: ubuntu-latest
    needs: package
    
    permissions:
      contents: read
      packages: write
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Download JAR artifact
        uses: actions/download-artifact@v3
        with:
          name: app-jar
          path: target/
      
      - name: Set up QEMU
        uses: docker/setup-qemu-action@v2
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
      
      - name: Login to GitHub Container Registry
        uses: docker/login-action@v2
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Build and push Docker image
        uses: docker/build-push-action@v4
        with:
          context: .
          push: true
          tags: |
            ${{ env.DOCKER_REGISTRY }}/${{ env.IMAGE_NAME }}:${{ env.VERSION }}
            ${{ env.DOCKER_REGISTRY }}/${{ env.IMAGE_NAME }}:latest
          cache-from: type=gha
          cache-to: type=gha,mode=max
  
  deploy-development:
    name: Deploy to Development
    runs-on: ubuntu-latest
    needs: build-image
    environment: development
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Set up Kubernetes CLI
        uses: azure/setup-kubectl@v3
      
      - name: Deploy to Kubernetes development
        uses: Azure/k8s-deploy@v4
        with:
          namespace: development
          manifests: |
            k8s/development/namespace.yaml
            k8s/development/deployment.yaml
            k8s/development/service.yaml
          images: |
            ${{ env.DOCKER_REGISTRY }}/${{ env.IMAGE_NAME }}:${{ env.VERSION }}
          kubectl-version: 'latest'
          action: deploy
      
      - name: Wait for deployment
        run: |
          kubectl rollout status deployment/app-deployment -n development --timeout=180s
      
      - name: Verify deployment
        run: |
          kubectl get pods -n development -l app=myapp
      
      - name: Notify deployment status
        uses: rtCamp/action-slack-notify@v2
        env:
          SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK_URL }}
          SLACK_TITLE: Development Deployment
          SLACK_MESSAGE: "Application deployed to development environment"
          SLACK_COLOR: good
  
  integration-tests:
    name: Integration Tests
    runs-on: ubuntu-latest
    needs: deploy-development
    environment: development
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Set up JDK
        uses: actions/setup-java@v3
        with:
          distribution: 'temurin'
          java-version: '17'
          cache: 'maven'
      
      - name: Run integration tests
        run: |
          export APP_URL=http://dev-app.example.com
          mvn failsafe:integration-test
      
      - name: Upload integration test results
        uses: actions/upload-artifact@v3
        with:
          name: integration-test-results
          path: target/failsafe-reports/
  
  deploy-staging:
    name: Deploy to Staging
    runs-on: ubuntu-latest
    needs: integration-tests
    environment: staging
    if: github.ref == 'refs/heads/main'
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Set up Kubernetes CLI
        uses: azure/setup-kubectl@v3
      
      - name: Deploy to Kubernetes staging
        uses: Azure/k8s-deploy@v4
        with:
          namespace: staging
          manifests: |
            k8s/staging/namespace.yaml
            k8s/staging/deployment.yaml
            k8s/staging/service.yaml
          images: |
            ${{ env.DOCKER_REGISTRY }}/${{ env.IMAGE_NAME }}:${{ env.VERSION }}
          kubectl-version: 'latest'
          action: deploy
      
      - name: Wait for deployment
        run: |
          kubectl rollout status deployment/app-deployment -n staging --timeout=180s
      
      - name: Notify deployment status
        uses: rtCamp/action-slack-notify@v2
        env:
          SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK_URL }}
          SLACK_TITLE: Staging Deployment
          SLACK_MESSAGE: "Application deployed to staging environment"
          SLACK_COLOR: good
  
  performance-tests:
    name: Performance Tests
    runs-on: ubuntu-latest
    needs: deploy-staging
    environment: staging
    if: github.ref == 'refs/heads/main'
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Install k6
        run: |
          curl -L https://github.com/loadimpact/k6/releases/download/v0.33.0/k6-v0.33.0-linux-amd64.tar.gz | tar xzf -
          sudo cp k6-v0.33.0-linux-amd64/k6 /usr/local/bin
      
      - name: Run performance tests
        run: |
          export APP_URL=http://staging-app.example.com
          k6 run performance-tests/load-test.js
      
      - name: Upload performance test results
        uses: actions/upload-artifact@v3
        with:
          name: performance-test-results
          path: performance-tests/results/
  
  manual-approval:
    name: Manual Approval
    runs-on: ubuntu-latest
    needs: performance-tests
    environment: production
    if: github.ref == 'refs/heads/main'
    
    steps:
      - name: Approval notification
        uses: rtCamp/action-slack-notify@v2
        env:
          SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK_URL }}
          SLACK_TITLE: Production Deployment Approval
          SLACK_MESSAGE: "Production deployment requires approval"
          SLACK_COLOR: warning
  
  deploy-production:
    name: Deploy to Production
    runs-on: ubuntu-latest
    needs: manual-approval
    environment: production
    if: github.ref == 'refs/heads/main'
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Set up Kubernetes CLI
        uses: azure/setup-kubectl@v3
      
      - name: Deploy to Kubernetes production
        uses: Azure/k8s-deploy@v4
        with:
          namespace: production
          manifests: |
            k8s/production/namespace.yaml
            k8s/production/deployment.yaml
            k8s/production/service.yaml
          images: |
            ${{ env.DOCKER_REGISTRY }}/${{ env.IMAGE_NAME }}:${{ env.VERSION }}
          kubectl-version: 'latest'
          action: deploy
      
      - name: Wait for deployment
        run: |
          kubectl rollout status deployment/app-deployment -n production --timeout=180s
      
      - name: Verify deployment
        run: |
          kubectl get pods -n production -l app=myapp
      
      - name: Notify deployment status
        uses: rtCamp/action-slack-notify@v2
        env:
          SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK_URL }}
          SLACK_TITLE: Production Deployment
          SLACK_MESSAGE: "Application successfully deployed to production"
          SLACK_COLOR: good
  
  post-deployment:
    name: Post-Deployment Tasks
    runs-on: ubuntu-latest
    needs: deploy-production
    if: github.ref == 'refs/heads/main'
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Create release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: v${{ github.run_number }}
          release_name: Release v${{ github.run_number }}
          body: |
            Changes in this release:
            ${{ github.event.head_commit.message }}
          draft: false
          prerelease: false
      
      - name: Monitor application health
        run: |
          # Add health check script here
          echo "Monitoring application health..."
```

## Pipeline Stages in Detail

### 1. Build and Test

This job compiles the code and runs unit tests:

```yaml
build:
  name: Build and Test
  runs-on: ubuntu-latest
  
  steps:
    - name: Checkout code
      uses: actions/checkout@v3
      
    - name: Set up JDK
      uses: actions/setup-java@v3
      with:
        distribution: 'temurin'
        java-version: '17'
        cache: 'maven'
    
    - name: Build with Maven
      run: mvn -B compile
    
    - name: Run unit tests
      run: mvn -B test
    
    - name: Generate test report
      run: mvn surefire-report:report
    
    - name: Upload test results
      uses: actions/upload-artifact@v3
      with:
        name: test-results
        path: target/surefire-reports/
    
    - name: Code coverage
      run: mvn jacoco:report
    
    - name: Upload coverage results
      uses: actions/upload-artifact@v3
      with:
        name: code-coverage
        path: target/site/jacoco/
```

### 2. Static Code Analysis

This job analyzes code quality with SonarQube:

```yaml
static-analysis:
  name: Static Code Analysis
  runs-on: ubuntu-latest
  needs: build
  
  steps:
    - name: Checkout code
      uses: actions/checkout@v3
      with:
        fetch-depth: 0
    
    - name: Set up JDK
      uses: actions/setup-java@v3
      with:
        distribution: 'temurin'
        java-version: '17'
        cache: 'maven'
    
    - name: SonarQube Scan
      uses: sonarsource/sonarcloud-github-action@master
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
      with:
        args: >
          -Dsonar.projectKey=${{ github.repository_owner }}_${{ github.event.repository.name }}
          -Dsonar.organization=${{ github.repository_owner }}
```

### 3. Security Scan

This job checks for vulnerabilities in dependencies:

```yaml
security-scan:
  name: Security Scan
  runs-on: ubuntu-latest
  needs: build
  
  steps:
    - name: Checkout code
      uses: actions/checkout@v3
    
    - name: Set up JDK
      uses: actions/setup-java@v3
      with:
        distribution: 'temurin'
        java-version: '17'
        cache: 'maven'
    
    - name: Dependency Check
      run: mvn org.owasp:dependency-check-maven:check
    
    - name: Upload vulnerability report
      uses: actions/upload-artifact@v3
      with:
        name: vulnerability-report
        path: target/dependency-check-report.html
```

### 4. Package

This job creates the application artifact:

```yaml
package:
  name: Package Application
  runs-on: ubuntu-latest
  needs: [static-analysis, security-scan]
  
  steps:
    - name: Checkout code
      uses: actions/checkout@v3
    
    - name: Set up JDK
      uses: actions/setup-java@v3
      with:
        distribution: 'temurin'
        java-version: '17'
        cache: 'maven'
    
    - name: Package application
      run: mvn -B package -DskipTests
    
    - name: Upload JAR artifact
      uses: actions/upload-artifact@v3
      with:
        name: app-jar
        path: target/*.jar
```

### 5. Build and Push Docker Image

This job creates and publishes a Docker image:

```yaml
build-image:
  name: Build and Push Docker Image
  runs-on: ubuntu-latest
  needs: package
  
  permissions:
    contents: read
    packages: write
  
  steps:
    - name: Checkout code
      uses: actions/checkout@v3
    
    - name: Download JAR artifact
      uses: actions/download-artifact@v3
      with:
        name: app-jar
        path: target/
    
    - name: Set up QEMU
      uses: docker/setup-qemu-action@v2
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v2
    
    - name: Login to GitHub Container Registry
      uses: docker/login-action@v2
      with:
        registry: ghcr.io
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
    
    - name: Build and push Docker image
      uses: docker/build-push-action@v4
      with:
        context: .
        push: true
        tags: |
          ${{ env.DOCKER_REGISTRY }}/${{ env.IMAGE_NAME }}:${{ env.VERSION }}
          ${{ env.DOCKER_REGISTRY }}/${{ env.IMAGE_NAME }}:latest
        cache-from: type=gha
        cache-to: type=gha,mode=max
```

### 6. Deploy to Development

This job deploys the application to the development environment:

```yaml
deploy-development:
  name: Deploy to Development
  runs-on: ubuntu-latest
  needs: build-image
  environment: development
  
  steps:
    - name: Checkout code
      uses: actions/checkout@v3
    
    - name: Set up Kubernetes CLI
      uses: azure/setup-kubectl@v3
    
    - name: Deploy to Kubernetes development
      uses: Azure/k8s-deploy@v4
      with:
        namespace: development
        manifests: |
          k8s/development/namespace.yaml
          k8s/development/deployment.yaml
          k8s/development/service.yaml
        images: |
          ${{ env.DOCKER_REGISTRY }}/${{ env.IMAGE_NAME }}:${{ env.VERSION }}
        kubectl-version: 'latest'
        action: deploy
    
    - name: Wait for deployment
      run: |
        kubectl rollout status deployment/app-deployment -n development --timeout=180s
    
    - name: Verify deployment
      run: |
        kubectl get pods -n development -l app=myapp
    
    - name: Notify deployment status
      uses: rtCamp/action-slack-notify@v2
      env:
        SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK_URL }}
        SLACK_TITLE: Development Deployment
        SLACK_MESSAGE: "Application deployed to development environment"
        SLACK_COLOR: good
```

### 7. Integration Tests

This job runs integration tests against the development environment:

```yaml
integration-tests:
  name: Integration Tests
  runs-on: ubuntu-latest
  needs: deploy-development
  environment: development
  
  steps:
    - name: Checkout code
      uses: actions/checkout@v3
    
    - name: Set up JDK
      uses: actions/setup-java@v3
      with:
        distribution: 'temurin'
        java-version: '17'
        cache: 'maven'
    
    - name: Run integration tests
      run: |
        export APP_URL=http://dev-app.example.com
        mvn failsafe:integration-test
    
    - name: Upload integration test results
      uses: actions/upload-artifact@v3
      with:
        name: integration-test-results
        path: target/failsafe-reports/
```

### 8. Deploy to Staging

This job deploys to the staging environment:

```yaml
deploy-staging:
  name: Deploy to Staging
  runs-on: ubuntu-latest
  needs: integration-tests
  environment: staging
  if: github.ref == 'refs/heads/main'
  
  steps:
    - name: Checkout code
      uses: actions/checkout@v3
    
    - name: Set up Kubernetes CLI
      uses: azure/setup-kubectl@v3
    
    - name: Deploy to Kubernetes staging
      uses: Azure/k8s-deploy@v4
      with:
        namespace: staging
        manifests: |
          k8s/staging/namespace.yaml
          k8s/staging/deployment.yaml
          k8s/staging/service.yaml
        images: |
          ${{ env.DOCKER_REGISTRY }}/${{ env.IMAGE_NAME }}:${{ env.VERSION }}
        kubectl-version: 'latest'
        action: deploy
    
    - name: Wait for deployment
      run: |
        kubectl rollout status deployment/app-deployment -n staging --timeout=180s
    
    - name: Notify deployment status
      uses: rtCamp/action-slack-notify@v2
      env:
        SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK_URL }}
        SLACK_TITLE: Staging Deployment
        SLACK_MESSAGE: "Application deployed to staging environment"
        SLACK_COLOR: good
```

### 9. Performance Tests

This job runs performance tests against the staging environment:

```yaml
performance-tests:
  name: Performance Tests
  runs-on: ubuntu-latest
  needs: deploy-staging
  environment: staging
  if: github.ref == 'refs/heads/main'
  
  steps:
    - name: Checkout code
      uses: actions/checkout@v3
    
    - name: Install k6
      run: |
        curl -L https://github.com/loadimpact/k6/releases/download/v0.33.0/k6-v0.33.0-linux-amd64.tar.gz | tar xzf -
        sudo cp k6-v0.33.0-linux-amd64/k6 /usr/local/bin
    
    - name: Run performance tests
      run: |
        export APP_URL=http://staging-app.example.com
        k6 run performance-tests/load-test.js
    
    - name: Upload performance test results
      uses: actions/upload-artifact@v3
      with:
        name: performance-test-results
        path: performance-tests/results/
```

### 10. Manual Approval

This job requires manual approval before deploying to production:

```yaml
manual-approval:
  name: Manual Approval
  runs-on: ubuntu-latest
  needs: performance-tests
  environment: production
  if: github.ref == 'refs/heads/main'
  
  steps:
    - name: Approval notification
      uses: rtCamp/action-slack-notify@v2
      env:
        SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK_URL }}
        SLACK_TITLE: Production Deployment Approval
        SLACK_MESSAGE: "Production deployment requires approval"
        SLACK_COLOR: warning
```

### 11. Deploy to Production

This job deploys to the production environment:

```yaml
deploy-production:
  name: Deploy to Production
  runs-on: ubuntu-latest
  needs: manual-approval
  environment: production
  if: github.ref == 'refs/heads/main'
  
  steps:
    - name: Checkout code
      uses: actions/checkout@v3
    
    - name: Set up Kubernetes CLI
      uses: azure/setup-kubectl@v3
    
    - name: Deploy to Kubernetes production
      uses: Azure/k8s-deploy@v4
      with:
        namespace: production
        manifests: |
          k8s/production/namespace.yaml
          k8s/production/deployment.yaml
          k8s/production/service.yaml
        images: |
          ${{ env.DOCKER_REGISTRY }}/${{ env.IMAGE_NAME }}:${{ env.VERSION }}
        kubectl-version: 'latest'
        action: deploy
    
    - name: Wait for deployment
      run: |
        kubectl rollout status deployment/app-deployment -n production --timeout=180s
    
    - name: Verify deployment
      run: |
        kubectl get pods -n production -l app=myapp
    
    - name: Notify deployment status
      uses: rtCamp/action-slack-notify@v2
      env:
        SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK_URL }}
        SLACK_TITLE: Production Deployment
        SLACK_MESSAGE: "Application successfully deployed to production"
        SLACK_COLOR: good
```

### 12. Post-Deployment Tasks

This job handles tasks after successful production deployment:

```yaml
post-deployment:
  name: Post-Deployment Tasks
  runs-on: ubuntu-latest
  needs: deploy-production
  if: github.ref == 'refs/heads/main'
  
  steps:
    - name: Checkout code
      uses: actions/checkout@v3
    
    - name: Create release
      uses: actions/create-release@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        tag_name: v${{ github.run_number }}
        release_name: Release v${{ github.run_number }}
        body: |
          Changes in this release:
          ${{ github.event.head_commit.message }}
        draft: false
        prerelease: false
    
    - name: Monitor application health
      run: |
        # Add health check script here
        echo "Monitoring application health..."
```

## Environment Management

### Creating Environment-Specific Configurations

Organize environment-specific configurations:

```
k8s/
├── development/
│   ├── configmap.yaml
│   ├── deployment.yaml
│   ├── namespace.yaml
│   └── service.yaml
├── staging/
│   ├── configmap.yaml
│   ├── deployment.yaml
│   ├── namespace.yaml
│   └── service.yaml
└── production/
    ├── configmap.yaml
    ├── deployment.yaml
    ├── namespace.yaml
    └── service.yaml
```

### Environment Protection Rules

In GitHub repository settings:

1. Go to Settings > Environments
2. Select an environment (e.g., `production`)
3. Enable:
   - Required reviewers
   - Wait timer
   - Deployment branches (e.g., only `main`)

### Environment Variables

Set environment-specific variables:

```yaml
deploy-production:
  environment:
    name: production
    url: https://example.com
  steps:
    # Deployment steps using environment variables
```

## Secrets and Configuration

### Repository Secrets

Store sensitive information as repository secrets:

```yaml
steps:
  - name: Login to Docker Registry
    uses: docker/login-action@v2
    with:
      registry: ghcr.io
      username: ${{ github.actor }}
      password: ${{ secrets.GITHUB_TOKEN }}
```

### Environment Secrets

Store environment-specific secrets:

```yaml
deploy-production:
  environment: production
  steps:
    - name: Deploy with credentials
      env:
        API_KEY: ${{ secrets.PRODUCTION_API_KEY }}
      run: ./deploy.sh
```

### Configuration Files

Use workflow-specific configuration files:

```yaml
steps:
  - name: Load configuration
    run: |
      echo "Loading configuration for ${{ github.event.repository.name }}"
      cp .github/config/${{ github.event.repository.name }}.yml config.yml
```

## Advanced GitHub Actions Features

### Matrix Builds

Test across multiple configurations:

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [14.x, 16.x, 18.x]
        os: [ubuntu-latest, windows-latest, macos-latest]
    steps:
      - uses: actions/checkout@v3
      - name: Use Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v3
        with:
          node-version: ${{ matrix.node-version }}
      - run: npm ci
      - run: npm test
```

### Reusable Workflows

Create reusable workflow files:

```yaml
# .github/workflows/reusable-build.yml
name: Reusable Build
on:
  workflow_call:
    inputs:
      node-version:
        required: true
        type: string

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Use Node.js
        uses: actions/setup-node@v3
        with:
          node-version: ${{ inputs.node-version }}
      - run: npm ci
      - run: npm run build
```

Call from another workflow:

```yaml
jobs:
  call-workflow:
    uses: ./.github/workflows/reusable-build.yml
    with:
      node-version: '16'
```

### Composite Actions

Create custom actions:

```yaml
# .github/actions/deploy/action.yml
name: 'Deploy Application'
description: 'Deploys application to Kubernetes'
inputs:
  environment:
    description: 'Target environment'
    required: true
  namespace:
    description: 'Kubernetes namespace'
    required: true
runs:
  using: "composite"
  steps:
    - name: Set up kubectl
      uses: azure/setup-kubectl@v3
      shell: bash
    
    - name: Deploy to Kubernetes
      uses: Azure/k8s-deploy@v4
      with:
        namespace: ${{ inputs.namespace }}
        manifests: k8s/${{ inputs.environment }}/*.yaml
      shell: bash
```

Use in workflow:

```yaml
steps:
  - uses: ./.github/actions/deploy
    with:
      environment: 'production'
      namespace: 'production'
```

### Workflow Concurrency

Prevent multiple deployments to the same environment:

```yaml
jobs:
  deploy:
    concurrency:
      group: deploy-${{ github.ref }}-${{ github.event.environment }}
      cancel-in-progress: true
    steps:
      # Deployment steps
```

## Monitoring Your Pipeline

### GitHub Actions Dashboard

Monitor workflows in the GitHub UI:

1. Go to your repository
2. Click on "Actions" tab
3. View workflow runs and their status

### Workflow Visualization

Use the GitHub Actions visualization in the UI to:

1. See job dependencies
2. Identify bottlenecks
3. Troubleshoot failures

### Notifications

Configure notifications:

```yaml
steps:
  - name: Notify Slack
    uses: rtCamp/action-slack-notify@v2
    env:
      SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK_URL }}
      SLACK_TITLE: Deployment Status
      SLACK_MESSAGE: "Application deployed successfully"
      SLACK_COLOR: good
```

## Hands-on Exercises

### Exercise 1: Create a Basic GitHub Actions Workflow

1. Create a `.github/workflows` directory
2. Add a simple workflow file for a Node.js application
3. Configure it to run on push and pull requests
4. Test the workflow by pushing changes

### Exercise 2: Add Unit Tests and Quality Gates

1. Add unit tests to your project
2. Configure SonarCloud integration
3. Add test and analysis jobs to the workflow
4. Set up quality gates

### Exercise 3: Containerize Your Application

1. Create a Dockerfile for your application
2. Add Docker build and push jobs
3. Configure GitHub Container Registry
4. Test the container build

### Exercise 4: Implement Multi-Environment Deployment

1. Create environment configurations
2. Add deployment jobs for different environments
3. Configure environment protection rules
4. Test the deployment process

### Exercise 5: Create a Complete CI/CD Pipeline

1. Combine all previous exercises
2. Add integration and performance tests
3. Implement manual approval for production
4. Configure notifications
5. Test the entire pipeline

## Troubleshooting

### Common Issues and Solutions

1. **Workflow syntax errors**
   - Use GitHub Actions validator tools
   - Check YAML indentation
   - Validate workflow syntax

2. **Authentication failures**
   - Verify secret names and values
   - Check token permissions
   - Ensure service account credentials are valid

3. **Missing environment variables**
   - Verify environment variable names
   - Check if secrets are properly configured
   - Make sure environment variables are available in the correct scope

4. **Deployment failures**
   - Check Kubernetes manifests
   - Verify kubeconfig is valid
   - Ensure correct namespace is used

5. **Permission issues**
   - Check repository permissions
   - Verify workflow permissions
   - Make sure the necessary `permissions` block is included

### Debugging Workflows

1. Enable debug logging:
   - Set secret `ACTIONS_RUNNER_DEBUG` to `true`
   - Set secret `ACTIONS_STEP_DEBUG` to `true`

2. Add debug steps:
   ```yaml
   - name: Debug environment
     run: |
       env
       echo "Working directory: $GITHUB_WORKSPACE"
   ```

3. Use the workflow visualization to identify failing steps

### Getting Help

- Check workflow logs
- Review GitHub Actions documentation
- Use GitHub Community forums and Stack Overflow
- Check the GitHub Status page for service issues

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Actions Marketplace](https://github.com/marketplace?type=actions)
- [GitHub Actions Starter Workflows](https://github.com/actions/starter-workflows)
- [GitHub Actions Community Forum](https://github.community/c/actions/41)
- [GitHub Actions Best Practices](https://docs.github.com/en/actions/learn-github-actions/best-practices-for-github-actions)
