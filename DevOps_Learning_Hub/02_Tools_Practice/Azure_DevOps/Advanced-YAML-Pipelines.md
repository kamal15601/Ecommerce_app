# Advanced Azure DevOps YAML Pipelines

This guide covers advanced YAML pipeline techniques for Azure DevOps, focusing on real-world enterprise scenarios.

## Table of Contents

1. [Pipeline Templates](#pipeline-templates)
2. [Multi-Stage Deployments](#multi-stage-deployments)
3. [Environment Approvals](#environment-approvals)
4. [Deployment Strategies](#deployment-strategies)
5. [Container Jobs](#container-jobs)
6. [Dynamic Pipeline Generation](#dynamic-pipeline-generation)
7. [Security Scanning Integration](#security-scanning-integration)
8. [Cross-Platform Build Matrix](#cross-platform-build-matrix)
9. [Hands-on Lab: Advanced Azure DevOps Pipeline](#hands-on-lab-advanced-azure-devops-pipeline)

## Pipeline Templates

Templates allow you to define reusable content, logic, and parameters for your pipelines.

### Template Types

1. **Include Templates**: Reuse content across multiple pipelines
2. **Extend Templates**: Inherit and customize pipeline definitions
3. **Expression Templates**: Use expressions for dynamic content

### Example: Template Structure

```yaml
# azure-pipelines-templates/steps/build.yml
parameters:
  buildConfiguration: 'Release'
  buildPlatform: 'Any CPU'

steps:
- task: DotNetCoreCLI@2
  displayName: 'Build solution'
  inputs:
    command: 'build'
    projects: '**/*.csproj'
    arguments: '--configuration ${{ parameters.buildConfiguration }} --framework net6.0'
```

### Example: Using Templates

```yaml
# azure-pipelines.yml
trigger:
- main

pool:
  vmImage: 'ubuntu-latest'

steps:
- template: azure-pipelines-templates/steps/build.yml
  parameters:
    buildConfiguration: 'Debug'
```

### Template Libraries

You can store templates in separate repositories and reference them across multiple projects:

```yaml
resources:
  repositories:
  - repository: templates
    type: git
    name: YourOrg/pipeline-templates

steps:
- template: common/build.yml@templates
  parameters:
    buildConfiguration: 'Release'
```

## Multi-Stage Deployments

Multi-stage pipelines allow you to organize your deployment into distinct phases.

### Example: Three-Environment Deployment

```yaml
stages:
- stage: Build
  jobs:
  - job: BuildApp
    pool:
      vmImage: 'ubuntu-latest'
    steps:
    - script: echo "Building application"
    - task: PublishPipelineArtifact@1
      inputs:
        targetPath: '$(Build.ArtifactStagingDirectory)'
        artifactName: 'drop'

- stage: DeployToDev
  dependsOn: Build
  condition: succeeded()
  jobs:
  - deployment: DeployToDev
    environment: 'Development'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: DownloadPipelineArtifact@2
            inputs:
              artifactName: 'drop'
          - script: echo "Deploying to Dev"

- stage: DeployToStaging
  dependsOn: DeployToDev
  jobs:
  - deployment: DeployToStaging
    environment: 'Staging'
    strategy:
      runOnce:
        deploy:
          steps:
          - script: echo "Deploying to Staging"

- stage: DeployToProduction
  dependsOn: DeployToStaging
  jobs:
  - deployment: DeployToProduction
    environment: 'Production'
    strategy:
      runOnce:
        deploy:
          steps:
          - script: echo "Deploying to Production"
```

## Environment Approvals

Configure approval gates for deployments to sensitive environments:

1. Go to **Pipelines** > **Environments**
2. Select or create the environment (e.g., "Production")
3. Click **Approvals and checks**
4. Add an **Approval** check and configure approvers

Now deployments to the environment will pause for manual approval:

```yaml
jobs:
- deployment: DeployToProduction
  environment: 'Production'  # This environment has approvals configured
  strategy:
    runOnce:
      deploy:
        steps:
        - script: echo "Deploying to Production"
```

## Deployment Strategies

Azure DevOps supports multiple deployment strategies:

### 1. RunOnce Strategy

Simple strategy for basic deployments:

```yaml
strategy:
  runOnce:
    deploy:
      steps:
      - script: echo "Simple deployment"
```

### 2. Rolling Strategy

Gradually update deployment targets in phases:

```yaml
strategy:
  rolling:
    maxParallel: 2  # Number of targets to deploy to in parallel
    preDeploy:
      steps:
      - script: echo "Pre-deployment tasks"
    deploy:
      steps:
      - script: echo "Deployment tasks"
    postRouteTraffic:
      steps:
      - script: echo "Post-route traffic tasks"
    routeTraffic:
      steps:
      - script: echo "Routing traffic to updated instances"
    postDeploy:
      steps:
      - script: echo "Post-deployment tasks"
```

### 3. Canary Strategy

Deploy to a small set of servers/users first, then roll out to the rest:

```yaml
strategy:
  canary:
    increments: [10, 20, 70]  # Deploy to 10%, then 30%, then 100%
    preDeploy:
      steps:
      - script: echo "Pre-deployment tasks"
    deploy:
      steps:
      - script: echo "Deployment tasks"
    postRouteTraffic:
      steps:
      - script: echo "Post-route traffic tasks"
    routeTraffic:
      steps:
      - script: echo "Routing traffic to updated instances"
    postDeploy:
      steps:
      - script: echo "Post-deployment tasks"
```

## Container Jobs

Run your pipeline steps inside a container for consistent build environments:

```yaml
jobs:
- job: BuildInContainer
  pool:
    vmImage: 'ubuntu-latest'
  container: 
    image: mcr.microsoft.com/dotnet/sdk:6.0
  steps:
  - script: |
      dotnet --version
      dotnet build
```

### Using Service Containers

Run dependent services in containers:

```yaml
jobs:
- job: TestWithDatabase
  pool:
    vmImage: 'ubuntu-latest'
  services:
    postgres:
      image: postgres:13
      ports:
        - 5432:5432
      env:
        POSTGRES_PASSWORD: example
        POSTGRES_USER: testuser
        POSTGRES_DB: testdb
  steps:
  - script: |
      # Connect to postgres service container
      PGPASSWORD=example psql -h localhost -U testuser -d testdb -c "SELECT 1;"
```

## Dynamic Pipeline Generation

Use template expressions to generate parts of your pipeline dynamically:

```yaml
parameters:
- name: deployToEnvironments
  type: object
  default:
  - name: Development
    serviceName: dev-service
    resourceGroup: dev-rg
  - name: Staging
    serviceName: staging-service
    resourceGroup: staging-rg
  - name: Production
    serviceName: prod-service
    resourceGroup: prod-rg

stages:
- stage: Build
  jobs:
  - job: BuildApp
    steps:
    - script: echo "Building application"

# Dynamically generate stages based on parameter
- ${{ each environment in parameters.deployToEnvironments }}:
  - stage: DeployTo${{ environment.name }}
    dependsOn: Build
    jobs:
    - deployment: Deploy
      environment: ${{ environment.name }}
      strategy:
        runOnce:
          deploy:
            steps:
            - script: echo "Deploying to ${{ environment.name }}"
            - task: AzureCLI@2
              inputs:
                azureSubscription: 'YourAzureConnection'
                scriptType: 'bash'
                scriptLocation: 'inlineScript'
                inlineScript: |
                  az webapp deployment source config-zip \
                    --resource-group ${{ environment.resourceGroup }} \
                    --name ${{ environment.serviceName }} \
                    --src $(System.ArtifactsDirectory)/drop/app.zip
```

## Security Scanning Integration

Integrate security scanning tools into your pipeline:

```yaml
stages:
- stage: Build
  jobs:
  - job: BuildAndScan
    pool:
      vmImage: 'ubuntu-latest'
    steps:
    - task: DotNetCoreCLI@2
      displayName: 'Build application'
      inputs:
        command: 'build'
        projects: '**/*.csproj'
    
    # Dependency scanning
    - task: WhiteSource@21
      inputs:
        cwd: '$(System.DefaultWorkingDirectory)'
        projectName: '$(Build.Repository.Name)'
    
    # SAST scanning
    - task: SonarCloudPrepare@1
      inputs:
        SonarCloud: 'SonarCloud Connection'
        organization: 'your-org'
        scannerMode: 'MSBuild'
        projectKey: 'your-project-key'
    
    - task: DotNetCoreCLI@2
      inputs:
        command: 'build'
        projects: '**/*.csproj'
    
    - task: SonarCloudAnalyze@1
    - task: SonarCloudPublish@1
      inputs:
        pollingTimeoutSec: '300'
    
    # Container image scanning
    - task: AquaSecurityScan@5
      inputs:
        image: 'yourregistry.azurecr.io/yourimage:$(Build.BuildId)'
        cliScanOptions: '--hide-base --severity-threshold=1'
```

## Cross-Platform Build Matrix

Build and test your application across multiple platforms and configurations:

```yaml
jobs:
- job: CrossPlatformBuild
  strategy:
    matrix:
      linux:
        imageName: 'ubuntu-latest'
        buildPrefix: 'linux'
      mac:
        imageName: 'macOS-latest'
        buildPrefix: 'mac'
      windows:
        imageName: 'windows-latest'
        buildPrefix: 'win'
  pool:
    vmImage: $(imageName)
  steps:
  - script: echo "Building on $(imageName) with prefix $(buildPrefix)"

  - ${{ if eq(variables['Agent.OS'], 'Linux') }}:
    - script: echo "Running Linux-specific build steps"
  
  - ${{ if eq(variables['Agent.OS'], 'Darwin') }}:
    - script: echo "Running macOS-specific build steps"
  
  - ${{ if eq(variables['Agent.OS'], 'Windows_NT') }}:
    - script: echo "Running Windows-specific build steps"
```

## Hands-on Lab: Advanced Azure DevOps Pipeline

Let's create an advanced multi-stage pipeline for a containerized application with security scanning, testing, and deployment to multiple environments.

### Prerequisites

1. Azure DevOps account
2. Azure subscription
3. Source code repository (e.g., a simple web application)
4. Azure Container Registry
5. Azure App Service or AKS cluster

### Step 1: Create a YAML Pipeline Template Repository

Create a new repository called `pipeline-templates` with the following folder structure:

```
pipeline-templates/
├── jobs/
│   ├── build.yml
│   ├── security-scan.yml
│   ├── test.yml
│   └── deploy.yml
├── steps/
│   ├── build-docker-image.yml
│   ├── push-docker-image.yml
│   └── run-tests.yml
└── variables/
    ├── dev.yml
    ├── staging.yml
    └── prod.yml
```

### Step 2: Create Template Files

Create the job templates:

1. **jobs/build.yml**:

```yaml
parameters:
  buildConfiguration: 'Release'
  dockerfilePath: 'Dockerfile'
  containerRegistry: ''
  imageRepository: ''

jobs:
- job: Build
  displayName: 'Build and Push Docker Image'
  pool:
    vmImage: 'ubuntu-latest'
  steps:
  - template: ../steps/build-docker-image.yml
    parameters:
      dockerfilePath: ${{ parameters.dockerfilePath }}
      buildConfiguration: ${{ parameters.buildConfiguration }}
      
  - template: ../steps/push-docker-image.yml
    parameters:
      containerRegistry: ${{ parameters.containerRegistry }}
      imageRepository: ${{ parameters.imageRepository }}
```

2. **steps/build-docker-image.yml**:

```yaml
parameters:
  dockerfilePath: 'Dockerfile'
  buildConfiguration: 'Release'

steps:
- task: Docker@2
  displayName: 'Build Docker image'
  inputs:
    command: 'build'
    Dockerfile: ${{ parameters.dockerfilePath }}
    buildContext: '$(Build.SourcesDirectory)'
    arguments: '--build-arg CONFIGURATION=${{ parameters.buildConfiguration }}'
    tags: |
      $(Build.BuildId)
      latest
```

3. **steps/push-docker-image.yml**:

```yaml
parameters:
  containerRegistry: ''
  imageRepository: ''

steps:
- task: Docker@2
  displayName: 'Push Docker image'
  inputs:
    containerRegistry: ${{ parameters.containerRegistry }}
    repository: ${{ parameters.imageRepository }}
    command: 'push'
    tags: |
      $(Build.BuildId)
      latest
```

4. **jobs/security-scan.yml**:

```yaml
parameters:
  imageToScan: ''
  severityThreshold: 'MEDIUM'

jobs:
- job: SecurityScan
  displayName: 'Run Security Scans'
  pool:
    vmImage: 'ubuntu-latest'
  steps:
  - task: SonarCloudPrepare@1
    inputs:
      SonarCloud: 'SonarCloud'
      organization: '$(SonarCloudOrg)'
      scannerMode: 'CLI'
      configMode: 'manual'
      cliProjectKey: '$(Build.Repository.Name)'
      cliProjectName: '$(Build.Repository.Name)'
      cliSources: '.'
      
  - task: SonarCloudAnalyze@1
  
  - task: ContainerScan@0
    inputs:
      dockerImage: ${{ parameters.imageToScan }}
      severityThreshold: ${{ parameters.severityThreshold }}
```

### Step 3: Main Pipeline File

Create your main `azure-pipelines.yml` file:

```yaml
trigger:
- main

resources:
  repositories:
  - repository: templates
    type: git
    name: YourOrg/pipeline-templates

variables:
  dockerRegistryServiceConnection: 'your-acr-connection'
  imageRepository: 'your-app'
  containerRegistry: 'yourregistry.azurecr.io'
  dockerfilePath: '$(Build.SourcesDirectory)/Dockerfile'
  tag: '$(Build.BuildId)'

stages:
- stage: Build
  displayName: 'Build and Push'
  jobs:
  - template: jobs/build.yml@templates
    parameters:
      buildConfiguration: 'Release'
      dockerfilePath: $(dockerfilePath)
      containerRegistry: $(dockerRegistryServiceConnection)
      imageRepository: $(imageRepository)

- stage: Test
  displayName: 'Test and Scan'
  dependsOn: Build
  jobs:
  - template: jobs/security-scan.yml@templates
    parameters:
      imageToScan: '$(containerRegistry)/$(imageRepository):$(tag)'
      severityThreshold: 'HIGH'

- stage: DeployToDev
  displayName: 'Deploy to Development'
  dependsOn: Test
  condition: succeeded()
  variables:
  - template: variables/dev.yml@templates
  jobs:
  - deployment: DeployToDev
    environment: 'Development'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureWebAppContainer@1
            inputs:
              azureSubscription: 'your-azure-connection'
              appName: '$(appServiceName)'
              containers: '$(containerRegistry)/$(imageRepository):$(tag)'

- stage: DeployToStaging
  displayName: 'Deploy to Staging'
  dependsOn: DeployToDev
  variables:
  - template: variables/staging.yml@templates
  jobs:
  - deployment: DeployToStaging
    environment: 'Staging'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureWebAppContainer@1
            inputs:
              azureSubscription: 'your-azure-connection'
              appName: '$(appServiceName)'
              containers: '$(containerRegistry)/$(imageRepository):$(tag)'

- stage: DeployToProduction
  displayName: 'Deploy to Production'
  dependsOn: DeployToStaging
  variables:
  - template: variables/prod.yml@templates
  jobs:
  - deployment: DeployToProduction
    environment: 'Production'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureWebAppContainer@1
            inputs:
              azureSubscription: 'your-azure-connection'
              appName: '$(appServiceName)'
              containers: '$(containerRegistry)/$(imageRepository):$(tag)'
```

### Step 4: Environment-Specific Variables

Create your environment variable files:

1. **variables/dev.yml**:

```yaml
variables:
  appServiceName: 'your-app-dev'
  environmentName: 'Development'
  appSettings: '-ASPNETCORE_ENVIRONMENT Development'
```

2. **variables/staging.yml**:

```yaml
variables:
  appServiceName: 'your-app-staging'
  environmentName: 'Staging'
  appSettings: '-ASPNETCORE_ENVIRONMENT Staging'
```

3. **variables/prod.yml**:

```yaml
variables:
  appServiceName: 'your-app-prod'
  environmentName: 'Production'
  appSettings: '-ASPNETCORE_ENVIRONMENT Production'
```

### Step 5: Set Up Environments and Approvals

1. In your Azure DevOps project, go to **Pipelines** > **Environments**
2. Create environments: Development, Staging, Production
3. For Staging and Production, configure approval checks:
   - Select the environment > **Approvals and checks** > **Approvals**
   - Add approvers for each environment
   - Set timeout and instructions

### Step 6: Run the Pipeline

Commit all files and run the pipeline. Observe:

1. The build stage creates and pushes the Docker image
2. The test stage runs security scans
3. The deployment stages require approvals before proceeding
4. Each environment uses specific configuration values

This hands-on lab demonstrates advanced Azure DevOps pipeline features including:
- Template reuse
- Multi-stage deployments
- Environment approvals
- Security scanning
- Environment-specific configurations
