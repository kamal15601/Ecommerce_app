# GitHub Actions CI/CD Hands-On Labs ⚡

## Overview
GitHub Actions is a powerful CI/CD platform that enables automation directly within GitHub repositories. This comprehensive guide covers everything from basic workflows to advanced enterprise patterns.

## Prerequisites
- GitHub account
- Basic Git knowledge
- Understanding of YAML syntax
- Repository with code to build/deploy

## Labs Structure

### Lab 1: First Workflow - Hello World

#### Basic Workflow Structure
Create `.github/workflows/hello-world.yml`:

```yaml
name: Hello World

# Triggers
on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  schedule:
    - cron: '0 6 * * *'  # Daily at 6 AM UTC
  workflow_dispatch:      # Manual trigger

# Environment variables
env:
  GLOBAL_VAR: "Hello from GitHub Actions"

jobs:
  hello-world:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Print hello world
      run: |
        echo "Hello World!"
        echo "Global variable: $GLOBAL_VAR"
        echo "Repository: ${{ github.repository }}"
        echo "Branch: ${{ github.ref_name }}"
        echo "Commit SHA: ${{ github.sha }}"
        
    - name: Print environment info
      run: |
        echo "Runner OS: ${{ runner.os }}"
        echo "Runner temp: ${{ runner.temp }}"
        echo "Workspace: ${{ github.workspace }}"
```

#### Understanding Triggers
```yaml
on:
  # Push events
  push:
    branches: [ main, 'release/*' ]
    tags: [ 'v*' ]
    paths:
      - 'src/**'
      - '!src/docs/**'
  
  # Pull request events
  pull_request:
    types: [ opened, synchronize, reopened ]
    branches: [ main ]
  
  # Issue events
  issues:
    types: [ opened, labeled ]
  
  # Release events
  release:
    types: [ published ]
  
  # External webhooks
  repository_dispatch:
    types: [ custom-event ]
```

### Lab 2: Node.js CI/CD Pipeline

#### Complete Node.js Workflow
`.github/workflows/nodejs-ci.yml`:

```yaml
name: Node.js CI/CD

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

env:
  NODE_VERSION: '18'
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  # Job 1: Code Quality & Testing
  test:
    runs-on: ubuntu-latest
    
    strategy:
      matrix:
        node-version: [16, 18, 20]
        os: [ubuntu-latest, windows-latest, macos-latest]
    
    steps:
    - name: Checkout repository
      uses: actions/checkout@v4
      
    - name: Setup Node.js ${{ matrix.node-version }}
      uses: actions/setup-node@v4
      with:
        node-version: ${{ matrix.node-version }}
        cache: 'npm'
        
    - name: Install dependencies
      run: npm ci
      
    - name: Run linting
      run: npm run lint
      
    - name: Run tests
      run: npm test -- --coverage
      
    - name: Upload coverage reports
      uses: codecov/codecov-action@v3
      if: matrix.node-version == '18' && matrix.os == 'ubuntu-latest'
      with:
        file: ./coverage/coverage-final.json
        flags: unittests
        name: codecov-umbrella
        
    - name: Upload test artifacts
      uses: actions/upload-artifact@v4
      if: failure()
      with:
        name: test-results-${{ matrix.node-version }}-${{ matrix.os }}
        path: |
          test-results.xml
          coverage/
          
  # Job 2: Security Scanning
  security:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout repository
      uses: actions/checkout@v4
      
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: ${{ env.NODE_VERSION }}
        cache: 'npm'
        
    - name: Install dependencies
      run: npm ci
      
    - name: Run security audit
      run: npm audit --audit-level high
      
    - name: Run Snyk security scan
      uses: snyk/actions/node@master
      env:
        SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
      with:
        args: --severity-threshold=high
        
    - name: CodeQL Analysis
      uses: github/codeql-action/init@v2
      with:
        languages: javascript
        
    - name: Perform CodeQL Analysis
      uses: github/codeql-action/analyze@v2

  # Job 3: Build and Push Docker Image
  build:
    needs: [test, security]
    runs-on: ubuntu-latest
    if: github.event_name == 'push'
    
    permissions:
      contents: read
      packages: write
    
    outputs:
      image-digest: ${{ steps.build.outputs.digest }}
      image-tag: ${{ steps.meta.outputs.tags }}
    
    steps:
    - name: Checkout repository
      uses: actions/checkout@v4
      
    - name: Setup Docker Buildx
      uses: docker/setup-buildx-action@v3
      
    - name: Log in to Container Registry
      uses: docker/login-action@v3
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
        
    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v5
      with:
        images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
        tags: |
          type=ref,event=branch
          type=ref,event=pr
          type=sha,prefix={{branch}}-
          type=raw,value=latest,enable={{is_default_branch}}
          
    - name: Build and push Docker image
      id: build
      uses: docker/build-push-action@v5
      with:
        context: .
        platforms: linux/amd64,linux/arm64
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
        cache-from: type=gha
        cache-to: type=gha,mode=max
        build-args: |
          NODE_VERSION=${{ env.NODE_VERSION }}
          BUILD_DATE=${{ github.event.head_commit.timestamp }}
          GIT_SHA=${{ github.sha }}

  # Job 4: Deploy to Staging
  deploy-staging:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/develop'
    environment: staging
    
    steps:
    - name: Deploy to staging
      run: |
        echo "Deploying ${{ needs.build.outputs.image-tag }} to staging"
        # Add actual deployment commands here
        
  # Job 5: Deploy to Production
  deploy-production:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment: production
    
    steps:
    - name: Deploy to production
      run: |
        echo "Deploying ${{ needs.build.outputs.image-tag }} to production"
        # Add actual deployment commands here
```

### Lab 3: Advanced Matrix Strategies

#### Complex Matrix Builds
```yaml
name: Matrix Strategy

on: [push, pull_request]

jobs:
  test:
    runs-on: ${{ matrix.os }}
    
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        node-version: [16, 18, 20]
        database: [postgres, mysql, sqlite]
        
        # Include specific combinations
        include:
          - os: ubuntu-latest
            node-version: 18
            database: postgres
            experimental: true
            
        # Exclude specific combinations
        exclude:
          - os: macos-latest
            database: mysql
          - os: windows-latest
            node-version: 16
    
    env:
      DATABASE: ${{ matrix.database }}
      EXPERIMENTAL: ${{ matrix.experimental || false }}
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: ${{ matrix.node-version }}
        
    - name: Setup Database
      run: |
        if [ "${{ matrix.database }}" == "postgres" ]; then
          # Setup PostgreSQL
          sudo systemctl start postgresql
        elif [ "${{ matrix.database }}" == "mysql" ]; then
          # Setup MySQL
          sudo systemctl start mysql
        fi
      shell: bash
      
    - name: Run tests
      run: npm test
      continue-on-error: ${{ matrix.experimental == true }}
```

### Lab 4: Reusable Workflows

#### Creating Reusable Workflow
`.github/workflows/reusable-ci.yml`:

```yaml
name: Reusable CI

on:
  workflow_call:
    inputs:
      node-version:
        required: false
        type: string
        default: '18'
      environment:
        required: true
        type: string
      deploy:
        required: false
        type: boolean
        default: false
    secrets:
      DEPLOY_TOKEN:
        required: false
      SLACK_WEBHOOK:
        required: false
    outputs:
      build-artifact:
        description: "Built artifact name"
        value: ${{ jobs.build.outputs.artifact-name }}

jobs:
  build:
    runs-on: ubuntu-latest
    
    outputs:
      artifact-name: ${{ steps.artifact.outputs.artifact-name }}
    
    steps:
    - name: Checkout
      uses: actions/checkout@v4
      
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: ${{ inputs.node-version }}
        cache: 'npm'
        
    - name: Install and build
      run: |
        npm ci
        npm run build
        
    - name: Create artifact
      id: artifact
      run: |
        ARTIFACT_NAME="build-${{ github.sha }}-${{ inputs.environment }}"
        tar -czf "${ARTIFACT_NAME}.tar.gz" dist/
        echo "artifact-name=${ARTIFACT_NAME}" >> $GITHUB_OUTPUT
        
    - name: Upload artifact
      uses: actions/upload-artifact@v4
      with:
        name: ${{ steps.artifact.outputs.artifact-name }}
        path: ${{ steps.artifact.outputs.artifact-name }}.tar.gz
        
  deploy:
    if: inputs.deploy
    needs: build
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}
    
    steps:
    - name: Download artifact
      uses: actions/download-artifact@v4
      with:
        name: ${{ needs.build.outputs.artifact-name }}
        
    - name: Deploy
      env:
        DEPLOY_TOKEN: ${{ secrets.DEPLOY_TOKEN }}
      run: |
        echo "Deploying to ${{ inputs.environment }}"
        # Add deployment logic here
        
    - name: Notify Slack
      if: always() && secrets.SLACK_WEBHOOK
      uses: 8398a7/action-slack@v3
      with:
        status: ${{ job.status }}
        webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

#### Using Reusable Workflow
`.github/workflows/main.yml`:

```yaml
name: Main Pipeline

on:
  push:
    branches: [main, develop]

jobs:
  staging:
    uses: ./.github/workflows/reusable-ci.yml
    with:
      node-version: '18'
      environment: 'staging'
      deploy: true
    secrets:
      DEPLOY_TOKEN: ${{ secrets.STAGING_DEPLOY_TOKEN }}
      SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK }}
      
  production:
    if: github.ref == 'refs/heads/main'
    needs: staging
    uses: ./.github/workflows/reusable-ci.yml
    with:
      node-version: '18'
      environment: 'production'
      deploy: true
    secrets:
      DEPLOY_TOKEN: ${{ secrets.PROD_DEPLOY_TOKEN }}
      SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK }}
```

### Lab 5: Custom Actions

#### JavaScript Action
**action.yml**:
```yaml
name: 'Custom Deployment Action'
description: 'Deploy application with custom logic'
author: 'Your Name'

inputs:
  environment:
    description: 'Deployment environment'
    required: true
  image-tag:
    description: 'Docker image tag to deploy'
    required: true
  config-file:
    description: 'Configuration file path'
    required: false
    default: 'config/default.yml'

outputs:
  deployment-url:
    description: 'URL of the deployed application'
  deployment-id:
    description: 'Unique deployment identifier'

runs:
  using: 'node20'
  main: 'dist/index.js'
  
branding:
  icon: 'upload-cloud'
  color: 'blue'
```

**src/index.js**:
```javascript
const core = require('@actions/core');
const github = require('@actions/github');
const exec = require('@actions/exec');

async function run() {
  try {
    // Get inputs
    const environment = core.getInput('environment');
    const imageTag = core.getInput('image-tag');
    const configFile = core.getInput('config-file');
    
    // Get context
    const context = github.context;
    const sha = context.sha.substring(0, 7);
    
    core.info(`Deploying ${imageTag} to ${environment}`);
    
    // Generate deployment ID
    const deploymentId = `deploy-${environment}-${sha}-${Date.now()}`;
    
    // Simulate deployment commands
    await exec.exec('kubectl', [
      'set', 'image',
      `deployment/myapp-${environment}`,
      `app=${imageTag}`,
      `--namespace=${environment}`
    ]);
    
    // Wait for rollout
    await exec.exec('kubectl', [
      'rollout', 'status',
      `deployment/myapp-${environment}`,
      `--namespace=${environment}`,
      '--timeout=300s'
    ]);
    
    // Get service URL
    let serviceUrl = '';
    await exec.exec('kubectl', [
      'get', 'service', `myapp-${environment}`,
      `--namespace=${environment}`,
      '-o', 'jsonpath={.status.loadBalancer.ingress[0].hostname}'
    ], {
      listeners: {
        stdout: (data) => {
          serviceUrl += data.toString();
        }
      }
    });
    
    const deploymentUrl = `https://${serviceUrl}`;
    
    // Set outputs
    core.setOutput('deployment-url', deploymentUrl);
    core.setOutput('deployment-id', deploymentId);
    
    // Create deployment annotation
    await core.summary
      .addHeading('Deployment Summary')
      .addTable([
        ['Environment', environment],
        ['Image Tag', imageTag],
        ['Deployment ID', deploymentId],
        ['URL', deploymentUrl]
      ])
      .write();
    
    core.info(`Deployment completed: ${deploymentUrl}`);
    
  } catch (error) {
    core.setFailed(error.message);
  }
}

run();
```

#### Docker Action
**Dockerfile**:
```dockerfile
FROM alpine:3.18

RUN apk add --no-cache \
    bash \
    curl \
    kubectl

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
```

**entrypoint.sh**:
```bash
#!/bin/bash
set -e

ENVIRONMENT=$1
IMAGE_TAG=$2
CONFIG_FILE=$3

echo "Deploying $IMAGE_TAG to $ENVIRONMENT"

# Apply configuration
kubectl apply -f "$CONFIG_FILE" --namespace="$ENVIRONMENT"

# Update deployment
kubectl set image deployment/myapp \
  app="$IMAGE_TAG" \
  --namespace="$ENVIRONMENT"

# Wait for rollout
kubectl rollout status deployment/myapp \
  --namespace="$ENVIRONMENT" \
  --timeout=300s

echo "Deployment completed successfully"
```

### Lab 6: Security and Secrets Management

#### Secure Workflow with OIDC
```yaml
name: Secure AWS Deployment

on:
  push:
    branches: [main]

env:
  AWS_REGION: us-east-1

# OIDC permissions
permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout
      uses: actions/checkout@v4
      
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        role-to-assume: ${{ secrets.AWS_ROLE_TO_ASSUME }}
        role-session-name: GitHubActions
        aws-region: ${{ env.AWS_REGION }}
        
    - name: Login to Amazon ECR
      id: login-ecr
      uses: aws-actions/amazon-ecr-login@v2
      
    - name: Build and push image
      env:
        ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        ECR_REPOSITORY: myapp
        IMAGE_TAG: ${{ github.sha }}
      run: |
        docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
        docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
        
    - name: Deploy to EKS
      run: |
        aws eks update-kubeconfig --name my-cluster --region $AWS_REGION
        kubectl set image deployment/myapp \
          app=$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
```

#### Secrets Scanning
```yaml
name: Security Scan

on: [push, pull_request]

jobs:
  secret-scan:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout
      uses: actions/checkout@v4
      with:
        fetch-depth: 0
        
    - name: TruffleHog OSS
      uses: trufflesecurity/trufflehog@main
      with:
        path: ./
        base: main
        head: HEAD
        extra_args: --debug --only-verified
        
    - name: GitGuardian scan
      uses: GitGuardian/ggshield/actions/secret@main
      env:
        GITHUB_PUSH_BEFORE_SHA: ${{ github.event.before }}
        GITHUB_PUSH_BASE_SHA: ${{ github.event.base }}
        GITHUB_PULL_BASE_SHA: ${{ github.event.pull_request.base.sha }}
        GITHUB_DEFAULT_BRANCH: ${{ github.event.repository.default_branch }}
        GITGUARDIAN_API_KEY: ${{ secrets.GITGUARDIAN_API_KEY }}
```

### Lab 7: Multi-Cloud Deployment

#### Azure + AWS + GCP Deployment
```yaml
name: Multi-Cloud Deployment

on:
  push:
    branches: [main]

permissions:
  id-token: write
  contents: read

jobs:
  deploy-azure:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout
      uses: actions/checkout@v4
      
    - name: Azure Login
      uses: azure/login@v1
      with:
        client-id: ${{ secrets.AZURE_CLIENT_ID }}
        tenant-id: ${{ secrets.AZURE_TENANT_ID }}
        subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
        
    - name: Deploy to Azure Container Instances
      uses: azure/aci-deploy@v1
      with:
        resource-group: myapp-rg
        dns-name-label: myapp-azure
        image: myregistry.azurecr.io/myapp:${{ github.sha }}
        name: myapp-azure
        location: 'East US'

  deploy-aws:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout
      uses: actions/checkout@v4
      
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        role-to-assume: ${{ secrets.AWS_ROLE_TO_ASSUME }}
        aws-region: us-east-1
        
    - name: Deploy to ECS
      run: |
        aws ecs update-service \
          --cluster myapp-cluster \
          --service myapp-service \
          --force-new-deployment

  deploy-gcp:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout
      uses: actions/checkout@v4
      
    - name: Authenticate to Google Cloud
      uses: google-github-actions/auth@v1
      with:
        workload_identity_provider: ${{ secrets.WIF_PROVIDER }}
        service_account: ${{ secrets.WIF_SERVICE_ACCOUNT }}
        
    - name: Deploy to Cloud Run
      uses: google-github-actions/deploy-cloudrun@v1
      with:
        service: myapp
        image: gcr.io/${{ secrets.GCP_PROJECT_ID }}/myapp:${{ github.sha }}
        region: us-central1
```

### Lab 8: Advanced Monitoring and Observability

#### Comprehensive Monitoring Workflow
```yaml
name: Deploy with Monitoring

on:
  push:
    branches: [main]

jobs:
  deploy-with-monitoring:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout
      uses: actions/checkout@v4
      
    - name: Deploy application
      id: deploy
      run: |
        # Deployment commands
        kubectl apply -f k8s/
        kubectl rollout status deployment/myapp
        
        # Get deployment info
        DEPLOYMENT_URL=$(kubectl get ingress myapp -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
        echo "deployment-url=$DEPLOYMENT_URL" >> $GITHUB_OUTPUT
        
    - name: Setup monitoring
      run: |
        # Create Grafana dashboard
        curl -X POST "${{ secrets.GRAFANA_URL }}/api/dashboards/db" \
          -H "Authorization: Bearer ${{ secrets.GRAFANA_API_KEY }}" \
          -H "Content-Type: application/json" \
          -d @monitoring/dashboard.json
        
        # Create Prometheus alerts
        kubectl apply -f monitoring/alerts.yaml
        
    - name: Run health checks
      id: health
      run: |
        DEPLOYMENT_URL="${{ steps.deploy.outputs.deployment-url }}"
        
        # Wait for service to be ready
        for i in {1..30}; do
          if curl -f "$DEPLOYMENT_URL/health"; then
            echo "Service is healthy"
            break
          fi
          echo "Waiting for service to be ready..."
          sleep 10
        done
        
    - name: Run load tests
      uses: k6-io/action@v0.1
      with:
        filename: tests/load-test.js
        flags: --env HOSTNAME=${{ steps.deploy.outputs.deployment-url }}
        
    - name: Synthetic monitoring
      run: |
        # Create Datadog synthetic test
        curl -X POST "https://api.datadoghq.com/api/v1/synthetics/tests" \
          -H "Content-Type: application/json" \
          -H "DD-API-KEY: ${{ secrets.DATADOG_API_KEY }}" \
          -H "DD-APPLICATION-KEY: ${{ secrets.DATADOG_APP_KEY }}" \
          -d '{
            "type": "api",
            "subtype": "http",
            "name": "MyApp Health Check",
            "message": "Health check for MyApp deployment",
            "config": {
              "request": {
                "method": "GET",
                "url": "${{ steps.deploy.outputs.deployment-url }}/health"
              },
              "assertions": [
                {
                  "type": "statusCode",
                  "operator": "is",
                  "target": 200
                }
              ]
            },
            "locations": ["aws:us-east-1", "aws:eu-west-1"],
            "options": {
              "tick_every": 60
            }
          }'
          
    - name: Create deployment annotation
      run: |
        # Grafana annotation
        curl -X POST "${{ secrets.GRAFANA_URL }}/api/annotations" \
          -H "Authorization: Bearer ${{ secrets.GRAFANA_API_KEY }}" \
          -H "Content-Type: application/json" \
          -d '{
            "text": "Deployment ${{ github.sha }} completed",
            "tags": ["deployment", "github-actions"],
            "time": '$(date +%s000)'
          }'
```

### Lab 9: GitOps with ArgoCD

#### GitOps Workflow
```yaml
name: GitOps Deployment

on:
  push:
    branches: [main]

jobs:
  update-manifests:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout app repo
      uses: actions/checkout@v4
      
    - name: Build and push image
      run: |
        docker build -t myregistry.io/myapp:${{ github.sha }} .
        docker push myregistry.io/myapp:${{ github.sha }}
        
    - name: Checkout GitOps repo
      uses: actions/checkout@v4
      with:
        repository: myorg/k8s-manifests
        token: ${{ secrets.GITOPS_TOKEN }}
        path: gitops
        
    - name: Update manifests
      run: |
        cd gitops
        
        # Update image tag using kustomize
        cd overlays/production
        kustomize edit set image myapp=myregistry.io/myapp:${{ github.sha }}
        
        # Or using yq for direct YAML editing
        yq e '.spec.template.spec.containers[0].image = "myregistry.io/myapp:${{ github.sha }}"' \
          -i ../../base/deployment.yaml
          
    - name: Commit and push changes
      run: |
        cd gitops
        git config user.name "github-actions[bot]"
        git config user.email "github-actions[bot]@users.noreply.github.com"
        
        git add .
        git commit -m "Update image to ${{ github.sha }}"
        git push
        
    - name: Sync ArgoCD application
      run: |
        # Optional: Force sync ArgoCD app
        curl -X POST "${{ secrets.ARGOCD_URL }}/api/v1/applications/myapp/sync" \
          -H "Authorization: Bearer ${{ secrets.ARGOCD_TOKEN }}" \
          -H "Content-Type: application/json" \
          -d '{
            "revision": "HEAD",
            "prune": true,
            "dryRun": false,
            "strategy": {
              "hook": {
                "force": true
              }
            }
          }'
```

### Lab 10: Advanced Deployment Strategies

#### Blue-Green Deployment
```yaml
name: Blue-Green Deployment

on:
  push:
    branches: [main]

env:
  IMAGE_TAG: ${{ github.sha }}

jobs:
  blue-green-deploy:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout
      uses: actions/checkout@v4
      
    - name: Determine current environment
      id: current
      run: |
        CURRENT_COLOR=$(kubectl get service myapp -o jsonpath='{.spec.selector.version}' || echo "blue")
        NEW_COLOR=$( [[ "$CURRENT_COLOR" == "blue" ]] && echo "green" || echo "blue" )
        
        echo "current-color=$CURRENT_COLOR" >> $GITHUB_OUTPUT
        echo "new-color=$NEW_COLOR" >> $GITHUB_OUTPUT
        
    - name: Deploy to inactive environment
      run: |
        NEW_COLOR="${{ steps.current.outputs.new-color }}"
        
        # Update deployment with new image and color
        kubectl patch deployment myapp-$NEW_COLOR \
          -p '{"spec":{"template":{"spec":{"containers":[{"name":"app","image":"myregistry.io/myapp:'$IMAGE_TAG'"}]},"metadata":{"labels":{"version":"'$NEW_COLOR'"}}}}}'
        
        # Wait for rollout
        kubectl rollout status deployment/myapp-$NEW_COLOR --timeout=300s
        
    - name: Health check new environment
      run: |
        NEW_COLOR="${{ steps.current.outputs.new-color }}"
        
        # Get service endpoint for testing
        kubectl port-forward service/myapp-$NEW_COLOR 8080:80 &
        PORT_FORWARD_PID=$!
        
        sleep 5
        
        # Run health checks
        for i in {1..10}; do
          if curl -f http://localhost:8080/health; then
            echo "Health check passed"
            kill $PORT_FORWARD_PID
            exit 0
          fi
          sleep 5
        done
        
        kill $PORT_FORWARD_PID
        exit 1
        
    - name: Switch traffic
      run: |
        NEW_COLOR="${{ steps.current.outputs.new-color }}"
        
        # Update service selector to point to new version
        kubectl patch service myapp -p '{"spec":{"selector":{"version":"'$NEW_COLOR'"}}}'
        
        echo "Traffic switched to $NEW_COLOR environment"
        
    - name: Cleanup old environment
      run: |
        CURRENT_COLOR="${{ steps.current.outputs.current-color }}"
        
        # Scale down old deployment after delay
        sleep 300  # Wait 5 minutes before cleanup
        kubectl scale deployment myapp-$CURRENT_COLOR --replicas=0
```

#### Canary Deployment with Flagger
```yaml
name: Canary Deployment

on:
  push:
    branches: [main]

jobs:
  canary-deploy:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout
      uses: actions/checkout@v4
      
    - name: Update canary deployment
      run: |
        # Update the primary deployment image
        kubectl set image deployment/myapp \
          app=myregistry.io/myapp:${{ github.sha }}
        
    - name: Monitor canary rollout
      run: |
        # Flagger will automatically handle the canary rollout
        # Monitor the canary object status
        
        echo "Monitoring canary rollout..."
        
        for i in {1..60}; do  # Monitor for 30 minutes
          STATUS=$(kubectl get canary myapp -o jsonpath='{.status.phase}')
          
          case $STATUS in
            "Succeeded")
              echo "Canary deployment succeeded!"
              exit 0
              ;;
            "Failed")
              echo "Canary deployment failed!"
              exit 1
              ;;
            "Progressing")
              echo "Canary deployment in progress... ($i/60)"
              ;;
            *)
              echo "Canary status: $STATUS"
              ;;
          esac
          
          sleep 30
        done
        
        echo "Canary deployment timeout"
        exit 1
```

## Best Practices

### 1. Workflow Organization
```yaml
# Use descriptive names
name: Production Deployment Pipeline

# Clear trigger conditions
on:
  push:
    branches: [main]
    paths: ['src/**', 'package.json']

# Organize jobs logically
jobs:
  validate:
    # Input validation and testing
  build:
    needs: validate
    # Build artifacts
  deploy:
    needs: build
    # Deployment steps
```

### 2. Security Best Practices
```yaml
# Minimal permissions
permissions:
  contents: read
  packages: write

# Environment protection
environment:
  name: production
  url: https://myapp.com
  
# Secret management
env:
  API_KEY: ${{ secrets.API_KEY }}
  
# Never log secrets
- name: Deploy
  run: echo "Deploying with key ${API_KEY:0:8}..."
```

### 3. Error Handling
```yaml
- name: Deploy with retry
  uses: nick-fields/retry@v2
  with:
    timeout_minutes: 10
    max_attempts: 3
    command: |
      kubectl apply -f deployment.yaml
      kubectl rollout status deployment/myapp

- name: Cleanup on failure
  if: failure()
  run: |
    kubectl rollback deployment/myapp
    kubectl delete pod -l app=myapp --field-selector=status.phase=Failed
```

### 4. Performance Optimization
```yaml
# Use caching
- name: Cache dependencies
  uses: actions/cache@v3
  with:
    path: ~/.npm
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}

# Parallel execution
jobs:
  test:
    strategy:
      matrix:
        node-version: [16, 18, 20]
    steps:
      # Test steps

# Conditional execution
- name: Deploy
  if: github.ref == 'refs/heads/main' && github.event_name == 'push'
  run: ./deploy.sh
```

## Troubleshooting

### Common Issues

#### Debug Information
```yaml
- name: Debug Context
  run: |
    echo "Event: ${{ github.event_name }}"
    echo "Ref: ${{ github.ref }}"
    echo "SHA: ${{ github.sha }}"
    echo "Actor: ${{ github.actor }}"
    echo "Workspace: ${{ github.workspace }}"
    env | sort
```

#### Secret Access Issues
```yaml
- name: Check Secret Access
  env:
    SECRET_VALUE: ${{ secrets.MY_SECRET }}
  run: |
    if [ -z "$SECRET_VALUE" ]; then
      echo "Secret is not accessible"
      exit 1
    else
      echo "Secret is accessible"
    fi
```

#### Matrix Job Debugging
```yaml
strategy:
  matrix:
    include:
      - os: ubuntu-latest
        debug: true
        
steps:
- name: Debug Matrix
  if: matrix.debug
  run: |
    echo "Matrix OS: ${{ matrix.os }}"
    echo "Debug mode: ${{ matrix.debug }}"
```

This comprehensive GitHub Actions guide covers everything from basic workflows to advanced enterprise deployment patterns, providing practical experience for real-world CI/CD scenarios.
