# Azure Security Best Practices for DevOps

This guide covers comprehensive security best practices for Azure DevOps, focusing on implementing a secure DevOps lifecycle for Azure cloud resources.

## Table of Contents

1. [Secure CI/CD Pipelines](#secure-cicd-pipelines)
2. [Infrastructure as Code (IaC) Security](#infrastructure-as-code-security)
3. [Secret Management](#secret-management)
4. [Container Security](#container-security)
5. [Identity and Access Management](#identity-and-access-management)
6. [Monitoring and Threat Detection](#monitoring-and-threat-detection)
7. [Compliance and Governance](#compliance-and-governance)
8. [Secure Development Practices](#secure-development-practices)
9. [Hands-on Lab: Implementing Azure DevSecOps](#hands-on-lab-implementing-azure-devsecops)

## Secure CI/CD Pipelines

### Pipeline Security Best Practices

1. **Service Connection Security**
   - Use service principals with minimum required permissions
   - Regularly rotate service principal credentials
   - Implement approval workflows for service connections

2. **Build Agent Security**
   - Use Microsoft-hosted agents when possible
   - If using self-hosted agents, secure network access
   - Apply security patches regularly to self-hosted agents

3. **Branch Policies**
   - Enforce branch protection rules
   - Require PR reviews before merging
   - Set up status checks for security scans

4. **Pipeline Configuration**
   - Use YAML pipelines stored in the repository
   - Disable direct pushes to protected branches
   - Implement pipeline templates for security controls

### Example: Secure YAML Pipeline

```yaml
trigger:
- main

pr:
  branches:
    include:
    - main
  drafts: false

pool:
  vmImage: 'ubuntu-latest'

stages:
- stage: SecurityChecks
  jobs:
  - job: CodeAnalysis
    steps:
    - task: SonarCloudPrepare@1
      inputs:
        SonarCloud: 'SonarCloud'
        organization: 'your-organization'
        scannerMode: 'MSBuild'
        projectKey: 'your-project-key'
    
    - task: DotNetCoreCLI@2
      inputs:
        command: 'build'
    
    - task: SonarCloudAnalyze@1
    
    - task: SonarCloudPublish@1
  
  - job: DependencyCheck
    steps:
    - task: dependency-check-build-task@5
      inputs:
        projectName: 'YourProject'
        scanPath: '$(Build.SourcesDirectory)'
        format: 'HTML,JSON'
    
    - task: PublishBuildArtifacts@1
      inputs:
        pathToPublish: '$(Agent.BuildDirectory)/dependency-check-report.html'
        artifactName: 'DependencyCheckReport'

- stage: Build
  dependsOn: SecurityChecks
  condition: succeeded('SecurityChecks')
  jobs:
  - job: BuildJob
    steps:
    - task: DotNetCoreCLI@2
      inputs:
        command: 'build'
```

## Infrastructure as Code Security

### Secure IaC Practices

1. **Code Review**
   - Mandatory peer review for all IaC changes
   - Use linters and static analysis tools
   - Validate IaC before deployment

2. **Security Scanning**
   - Scan IaC templates for security misconfigurations
   - Integrate security scanning in CI/CD pipelines
   - Fail builds when critical issues are found

3. **Least Privilege**
   - Apply least privilege principles in IaC templates
   - Use managed identities instead of service principals
   - Avoid hardcoded secrets in templates

### Tools for IaC Security

1. **Azure Resource Manager Template Toolkit (arm-ttk)**
   - Validate ARM templates against best practices
   - Identify potential security issues
   - Enforce consistency

2. **Checkov**
   - Scan Terraform, ARM, Bicep templates
   - Identify misconfigurations and security issues
   - Integrate with CI/CD pipelines

3. **Terrascan**
   - Detect compliance and security violations
   - Support for Azure and multi-cloud environments
   - Policy as code for IaC

### Example: Secure Bicep Template

```bicep
@description('The location where resources will be deployed.')
param location string = resourceGroup().location

@description('The name of the Azure Key Vault')
param keyVaultName string

@description('The Azure AD tenant ID that should be used for authenticating requests to the key vault.')
param tenantId string = subscription().tenantId

// Secure parameter for SQL admin password
@secure()
param sqlAdminPassword string

resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: keyVaultName
  location: location
  properties: {
    enableRbacAuthorization: true
    tenantId: tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
}

resource sqlServer 'Microsoft.Sql/servers@2021-02-01-preview' = {
  name: 'sql-${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    administratorLogin: 'sqladmin'
    administratorLoginPassword: sqlAdminPassword
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Disabled'
  }
}

resource sqlFirewallRule 'Microsoft.Sql/servers/firewallRules@2021-02-01-preview' = {
  parent: sqlServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Store SQL password in Key Vault
resource sqlPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  parent: keyVault
  name: 'sqlAdminPassword'
  properties: {
    value: sqlAdminPassword
  }
}
```

## Secret Management

### Azure Key Vault Best Practices

1. **Access Control**
   - Use RBAC for Key Vault access
   - Implement Managed Identities for services
   - Apply just-in-time access for administrators

2. **Secret Lifecycle**
   - Automate secret rotation
   - Set expiration dates for secrets
   - Implement versioning for secrets

3. **Monitoring**
   - Enable Key Vault logging and monitoring
   - Set up alerts for suspicious activities
   - Regular audit of access and operations

### Integration with Azure DevOps

1. **Variable Groups Linked to Key Vault**
   - Store sensitive information in Key Vault
   - Link Azure DevOps variable groups to Key Vault
   - Use controlled access to variable groups

2. **Key Vault Task in Pipelines**
   - Fetch secrets during pipeline execution
   - Minimize exposure of secrets
   - Use the task with minimum required permissions

### Example: Using Key Vault in Pipelines

```yaml
# azure-pipelines.yml
variables:
- group: KeyVaultVariables  # Variable group linked to Key Vault

steps:
- task: AzureKeyVault@2
  inputs:
    azureSubscription: 'your-azure-connection'
    KeyVaultName: 'your-key-vault'
    SecretsFilter: 'sqlAdminPassword,apiKey'
    RunAsPreJob: true  # Fetches secrets before other tasks

- task: AzureCLI@2
  inputs:
    azureSubscription: 'your-azure-connection'
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: |
      # Access secrets as environment variables
      echo "Connecting to database (without exposing password)"
      az sql db list --server $(sqlServerName) --resource-group $(resourceGroupName)
```

## Container Security

### Container Image Security

1. **Vulnerability Scanning**
   - Scan images for vulnerabilities
   - Block deployments with critical vulnerabilities
   - Implement continuous scanning

2. **Base Image Management**
   - Use minimal base images (e.g., Alpine, Distroless)
   - Keep base images updated
   - Use trusted and official base images

3. **Image Signing and Verification**
   - Sign container images
   - Verify signatures before deployment
   - Implement content trust

### Azure Container Registry Security

1. **Access Control**
   - Use RBAC for ACR access
   - Implement Managed Identities for pulling images
   - Set up private links for network isolation

2. **Content Trust**
   - Enable Azure Container Registry content trust
   - Sign images before pushing to registry
   - Verify signatures during deployment

3. **Vulnerability Scanning**
   - Integrate Microsoft Defender for Cloud
   - Set up automated scanning
   - Implement policies for remediation

### Example: Secure Docker Build and Push

```yaml
# azure-pipelines.yml
trigger:
- main

pool:
  vmImage: 'ubuntu-latest'

variables:
  dockerRegistryServiceConnection: 'your-acr-connection'
  containerRegistry: 'yourregistry.azurecr.io'
  imageRepository: 'your-app'
  dockerfilePath: '$(Build.SourcesDirectory)/Dockerfile'
  tag: '$(Build.BuildId)'

steps:
- task: Docker@2
  displayName: 'Build and push'
  inputs:
    command: 'buildAndPush'
    containerRegistry: $(dockerRegistryServiceConnection)
    repository: $(imageRepository)
    dockerfile: $(dockerfilePath)
    tags: |
      $(tag)
      latest
    buildContext: $(Build.SourcesDirectory)

- task: ContainerScan@0
  displayName: 'Scan image for vulnerabilities'
  inputs:
    image: '$(containerRegistry)/$(imageRepository):$(tag)'
    timeout: '240'
    severityThreshold: 'CRITICAL'
```

## Identity and Access Management

### Azure AD Integration

1. **Managed Identities**
   - Use system-assigned or user-assigned managed identities
   - Eliminate credential management
   - Apply least privilege to identities

2. **Application Authentication**
   - Use Azure AD for application authentication
   - Implement certificate-based authentication
   - Avoid client secrets when possible

3. **Multi-Factor Authentication**
   - Enforce MFA for all users
   - Use conditional access policies
   - Implement privileged identity management

### RBAC Best Practices

1. **Custom Roles**
   - Create custom roles with minimum permissions
   - Use built-in roles when appropriate
   - Regularly review and audit role assignments

2. **Just-in-Time Access**
   - Implement Azure AD Privileged Identity Management
   - Use time-bound role activations
   - Require approval for privileged roles

3. **Access Reviews**
   - Conduct regular access reviews
   - Automate recertification processes
   - Remove unnecessary access

### Example: Managed Identity in ARM Template

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "webAppName": {
      "type": "string",
      "metadata": {
        "description": "The name of the web app"
      }
    }
  },
  "resources": [
    {
      "type": "Microsoft.Web/sites",
      "apiVersion": "2021-02-01",
      "name": "[parameters('webAppName')]",
      "location": "[resourceGroup().location]",
      "identity": {
        "type": "SystemAssigned"
      },
      "properties": {
        "httpsOnly": true,
        "siteConfig": {
          "minTlsVersion": "1.2"
        }
      }
    },
    {
      "type": "Microsoft.KeyVault/vaults/accessPolicies",
      "apiVersion": "2021-06-01-preview",
      "name": "[concat('myKeyVault', '/add')]",
      "dependsOn": [
        "[resourceId('Microsoft.Web/sites', parameters('webAppName'))]"
      ],
      "properties": {
        "accessPolicies": [
          {
            "tenantId": "[subscription().tenantId]",
            "objectId": "[reference(resourceId('Microsoft.Web/sites', parameters('webAppName')), '2021-02-01', 'Full').identity.principalId]",
            "permissions": {
              "secrets": ["get", "list"]
            }
          }
        ]
      }
    }
  ]
}
```

## Monitoring and Threat Detection

### Azure Monitor

1. **Logging and Diagnostics**
   - Enable diagnostic settings for all resources
   - Centralize logs in Log Analytics
   - Retain logs for compliance requirements

2. **Alert Configuration**
   - Set up alerts for security events
   - Configure action groups for notifications
   - Implement automated responses

3. **Dashboard and Visualization**
   - Create custom dashboards for security monitoring
   - Visualize security metrics
   - Share dashboards with stakeholders

### Microsoft Defender for Cloud

1. **Security Posture Management**
   - Enable Microsoft Defender for Cloud on subscriptions
   - Implement security recommendations
   - Track and improve secure score

2. **Threat Protection**
   - Enable advanced threat protection features
   - Configure just-in-time VM access
   - Implement adaptive network hardening

3. **Security Policies**
   - Define and enforce security policies
   - Integrate with Azure Policy
   - Implement regulatory compliance standards

### Example: Enabling Diagnostic Settings with Bicep

```bicep
@description('The name of the Log Analytics workspace')
param logAnalyticsWorkspaceName string

@description('The name of the App Service')
param appServiceName string

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: logAnalyticsWorkspaceName
  location: resourceGroup().location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 90
  }
}

resource appService 'Microsoft.Web/sites@2021-02-01' = {
  name: appServiceName
  location: resourceGroup().location
  properties: {
    httpsOnly: true
  }
}

resource appServiceDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${appService.name}-diagnostics'
  scope: appService
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
        retentionPolicy: {
          days: 90
          enabled: true
        }
      }
      {
        category: 'AppServiceAuditLogs'
        enabled: true
        retentionPolicy: {
          days: 90
          enabled: true
        }
      }
      {
        category: 'AppServiceAppLogs'
        enabled: true
        retentionPolicy: {
          days: 90
          enabled: true
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          days: 90
          enabled: true
        }
      }
    ]
  }
}
```

## Compliance and Governance

### Azure Policy

1. **Policy Definitions**
   - Create custom policy definitions
   - Use built-in policy definitions
   - Implement policy initiatives

2. **Compliance Monitoring**
   - Track compliance with policies
   - Generate compliance reports
   - Set up remediation tasks

3. **Policy Assignment**
   - Assign policies at appropriate scopes
   - Implement exemptions when necessary
   - Apply effect parameters based on environment

### Azure Blueprint

1. **Blueprint Definitions**
   - Create blueprint definitions for compliance standards
   - Include ARM templates, policies, and RBAC
   - Version control for blueprints

2. **Blueprint Assignment**
   - Assign blueprints to subscriptions
   - Lock resources against manual changes
   - Track deployment status

### Example: Azure Policy Assignment with Bicep

```bicep
@description('The name of the policy assignment')
param policyAssignmentName string

@description('The display name of the policy assignment')
param policyAssignmentDisplayName string

@allowed([
  'Default'
  'DoNotEnforce'
])
@description('The enforcement mode for the policy assignment')
param enforcementMode string = 'Default'

// Assign built-in policy to enforce HTTPS for App Service
resource policyAssignment 'Microsoft.Authorization/policyAssignments@2020-09-01' = {
  name: policyAssignmentName
  properties: {
    displayName: policyAssignmentDisplayName
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/a4af4a39-4135-47fb-b175-47fbdf85311d' // App Service should only be accessible over HTTPS
    scope: subscription().id
    enforcementMode: enforcementMode
  }
}
```

## Secure Development Practices

### Secure Coding Standards

1. **Code Analysis**
   - Implement static code analysis
   - Define security rulesets
   - Fix security issues early in development

2. **Dependency Management**
   - Scan dependencies for vulnerabilities
   - Keep dependencies updated
   - Implement automated dependency updates

3. **Code Reviews**
   - Implement security-focused code reviews
   - Use security checklists
   - Train developers on secure coding practices

### Threat Modeling

1. **Threat Identification**
   - Conduct threat modeling sessions
   - Use methodologies like STRIDE
   - Document and prioritize threats

2. **Mitigation Strategies**
   - Develop mitigation plans for identified threats
   - Implement defense-in-depth strategies
   - Validate mitigations through testing

### Example: Security Code Scanning in Pipeline

```yaml
# azure-pipelines.yml
trigger:
- main

pool:
  vmImage: 'ubuntu-latest'

steps:
- task: DotNetCoreCLI@2
  displayName: 'Restore'
  inputs:
    command: 'restore'
    projects: '**/*.csproj'

- task: DotNetCoreCLI@2
  displayName: 'Build'
  inputs:
    command: 'build'
    projects: '**/*.csproj'
    arguments: '--configuration Release'

- task: CredScan@3
  displayName: 'Run CredScan'
  inputs:
    outputFormat: 'sarif'
    suppressionsFile: 'CredScanSuppressions.json'

- task: SonarCloudPrepare@1
  displayName: 'Prepare SonarCloud Analysis'
  inputs:
    SonarCloud: 'SonarCloud'
    organization: 'your-organization'
    scannerMode: 'MSBuild'
    projectKey: 'your-project-key'
    projectName: 'Your Project Name'
    extraProperties: |
      sonar.cs.roslyn.ignoreIssues=false
      sonar.cs.vstest.reportsPaths=$(Agent.TempDirectory)/*.trx
      sonar.cs.opencover.reportsPaths=$(Agent.TempDirectory)/*/coverage.opencover.xml

- task: DotNetCoreCLI@2
  displayName: 'Run Tests with Coverage'
  inputs:
    command: 'test'
    projects: '**/*Tests/*.csproj'
    arguments: '--configuration Release --collect:"XPlat Code Coverage" -- DataCollectionRunSettings.DataCollectors.DataCollector.Configuration.Format=opencover'

- task: SonarCloudAnalyze@1
  displayName: 'Run SonarCloud Analysis'

- task: SonarCloudPublish@1
  displayName: 'Publish SonarCloud Results'
  inputs:
    pollingTimeoutSec: '300'

- task: PostAnalysis@1
  displayName: 'Post Analysis'
  inputs:
    AllTools: false
    CredScan: true
```

## Hands-on Lab: Implementing Azure DevSecOps

This hands-on lab guides you through implementing a complete DevSecOps pipeline for an Azure web application.

### Prerequisites

1. Azure DevOps organization and project
2. Azure subscription
3. Sample web application source code
4. Azure DevOps extensions:
   - SonarCloud
   - OWASP ZAP
   - Microsoft Security Code Analysis

### Step 1: Set Up Azure Resources

1. Create a resource group:

```bash
az group create --name devsecops-rg --location eastus
```

2. Create an Azure Key Vault:

```bash
az keyvault create --name mydevsecops-kv --resource-group devsecops-rg --location eastus
```

3. Create an Azure Container Registry:

```bash
az acr create --name mydevsecopscr --resource-group devsecops-rg --sku Standard --location eastus --admin-enabled true
```

4. Create a Log Analytics workspace:

```bash
az monitor log-analytics workspace create --resource-group devsecops-rg --workspace-name devsecops-logs --location eastus
```

### Step 2: Configure Azure DevOps

1. Create service connections:
   - Go to **Project Settings** > **Service connections**
   - Create connections for:
     - Azure Resource Manager
     - SonarCloud
     - Azure Container Registry

2. Create variable groups:
   - Go to **Pipelines** > **Library** > **Variable groups**
   - Create a variable group linked to Key Vault

3. Create environments:
   - Go to **Pipelines** > **Environments**
   - Create environments for Dev, QA, and Production
   - Configure approval checks for QA and Production

### Step 3: Create the DevSecOps Pipeline

Create a `azure-pipelines.yml` file:

```yaml
trigger:
- main

variables:
  # Pipeline variables
  vmImageName: 'ubuntu-latest'
  azureSubscription: 'your-azure-subscription'
  resourceGroupName: 'devsecops-rg'
  location: 'eastus'
  webAppName: 'devsecops-webapp'
  containerRegistry: 'mydevsecopscr.azurecr.io'
  dockerfilePath: '$(Build.SourcesDirectory)/Dockerfile'
  imageRepository: 'devsecops-app'
  tag: '$(Build.BuildId)'
  
  # Link to Key Vault variable group
- group: 'KeyVaultSecrets'

stages:
# Secret Scanning Stage
- stage: SecretScanning
  displayName: 'Secret Scanning'
  jobs:
  - job: CredScan
    displayName: 'Credential Scanning'
    pool:
      vmImage: $(vmImageName)
    steps:
    - task: CredScan@3
      displayName: 'Run CredScan'
      inputs:
        outputFormat: 'pre'
    
    - task: PostAnalysis@1
      displayName: 'Validate CredScan Results'
      inputs:
        CredScan: true
        ToolLogsNotFoundAction: 'Standard'

# Static Code Analysis Stage
- stage: SAST
  displayName: 'Static Analysis'
  dependsOn: SecretScanning
  jobs:
  - job: SonarCloud
    displayName: 'SonarCloud Analysis'
    pool:
      vmImage: $(vmImageName)
    steps:
    - task: SonarCloudPrepare@1
      inputs:
        SonarCloud: 'SonarCloud'
        organization: 'your-organization'
        scannerMode: 'MSBuild'
        projectKey: 'your-project-key'
        projectName: 'Your Project Name'
    
    - task: DotNetCoreCLI@2
      inputs:
        command: 'build'
        projects: '**/*.csproj'
    
    - task: SonarCloudAnalyze@1
    
    - task: SonarCloudPublish@1
      inputs:
        pollingTimeoutSec: '300'

# Build and Scan Container Image
- stage: BuildAndScan
  displayName: 'Build and Scan Container'
  dependsOn: SAST
  jobs:
  - job: BuildAndScanImage
    displayName: 'Build and Scan Docker Image'
    pool:
      vmImage: $(vmImageName)
    steps:
    - task: Docker@2
      displayName: 'Build Docker Image'
      inputs:
        command: 'build'
        dockerfile: $(dockerfilePath)
        repository: $(imageRepository)
        containerRegistry: 'ACR'
        tags: |
          $(tag)
          latest
    
    - task: ContainerScan@0
      displayName: 'Container Image Scan'
      inputs:
        image: '$(containerRegistry)/$(imageRepository):$(tag)'
        severityThreshold: 'Medium'
    
    - task: Docker@2
      displayName: 'Push Docker Image'
      inputs:
        command: 'push'
        repository: $(imageRepository)
        containerRegistry: 'ACR'
        tags: |
          $(tag)
          latest

# Infrastructure Deployment and Scanning
- stage: InfrastructureDeployment
  displayName: 'Deploy Infrastructure'
  dependsOn: BuildAndScan
  jobs:
  - job: DeployInfrastructure
    displayName: 'Deploy Azure Infrastructure'
    pool:
      vmImage: $(vmImageName)
    steps:
    - task: AzureCLI@2
      displayName: 'Validate ARM Template'
      inputs:
        azureSubscription: $(azureSubscription)
        scriptType: 'bash'
        scriptLocation: 'inlineScript'
        inlineScript: |
          az deployment group validate \
            --resource-group $(resourceGroupName) \
            --template-file infrastructure/azuredeploy.json \
            --parameters infrastructure/azuredeploy.parameters.json
    
    - task: AzureResourceManagerTemplateDeployment@3
      displayName: 'Deploy ARM Template'
      inputs:
        deploymentScope: 'Resource Group'
        azureResourceManagerConnection: $(azureSubscription)
        subscriptionId: $(subscriptionId)
        action: 'Create Or Update Resource Group'
        resourceGroupName: $(resourceGroupName)
        location: $(location)
        templateLocation: 'Linked artifact'
        csmFile: 'infrastructure/azuredeploy.json'
        csmParametersFile: 'infrastructure/azuredeploy.parameters.json'
        deploymentMode: 'Incremental'

# Development Deployment
- stage: DeployToDev
  displayName: 'Deploy to Development'
  dependsOn: InfrastructureDeployment
  jobs:
  - deployment: DeployToDev
    displayName: 'Deploy Web App to Dev'
    environment: 'Development'
    pool:
      vmImage: $(vmImageName)
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureWebAppContainer@1
            displayName: 'Deploy Container to App Service'
            inputs:
              azureSubscription: $(azureSubscription)
              appName: '$(webAppName)-dev'
              containers: '$(containerRegistry)/$(imageRepository):$(tag)'

# Dynamic Application Security Testing
- stage: DAST
  displayName: 'Dynamic Security Testing'
  dependsOn: DeployToDev
  jobs:
  - job: OWASP_ZAP_Scan
    displayName: 'Run OWASP ZAP Scan'
    pool:
      vmImage: $(vmImageName)
    steps:
    - script: |
        docker pull owasp/zap2docker-stable
        docker run --rm -v $(pwd):/zap/wrk owasp/zap2docker-stable zap-baseline.py \
          -t https://$(webAppName)-dev.azurewebsites.net \
          -g gen.conf -r zap-report.html
      displayName: 'Run OWASP ZAP Baseline Scan'
    
    - task: PublishBuildArtifacts@1
      inputs:
        pathToPublish: '$(Build.SourcesDirectory)/zap-report.html'
        artifactName: 'ZAP-Report'

# Production Deployment
- stage: DeployToProduction
  displayName: 'Deploy to Production'
  dependsOn: DAST
  jobs:
  - deployment: DeployToProduction
    displayName: 'Deploy Web App to Production'
    environment: 'Production'
    pool:
      vmImage: $(vmImageName)
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureWebAppContainer@1
            displayName: 'Deploy Container to App Service'
            inputs:
              azureSubscription: $(azureSubscription)
              appName: '$(webAppName)'
              containers: '$(containerRegistry)/$(imageRepository):$(tag)'

# Post-Deployment Security Monitoring
- stage: SecurityMonitoring
  displayName: 'Security Monitoring Setup'
  dependsOn: DeployToProduction
  jobs:
  - job: ConfigureSecurityMonitoring
    displayName: 'Configure Security Monitoring'
    pool:
      vmImage: $(vmImageName)
    steps:
    - task: AzureCLI@2
      displayName: 'Setup Microsoft Defender for Cloud'
      inputs:
        azureSubscription: $(azureSubscription)
        scriptType: 'bash'
        scriptLocation: 'inlineScript'
        inlineScript: |
          # Enable Defender for App Service
          az security pricing create --name AppServices --tier 'Standard'
          
          # Enable diagnostic settings for web app
          az monitor diagnostic-settings create \
            --name 'SecurityMonitoring' \
            --resource $(webAppName) \
            --resource-group $(resourceGroupName) \
            --resource-type 'Microsoft.Web/sites' \
            --workspace $(logAnalyticsWorkspace) \
            --logs '[{"category":"AppServiceHTTPLogs","enabled":true},{"category":"AppServiceAuditLogs","enabled":true},{"category":"AppServiceAppLogs","enabled":true}]' \
            --metrics '[{"category":"AllMetrics","enabled":true}]'
          
          # Set up alert rules
          az monitor metrics alert create \
            --name 'HighFailureRate' \
            --resource-group $(resourceGroupName) \
            --scopes $(webAppResourceId) \
            --condition 'count Http5xx > 10' \
            --window-size 5m \
            --action-group $(alertActionGroupId)
```

### Step 4: Create Infrastructure Templates

Create an ARM template (`infrastructure/azuredeploy.json`):

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "webAppName": {
      "type": "string",
      "metadata": {
        "description": "The name of the web app"
      }
    },
    "location": {
      "type": "string",
      "defaultValue": "[resourceGroup().location]",
      "metadata": {
        "description": "Location for all resources"
      }
    },
    "keyVaultName": {
      "type": "string",
      "metadata": {
        "description": "The name of the key vault"
      }
    },
    "logAnalyticsWorkspaceName": {
      "type": "string",
      "metadata": {
        "description": "The name of the Log Analytics workspace"
      }
    }
  },
  "resources": [
    {
      "type": "Microsoft.Web/serverfarms",
      "apiVersion": "2021-02-01",
      "name": "[concat(parameters('webAppName'), '-plan')]",
      "location": "[parameters('location')]",
      "sku": {
        "name": "P1v2",
        "tier": "PremiumV2",
        "size": "P1v2",
        "family": "Pv2",
        "capacity": 1
      },
      "kind": "linux",
      "properties": {
        "reserved": true
      }
    },
    {
      "type": "Microsoft.Web/sites",
      "apiVersion": "2021-02-01",
      "name": "[parameters('webAppName')]",
      "location": "[parameters('location')]",
      "dependsOn": [
        "[resourceId('Microsoft.Web/serverfarms', concat(parameters('webAppName'), '-plan'))]"
      ],
      "identity": {
        "type": "SystemAssigned"
      },
      "properties": {
        "serverFarmId": "[resourceId('Microsoft.Web/serverfarms', concat(parameters('webAppName'), '-plan'))]",
        "siteConfig": {
          "linuxFxVersion": "DOCKER|mcr.microsoft.com/appsvc/staticsite:latest",
          "httpsOnly": true,
          "minTlsVersion": "1.2"
        },
        "httpsOnly": true
      }
    },
    {
      "type": "Microsoft.Web/sites",
      "apiVersion": "2021-02-01",
      "name": "[concat(parameters('webAppName'), '-dev')]",
      "location": "[parameters('location')]",
      "dependsOn": [
        "[resourceId('Microsoft.Web/serverfarms', concat(parameters('webAppName'), '-plan'))]"
      ],
      "identity": {
        "type": "SystemAssigned"
      },
      "properties": {
        "serverFarmId": "[resourceId('Microsoft.Web/serverfarms', concat(parameters('webAppName'), '-plan'))]",
        "siteConfig": {
          "linuxFxVersion": "DOCKER|mcr.microsoft.com/appsvc/staticsite:latest",
          "httpsOnly": true,
          "minTlsVersion": "1.2"
        },
        "httpsOnly": true
      }
    },
    {
      "type": "Microsoft.Insights/diagnosticSettings",
      "apiVersion": "2021-05-01-preview",
      "name": "[concat(parameters('webAppName'), '-diagnostics')]",
      "scope": "[resourceId('Microsoft.Web/sites', parameters('webAppName'))]",
      "dependsOn": [
        "[resourceId('Microsoft.Web/sites', parameters('webAppName'))]"
      ],
      "properties": {
        "workspaceId": "[resourceId('Microsoft.OperationalInsights/workspaces', parameters('logAnalyticsWorkspaceName'))]",
        "logs": [
          {
            "category": "AppServiceHTTPLogs",
            "enabled": true
          },
          {
            "category": "AppServiceAuditLogs",
            "enabled": true
          },
          {
            "category": "AppServiceAppLogs",
            "enabled": true
          }
        ],
        "metrics": [
          {
            "category": "AllMetrics",
            "enabled": true
          }
        ]
      }
    },
    {
      "type": "Microsoft.KeyVault/vaults/accessPolicies",
      "apiVersion": "2021-06-01-preview",
      "name": "[concat(parameters('keyVaultName'), '/add')]",
      "dependsOn": [
        "[resourceId('Microsoft.Web/sites', parameters('webAppName'))]"
      ],
      "properties": {
        "accessPolicies": [
          {
            "tenantId": "[subscription().tenantId]",
            "objectId": "[reference(resourceId('Microsoft.Web/sites', parameters('webAppName')), '2021-02-01', 'Full').identity.principalId]",
            "permissions": {
              "secrets": ["get", "list"]
            }
          }
        ]
      }
    }
  ],
  "outputs": {
    "webAppResourceId": {
      "type": "string",
      "value": "[resourceId('Microsoft.Web/sites', parameters('webAppName'))]"
    },
    "webAppUrl": {
      "type": "string",
      "value": "[concat('https://', reference(resourceId('Microsoft.Web/sites', parameters('webAppName'))).defaultHostName)]"
    },
    "webAppPrincipalId": {
      "type": "string",
      "value": "[reference(resourceId('Microsoft.Web/sites', parameters('webAppName')), '2021-02-01', 'Full').identity.principalId]"
    }
  }
}
```

### Step 5: Run the Pipeline

1. Commit all files to your repository
2. Create and run the pipeline in Azure DevOps
3. Monitor each stage for security findings
4. Review deployment results and security reports

### Step 6: Review and Remediate

1. Analyze security scan reports:
   - Review SonarCloud findings
   - Check container scan results
   - Review OWASP ZAP report

2. Remediate security issues:
   - Fix code vulnerabilities
   - Update dependencies
   - Harden container configurations

3. Set up continuous monitoring:
   - Configure Microsoft Defender for Cloud
   - Set up alerts for security events
   - Implement regular security reviews

This hands-on lab demonstrates a complete DevSecOps implementation for Azure, integrating security at every stage of the CI/CD pipeline from code to production.
