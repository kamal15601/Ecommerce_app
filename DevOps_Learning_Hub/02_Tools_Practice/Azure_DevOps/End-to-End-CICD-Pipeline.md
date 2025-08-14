# End-to-End CI/CD Pipeline with Azure DevOps (2025 Edition)

This guide provides a comprehensive walkthrough for creating a complete end-to-end CI/CD pipeline using Azure DevOps, covering all stages from code commit to production deployment. Updated for 2025 with the latest features, integrations, and best practices.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Pipeline Overview](#pipeline-overview)
3. [Azure DevOps Setup](#azure-devops-setup)
4. [Pipeline Definition](#pipeline-definition)
5. [Pipeline Stages in Detail](#pipeline-stages-in-detail)
6. [Environment Management](#environment-management)
7. [Secrets and Configuration](#secrets-and-configuration)
8. [Advanced Azure DevOps Features](#advanced-azure-devops-features)
9. [Monitoring Your Pipeline](#monitoring-your-pipeline)
10. [Hands-on Exercises](#hands-on-exercises)
11. [Troubleshooting](#troubleshooting)

## Prerequisites

Before getting started, ensure you have:

- Azure DevOps organization and project
- Basic understanding of YAML
- Application code in an Azure Repos Git repository or GitHub repository
- Docker and/or Kubernetes environment
- Azure subscription for cloud deployments
- Service principal or managed identity for Azure authentication

## Pipeline Overview

Our end-to-end CI/CD pipeline consists of the following stages:

```
Code Commit → Build → Test → Static Analysis → Security Scan → Artifact Creation → Deploy to Dev → Integration Tests → Deploy to Staging → Performance Tests → Manual Approval → Deploy to Production → Monitoring
```

![Azure DevOps Pipeline Flow](https://example.com/azure-devops-pipeline-diagram.png)

## Azure DevOps Setup

### 1. Creating Your First Pipeline

1. Navigate to your Azure DevOps project
2. Go to Pipelines > Pipelines
3. Click "New pipeline"
4. Select your repository source (Azure Repos Git, GitHub, etc.)
5. Select your repository
6. Choose "Starter pipeline" or a template relevant to your project
7. Edit the YAML file to define your pipeline
8. Click "Save and run"

### 2. Setting Up Environments

1. Go to Pipelines > Environments
2. Click "New environment"
3. Enter a name (e.g., "Development", "Staging", "Production")
4. Choose the environment type (Virtual machine or Kubernetes)
5. Configure the environment resources
6. Set up approvals and checks

## Pipeline Definition

Here's a comprehensive multi-stage YAML pipeline definition for a typical application:

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
  # Build variables
  buildConfiguration: 'Release'
  vmImageName: 'ubuntu-latest'
  
  # Docker variables
  containerRegistry: 'mycontainerregistry.azurecr.io'
  imageName: 'myapp'
  imageTag: '$(Build.BuildId)'
  
  # Environment URLs
  devUrl: 'https://dev.myapp.com'
  stagingUrl: 'https://staging.myapp.com'
  productionUrl: 'https://myapp.com'

stages:
- stage: Build
  displayName: 'Build and Test'
  jobs:
  - job: BuildJob
    pool:
      vmImage: $(vmImageName)
    steps:
    - task: DotNetCoreCLI@2
      displayName: 'Restore packages'
      inputs:
        command: 'restore'
        projects: '**/*.csproj'
        
    - task: DotNetCoreCLI@2
      displayName: 'Build solution'
      inputs:
        command: 'build'
        projects: '**/*.csproj'
        arguments: '--configuration $(buildConfiguration)'
        
    - task: DotNetCoreCLI@2
      displayName: 'Run unit tests'
      inputs:
        command: 'test'
        projects: '**/*Tests/*.csproj'
        arguments: '--configuration $(buildConfiguration) --collect "Code coverage"'
        
    - task: WhiteSource@21
      displayName: 'Run WhiteSource Bolt'
      inputs:
        cwd: '$(System.DefaultWorkingDirectory)'
        
    - task: Docker@2
      displayName: 'Build and push Docker image'
      inputs:
        containerRegistry: 'myACRConnection'
        repository: '$(imageName)'
        command: 'buildAndPush'
        Dockerfile: '**/Dockerfile'
        tags: |
          $(imageTag)
          latest
          
    - task: PublishPipelineArtifact@1
      displayName: 'Publish deployment scripts'
      inputs:
        targetPath: '$(System.DefaultWorkingDirectory)/deploy'
        artifact: 'DeploymentScripts'

- stage: DeployToDev
  displayName: 'Deploy to Development'
  dependsOn: Build
  condition: succeeded()
  jobs:
  - deployment: DeployToDev
    displayName: 'Deploy to Dev environment'
    environment: 'Development'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: DownloadPipelineArtifact@2
            inputs:
              artifactName: 'DeploymentScripts'
              downloadPath: '$(System.ArtifactsDirectory)/deploy'
              
          - task: AzureWebAppContainer@1
            displayName: 'Deploy to Azure Web App'
            inputs:
              azureSubscription: 'myAzureConnection'
              appName: 'myapp-dev'
              containers: '$(containerRegistry)/$(imageName):$(imageTag)'
              
          - task: PowerShell@2
            displayName: 'Run smoke tests'
            inputs:
              targetType: 'inline'
              script: |
                $statusCode = (Invoke-WebRequest -Uri "$(devUrl)/health" -UseBasicParsing).StatusCode
                if ($statusCode -ne 200) {
                  Write-Error "Health check failed with status code $statusCode"
                  exit 1
                }

- stage: RunIntegrationTests
  displayName: 'Run Integration Tests'
  dependsOn: DeployToDev
  condition: succeeded()
  jobs:
  - job: IntegrationTests
    displayName: 'Execute integration tests'
    pool:
      vmImage: $(vmImageName)
    steps:
    - task: DotNetCoreCLI@2
      displayName: 'Run integration tests'
      inputs:
        command: 'test'
        projects: '**/*IntegrationTests/*.csproj'
        arguments: '--configuration $(buildConfiguration)'
        
- stage: DeployToStaging
  displayName: 'Deploy to Staging'
  dependsOn: RunIntegrationTests
  condition: succeeded()
  jobs:
  - deployment: DeployToStaging
    displayName: 'Deploy to Staging environment'
    environment: 'Staging'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: DownloadPipelineArtifact@2
            inputs:
              artifactName: 'DeploymentScripts'
              downloadPath: '$(System.ArtifactsDirectory)/deploy'
              
          - task: AzureWebAppContainer@1
            displayName: 'Deploy to Azure Web App'
            inputs:
              azureSubscription: 'myAzureConnection'
              appName: 'myapp-staging'
              containers: '$(containerRegistry)/$(imageName):$(imageTag)'
              
          - task: PowerShell@2
            displayName: 'Run health check'
            inputs:
              targetType: 'inline'
              script: |
                $statusCode = (Invoke-WebRequest -Uri "$(stagingUrl)/health" -UseBasicParsing).StatusCode
                if ($statusCode -ne 200) {
                  Write-Error "Health check failed with status code $statusCode"
                  exit 1
                }

- stage: RunPerformanceTests
  displayName: 'Run Performance Tests'
  dependsOn: DeployToStaging
  condition: succeeded()
  jobs:
  - job: PerformanceTests
    displayName: 'Execute performance tests'
    pool:
      vmImage: $(vmImageName)
    steps:
    - task: JMeterInstaller@0
      displayName: 'Install JMeter'
      inputs:
        jmeterVersion: '5.4.1'
        
    - task: CmdLine@2
      displayName: 'Run JMeter tests'
      inputs:
        script: |
          jmeter -n -t $(System.DefaultWorkingDirectory)/tests/performance/load-test.jmx -l results.jtl -e -o report
          
    - task: PublishPipelineArtifact@1
      displayName: 'Publish performance test results'
      inputs:
        targetPath: 'report'
        artifact: 'PerformanceTestResults'

- stage: DeployToProduction
  displayName: 'Deploy to Production'
  dependsOn: RunPerformanceTests
  condition: succeeded()
  jobs:
  - deployment: DeployToProduction
    displayName: 'Deploy to Production environment'
    environment: 'Production'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: DownloadPipelineArtifact@2
            inputs:
              artifactName: 'DeploymentScripts'
              downloadPath: '$(System.ArtifactsDirectory)/deploy'
              
          - task: AzureWebAppContainer@1
            displayName: 'Deploy to Azure Web App'
            inputs:
              azureSubscription: 'myAzureConnection'
              appName: 'myapp-prod'
              containers: '$(containerRegistry)/$(imageName):$(imageTag)'
              
          - task: PowerShell@2
            displayName: 'Run post-deployment validation'
            inputs:
              targetType: 'inline'
              script: |
                $statusCode = (Invoke-WebRequest -Uri "$(productionUrl)/health" -UseBasicParsing).StatusCode
                if ($statusCode -ne 200) {
                  Write-Error "Health check failed with status code $statusCode"
                  exit 1
                }
```

## Pipeline Stages in Detail

### 1. Build and Test

The first stage of the pipeline builds the application, runs unit tests, performs static code analysis, and packages the application into a deployable artifact.

Key tasks:
- Source code checkout
- Package restoration
- Code compilation
- Unit testing
- Code coverage analysis
- Static code analysis (e.g., SonarQube)
- Security scanning (e.g., WhiteSource Bolt)
- Docker image creation
- Artifact creation

### 2. Deploy to Development

This stage deploys the application to the development environment.

Key tasks:
- Download deployment artifacts
- Deploy to Azure Web App or Kubernetes
- Run basic health checks

### 3. Integration Tests

After the application is deployed to the development environment, this stage runs integration tests to ensure that all components work together.

Key tasks:
- Run API tests
- Run database integration tests
- Run UI automation tests

### 4. Deploy to Staging

This stage deploys the application to the staging environment, which should closely mirror the production environment.

Key tasks:
- Deploy to staging environment
- Run health checks
- Validate configuration

### 5. Performance Tests

This stage runs performance tests against the staging environment to ensure that the application meets performance requirements.

Key tasks:
- Run load tests
- Run stress tests
- Analyze performance metrics

### 6. Deploy to Production

The final stage deploys the application to the production environment.

Key tasks:
- Obtain approvals
- Deploy to production
- Run health checks
- Monitor deployment

## Environment Management

### Managing Multiple Environments

Azure DevOps environments provide a way to group deployment targets (VMs, Kubernetes clusters, etc.) and apply security controls like approvals.

#### Environment Approvals

To add approvals to an environment:

1. Go to Pipelines > Environments
2. Select the environment
3. Click on the three dots and select "Checks"
4. Click "Add check" and select "Approvals"
5. Add required approvers and set options like timeout and instructions
6. Click "Create"

#### Environment Security

To secure your environments:

- Limit who can create and manage environments
- Use approvals for sensitive environments
- Implement branch policies to protect important branches
- Use service connections with restricted permissions

## Secrets and Configuration

### Managing Secrets

Use Azure Key Vault to store sensitive information:

1. Create a Key Vault in Azure
2. Add your secrets to the Key Vault
3. Create a service connection to Azure in Azure DevOps
4. Use the Azure Key Vault task in your pipeline:

```yaml
- task: AzureKeyVault@1
  inputs:
    azureSubscription: 'myAzureConnection'
    KeyVaultName: 'myKeyVault'
    SecretsFilter: 'secretName1,secretName2'
```

### Configuration Management

For managing environment-specific configuration:

1. Create variable groups for each environment
2. Link variable groups to your pipeline
3. Use variable substitution in your configuration files

```yaml
variables:
- group: development-variables
- group: common-variables

steps:
- task: FileTransform@1
  inputs:
    folderPath: '$(System.DefaultWorkingDirectory)/**/*.config.json'
    fileType: 'json'
    targetFiles: '**/*.config.json'
```

## Advanced Azure DevOps Features

### Pipeline Templates

Create reusable templates to standardize common processes:

```yaml
# templates/build.yml
parameters:
  buildConfiguration: 'Release'
  
steps:
- task: DotNetCoreCLI@2
  displayName: 'Build solution'
  inputs:
    command: 'build'
    projects: '**/*.csproj'
    arguments: '--configuration ${{ parameters.buildConfiguration }}'
```

To use the template:

```yaml
stages:
- stage: Build
  jobs:
  - job: BuildJob
    steps:
    - template: templates/build.yml
      parameters:
        buildConfiguration: $(buildConfiguration)
```

### Deployment Strategies

Azure DevOps supports several deployment strategies:

#### Blue-Green Deployment

```yaml
strategy:
  runOnce:
    deploy:
      steps:
      - task: AzureWebAppContainer@1
        inputs:
          azureSubscription: 'myAzureConnection'
          resourceGroupName: 'myResourceGroup'
          appName: 'myapp-blue'
          containers: '$(containerRegistry)/$(imageName):$(imageTag)'
          
      # Switch traffic from green to blue
      - task: AzureCLI@2
        inputs:
          azureSubscription: 'myAzureConnection'
          scriptType: 'bash'
          scriptLocation: 'inlineScript'
          inlineScript: |
            az webapp traffic-routing set --distribution myapp-blue=100 myapp-green=0 --resource-group myResourceGroup --name myapp
```

#### Canary Deployment

```yaml
strategy:
  runOnce:
    deploy:
      steps:
      # Deploy to canary
      - task: AzureWebAppContainer@1
        inputs:
          azureSubscription: 'myAzureConnection'
          appName: 'myapp-canary'
          containers: '$(containerRegistry)/$(imageName):$(imageTag)'
          
      # Monitor canary
      - task: PowerShell@2
        inputs:
          targetType: 'inline'
          script: |
            # Monitor for 15 minutes
            $startTime = Get-Date
            $endTime = $startTime.AddMinutes(15)
            
            while ((Get-Date) -lt $endTime) {
              # Check health
              $status = Invoke-RestMethod -Uri "https://myapp-canary.azurewebsites.net/health"
              if ($status.status -ne "healthy") {
                Write-Error "Canary is unhealthy"
                exit 1
              }
              
              Start-Sleep -Seconds 30
            }
            
      # Deploy to production
      - task: AzureWebAppContainer@1
        inputs:
          azureSubscription: 'myAzureConnection'
          appName: 'myapp'
          containers: '$(containerRegistry)/$(imageName):$(imageTag)'
```

## Monitoring Your Pipeline

### Pipeline Analytics

Azure DevOps provides built-in analytics for your pipelines:

1. Go to Pipelines > Pipelines
2. Select your pipeline
3. Click on "Analytics"
4. View metrics like pipeline duration, success rate, and test results

### Integrating with Application Insights

To monitor your application after deployment:

1. Create an Application Insights resource in Azure
2. Add the Application Insights SDK to your application
3. Use Application Insights to monitor application performance, usage, and errors

```yaml
- task: AzureAppServiceSettings@1
  inputs:
    azureSubscription: 'myAzureConnection'
    appName: 'myapp'
    resourceGroupName: 'myResourceGroup'
    appSettings: |
      [
        {
          "name": "APPLICATIONINSIGHTS_CONNECTION_STRING",
          "value": "InstrumentationKey=00000000-0000-0000-0000-000000000000",
          "slotSetting": false
        }
      ]
```

## Hands-on Exercises

### Exercise 1: Create a Basic CI/CD Pipeline

**Objective**: Create a pipeline that builds and deploys a simple web application.

1. Create a new Azure DevOps project
2. Import a sample application from: https://github.com/microsoft/dotnet-core-sample-templates
3. Create a new pipeline in Azure DevOps pointing to your repository
4. Configure the pipeline to build and test the application
5. Add a deployment stage to deploy to Azure App Service

### Exercise 2: Implement Continuous Deployment with Approvals

**Objective**: Enhance your pipeline with multiple environments and approval gates.

1. Create Dev, Staging, and Production environments in Azure DevOps
2. Configure approvals for the Staging and Production environments
3. Modify your pipeline to deploy to all three environments
4. Add health checks between deployments
5. Test the approval workflow

### Exercise 3: Implement a Complete DevOps Pipeline

**Objective**: Create a comprehensive pipeline with all the stages covered in this guide.

1. Create a new pipeline with separate stages for:
   - Build and test
   - Security scanning
   - Deployment to Dev
   - Integration testing
   - Deployment to Staging
   - Performance testing
   - Deployment to Production
2. Add appropriate approval gates
3. Implement monitoring and alerting
4. Document your pipeline architecture

## Troubleshooting

### Common Pipeline Issues

#### Build Failures

- **Problem**: Build fails due to missing dependencies
- **Solution**: Ensure all dependencies are correctly specified and available to the build agent

#### Deployment Failures

- **Problem**: Deployment fails with access denied
- **Solution**: Check service connection permissions and ensure the identity has necessary permissions

#### Test Failures

- **Problem**: Tests pass locally but fail in the pipeline
- **Solution**: Check for environment-specific issues, ensure test dependencies are available

### Debugging Techniques

1. **Enable diagnostic logging**:
   ```yaml
   steps:
   - task: PowerShell@2
     inputs:
       targetType: 'inline'
       script: |
         Write-Host "##vso[task.setvariable variable=system.debug]true"
   ```

2. **Use pipeline artifacts to preserve logs**:
   ```yaml
   - task: PublishPipelineArtifact@1
     inputs:
       targetPath: '$(System.DefaultWorkingDirectory)/logs'
       artifact: 'DiagnosticLogs'
   ```

3. **Monitor pipeline runs in real-time**:
   - Navigate to your running pipeline
   - Click on the job to see detailed logs
   - Use the Live Console to see output as it happens

## Resources

- [Azure DevOps Documentation](https://docs.microsoft.com/en-us/azure/devops/)
- [Microsoft Learn - DevOps Modules](https://docs.microsoft.com/en-us/learn/browse/?products=azure-devops)
- [Azure Pipeline Tasks Reference](https://docs.microsoft.com/en-us/azure/devops/pipelines/tasks/)
- [Azure DevOps Labs](https://azuredevopslabs.com/)

## Conclusion

This guide has covered the end-to-end process of creating a CI/CD pipeline in Azure DevOps, from initial setup to advanced deployment strategies. By following these practices, you can create robust, automated pipelines that improve the quality and reliability of your software delivery process.

Remember that CI/CD is not just about tools but also about culture and processes. Continuously evaluate and improve your pipeline to adapt to your team's evolving needs and the changing technology landscape.
