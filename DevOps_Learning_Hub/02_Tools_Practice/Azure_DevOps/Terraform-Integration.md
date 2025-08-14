# 🔄 Terraform Integration with Azure DevOps

This guide provides comprehensive instructions for integrating Terraform with Azure DevOps to implement Infrastructure as Code (IaC) in your CI/CD pipelines.

## 📋 Table of Contents

1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Setting Up Azure DevOps for Terraform](#setting-up-azure-devops-for-terraform)
4. [Terraform Project Structure](#terraform-project-structure)
5. [Creating a Terraform CI/CD Pipeline](#creating-a-terraform-cicd-pipeline)
6. [State Management with Azure Storage](#state-management-with-azure-storage)
7. [Security Best Practices](#security-best-practices)
8. [Working with Terraform Modules](#working-with-terraform-modules)
9. [Implementing Pull Request Validation](#implementing-pull-request-validation)
10. [End-to-End Example](#end-to-end-example)
11. [Advanced Scenarios](#advanced-scenarios)
12. [Troubleshooting](#troubleshooting)

## Introduction

Terraform is a powerful Infrastructure as Code (IaC) tool that allows you to define and provision infrastructure resources in a declarative way. Azure DevOps provides a comprehensive set of services for managing the development lifecycle, including CI/CD pipelines. Combining these tools enables you to implement GitOps workflows for your infrastructure, ensuring consistency, reliability, and auditability.

### Benefits of Terraform with Azure DevOps

- **Version-controlled infrastructure**: Track all infrastructure changes in git
- **Automated validation**: Catch configuration errors before they reach production
- **Consistent deployments**: Ensure the same infrastructure is deployed across environments
- **Self-documented infrastructure**: Infrastructure code serves as documentation
- **Reduced manual intervention**: Automate the provisioning and updating of resources

## Prerequisites

Before you begin, ensure you have:

1. **Azure DevOps Organization**: A project set up in Azure DevOps
2. **Azure Subscription**: Access to an Azure subscription
3. **Terraform Knowledge**: Basic understanding of Terraform concepts
4. **Service Principal**: An Azure service principal for Terraform to use

### Creating a Service Principal

Create a service principal for Terraform to authenticate with Azure:

```bash
az ad sp create-for-rbac --name "Terraform-ServicePrincipal" --role Contributor \
                         --scopes /subscriptions/<subscription-id>
```

Save the output containing `appId`, `password`, `tenant`, and `subscriptionId` for later use.

## Setting Up Azure DevOps for Terraform

### Install Terraform Extension

1. Go to the Azure DevOps Marketplace
2. Search for "Terraform"
3. Install the "Terraform" extension by Microsoft DevLabs
4. Install the "Terraform Build & Release Tasks" extension

### Create a Variable Group

1. Go to Pipelines > Library
2. Create a new variable group named "Terraform-Azure-Secrets"
3. Add the following variables:
   - `ARM_CLIENT_ID`: Service principal appId
   - `ARM_CLIENT_SECRET`: Service principal password (mark as secret)
   - `ARM_SUBSCRIPTION_ID`: Azure subscription ID
   - `ARM_TENANT_ID`: Azure tenant ID
4. Save the variable group

## Terraform Project Structure

A well-organized Terraform project structure helps maintain clean, modular code:

```
terraform-project/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars
│   ├── staging/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars
├── modules/
│   ├── networking/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── compute/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── database/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── pipeline/
    ├── azure-pipelines.yml
    └── scripts/
        ├── terraform-init.sh
        └── terraform-validate.sh
```

### Environment Configuration

Each environment directory contains:

- `main.tf`: Primary configuration file that calls modules
- `variables.tf`: Variable declarations
- `outputs.tf`: Output definitions
- `terraform.tfvars`: Environment-specific variable values

Example `environments/dev/main.tf`:

```hcl
provider "azurerm" {
  features {}
}

module "networking" {
  source = "../../modules/networking"
  
  resource_group_name     = var.resource_group_name
  location                = var.location
  vnet_name               = var.vnet_name
  vnet_address_space      = var.vnet_address_space
  subnet_names            = var.subnet_names
  subnet_address_prefixes = var.subnet_address_prefixes
  
  tags = var.tags
}

module "compute" {
  source = "../../modules/compute"
  
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = module.networking.subnet_ids[0]
  vm_name             = var.vm_name
  vm_size             = var.vm_size
  
  tags = var.tags
}
```

## Creating a Terraform CI/CD Pipeline

### Basic Pipeline Structure

Create a file `pipeline/azure-pipelines.yml`:

```yaml
trigger:
  branches:
    include:
    - main
  paths:
    include:
    - 'environments/dev/**'
    - 'modules/**'
    - 'pipeline/**'

pool:
  vmImage: 'ubuntu-latest'

variables:
- group: Terraform-Azure-Secrets
- name: TF_VERSION
  value: '1.3.6'
- name: ENVIRONMENT
  value: 'dev'
- name: TF_WORKING_DIR
  value: '$(System.DefaultWorkingDirectory)/environments/$(ENVIRONMENT)'

stages:
- stage: Validate
  jobs:
  - job: ValidateTerraform
    steps:
    - task: TerraformInstaller@0
      displayName: 'Install Terraform $(TF_VERSION)'
      inputs:
        terraformVersion: '$(TF_VERSION)'
    
    - task: TerraformTaskV3@3
      displayName: 'Terraform Init'
      inputs:
        provider: 'azurerm'
        command: 'init'
        workingDirectory: '$(TF_WORKING_DIR)'
        backendServiceArm: 'Terraform-ServiceConnection'
        backendAzureRmResourceGroupName: 'terraform-state-rg'
        backendAzureRmStorageAccountName: 'tfstate$(ENVIRONMENT)'
        backendAzureRmContainerName: 'tfstate'
        backendAzureRmKey: 'terraform.tfstate'
    
    - task: TerraformTaskV3@3
      displayName: 'Terraform Validate'
      inputs:
        provider: 'azurerm'
        command: 'validate'
        workingDirectory: '$(TF_WORKING_DIR)'
    
    - task: TerraformTaskV3@3
      displayName: 'Terraform Plan'
      inputs:
        provider: 'azurerm'
        command: 'plan'
        workingDirectory: '$(TF_WORKING_DIR)'
        environmentServiceNameAzureRM: 'Terraform-ServiceConnection'

- stage: Apply
  dependsOn: Validate
  condition: succeeded()
  jobs:
  - job: ApplyTerraform
    steps:
    - task: TerraformInstaller@0
      displayName: 'Install Terraform $(TF_VERSION)'
      inputs:
        terraformVersion: '$(TF_VERSION)'
    
    - task: TerraformTaskV3@3
      displayName: 'Terraform Init'
      inputs:
        provider: 'azurerm'
        command: 'init'
        workingDirectory: '$(TF_WORKING_DIR)'
        backendServiceArm: 'Terraform-ServiceConnection'
        backendAzureRmResourceGroupName: 'terraform-state-rg'
        backendAzureRmStorageAccountName: 'tfstate$(ENVIRONMENT)'
        backendAzureRmContainerName: 'tfstate'
        backendAzureRmKey: 'terraform.tfstate'
    
    - task: TerraformTaskV3@3
      displayName: 'Terraform Apply'
      inputs:
        provider: 'azurerm'
        command: 'apply'
        workingDirectory: '$(TF_WORKING_DIR)'
        environmentServiceNameAzureRM: 'Terraform-ServiceConnection'
```

### Setting Up Service Connections

1. Go to Project Settings > Service Connections
2. Create a new Azure Resource Manager service connection
3. Name it "Terraform-ServiceConnection"
4. Use service principal authentication
5. Enter the details from your service principal
6. Grant pipeline permissions to use the connection

## State Management with Azure Storage

### Setting Up Azure Storage for Terraform State

Create a storage account to store Terraform state:

```bash
# Create resource group
az group create --name terraform-state-rg --location eastus

# Create storage account
az storage account create --name tfstatedev --resource-group terraform-state-rg \
                         --sku Standard_LRS --encryption-services blob

# Create blob container
az storage container create --name tfstate --account-name tfstatedev
```

### Configuring Backend State

In each environment's `main.tf`, add a backend configuration:

```hcl
terraform {
  backend "azurerm" {
    # These values are provided by the Azure DevOps pipeline
    # resource_group_name  = "terraform-state-rg"
    # storage_account_name = "tfstatedev"
    # container_name       = "tfstate"
    # key                  = "terraform.tfstate"
  }
}
```

## Security Best Practices

### Securing Terraform in Azure DevOps

1. **Use Variable Groups**: Store secrets in Azure DevOps variable groups
2. **Enable Approvals**: Require approvals for production deployments
3. **Use Service Principals**: Create dedicated service principals with least privilege
4. **Secure State Files**: Encrypt state files and restrict access
5. **Enable Terraform Plan Reviews**: Review Terraform plans before applying
6. **Use Azure Key Vault**: Store sensitive values in Key Vault
7. **Implement Branch Policies**: Require PR reviews for infrastructure changes

### Example: Integrating Key Vault

```yaml
# In your pipeline
steps:
- task: AzureKeyVault@2
  inputs:
    azureSubscription: 'Terraform-ServiceConnection'
    KeyVaultName: 'tf-secrets-kv'
    SecretsFilter: 'db-password,api-key'
    RunAsPreJob: true

# Later in your Terraform task
- task: TerraformTaskV3@3
  displayName: 'Terraform Apply'
  inputs:
    provider: 'azurerm'
    command: 'apply'
    workingDirectory: '$(TF_WORKING_DIR)'
    environmentServiceNameAzureRM: 'Terraform-ServiceConnection'
    commandOptions: '-var="db_password=$(db-password)" -var="api_key=$(api-key)"'
```

## Working with Terraform Modules

### Creating Reusable Modules

Example networking module (`modules/networking/main.tf`):

```hcl
resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = var.vnet_address_space
  tags                = var.tags
}

resource "azurerm_subnet" "this" {
  count                = length(var.subnet_names)
  name                 = var.subnet_names[count.index]
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.subnet_address_prefixes[count.index]]
}
```

### Module Variables and Outputs

Variables (`modules/networking/variables.tf`):

```hcl
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
}

variable "subnet_names" {
  description = "Names of subnets to create"
  type        = list(string)
}

variable "subnet_address_prefixes" {
  description = "Address prefixes for subnets"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
```

Outputs (`modules/networking/outputs.tf`):

```hcl
output "resource_group_id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.this.id
}

output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.this.id
}

output "subnet_ids" {
  description = "IDs of created subnets"
  value       = azurerm_subnet.this[*].id
}
```

## Implementing Pull Request Validation

### Creating a PR Validation Pipeline

Create a file `pipeline/pr-validation.yml`:

```yaml
trigger: none

pr:
  branches:
    include:
    - main
  paths:
    include:
    - 'environments/**'
    - 'modules/**'
    - 'pipeline/**'

pool:
  vmImage: 'ubuntu-latest'

variables:
- group: Terraform-Azure-Secrets
- name: TF_VERSION
  value: '1.3.6'

jobs:
- job: ValidateAll
  strategy:
    matrix:
      dev:
        TF_WORKING_DIR: '$(System.DefaultWorkingDirectory)/environments/dev'
      staging:
        TF_WORKING_DIR: '$(System.DefaultWorkingDirectory)/environments/staging'
      prod:
        TF_WORKING_DIR: '$(System.DefaultWorkingDirectory)/environments/prod'
  steps:
  - task: TerraformInstaller@0
    displayName: 'Install Terraform $(TF_VERSION)'
    inputs:
      terraformVersion: '$(TF_VERSION)'
  
  - task: TerraformTaskV3@3
    displayName: 'Terraform Init'
    inputs:
      provider: 'azurerm'
      command: 'init'
      workingDirectory: '$(TF_WORKING_DIR)'
      backendType: 'azurerm'
      backendServiceArm: 'Terraform-ServiceConnection'
      backendAzureRmResourceGroupName: 'terraform-state-rg'
      backendAzureRmStorageAccountName: 'tfstate$(ENVIRONMENT)'
      backendAzureRmContainerName: 'tfstate'
      backendAzureRmKey: 'terraform.tfstate'
  
  - task: TerraformTaskV3@3
    displayName: 'Terraform Validate'
    inputs:
      provider: 'azurerm'
      command: 'validate'
      workingDirectory: '$(TF_WORKING_DIR)'
  
  - task: TerraformTaskV3@3
    displayName: 'Terraform Plan (No Apply)'
    inputs:
      provider: 'azurerm'
      command: 'plan'
      workingDirectory: '$(TF_WORKING_DIR)'
      environmentServiceNameAzureRM: 'Terraform-ServiceConnection'
      publishPlanResults: 'TerraformPlan'
```

### Implement Branch Policies

1. Go to Repos > Branches
2. Select the main branch and click "..." > Branch policies
3. Add a build validation policy
4. Select the PR validation pipeline
5. Check "Required"
6. Save the policy

## End-to-End Example

Let's create a complete example to deploy a web application with:
- Virtual Network
- App Service Plan
- App Service
- SQL Database

### Project Structure

```
terraform-webapp/
├── environments/
│   └── dev/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars
├── modules/
│   ├── networking/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── app_service/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── database/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── pipeline/
    └── azure-pipelines.yml
```

### Module Configuration

App Service Module (`modules/app_service/main.tf`):

```hcl
resource "azurerm_app_service_plan" "this" {
  name                = "${var.app_name}-plan"
  location            = var.location
  resource_group_name = var.resource_group_name
  
  sku {
    tier = var.sku_tier
    size = var.sku_size
  }
  
  tags = var.tags
}

resource "azurerm_app_service" "this" {
  name                = var.app_name
  location            = var.location
  resource_group_name = var.resource_group_name
  app_service_plan_id = azurerm_app_service_plan.this.id
  
  site_config {
    dotnet_framework_version = "v6.0"
    scm_type                 = "LocalGit"
    always_on                = true
    
    cors {
      allowed_origins = ["*"]
    }
  }
  
  app_settings = {
    "WEBSITE_NODE_DEFAULT_VERSION" = "~14"
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.this.instrumentation_key
    "ConnectionString" = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.db_connection.id})"
  }
  
  identity {
    type = "SystemAssigned"
  }
  
  tags = var.tags
}

resource "azurerm_application_insights" "this" {
  name                = "${var.app_name}-appinsights"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
  
  tags = var.tags
}

resource "azurerm_key_vault" "this" {
  name                = "${var.app_name}-kv"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  
  purge_protection_enabled = true
  
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    
    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Recover",
      "Backup",
      "Restore"
    ]
  }
  
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_app_service.this.identity[0].principal_id
    
    secret_permissions = [
      "Get",
      "List"
    ]
  }
  
  tags = var.tags
}

resource "azurerm_key_vault_secret" "db_connection" {
  name         = "ConnectionString"
  value        = var.db_connection_string
  key_vault_id = azurerm_key_vault.this.id
}

data "azurerm_client_config" "current" {}
```

Database Module (`modules/database/main.tf`):

```hcl
resource "azurerm_sql_server" "this" {
  name                         = "${var.name}-sqlserver"
  location                     = var.location
  resource_group_name          = var.resource_group_name
  version                      = "12.0"
  administrator_login          = var.admin_username
  administrator_login_password = var.admin_password
  
  tags = var.tags
}

resource "azurerm_mssql_database" "this" {
  name           = "${var.name}-db"
  server_id      = azurerm_sql_server.this.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 4
  read_scale     = false
  sku_name       = "S0"
  zone_redundant = false
  
  tags = var.tags
}

resource "azurerm_sql_firewall_rule" "allow_azure_services" {
  name                = "AllowAzureServices"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_sql_server.this.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}
```

Environment Configuration (`environments/dev/main.tf`):

```hcl
provider "azurerm" {
  features {}
}

terraform {
  backend "azurerm" {
    # Values provided by the pipeline
  }
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

module "networking" {
  source = "../../modules/networking"
  
  resource_group_name     = azurerm_resource_group.this.name
  location                = var.location
  vnet_name               = "${var.app_name}-vnet"
  vnet_address_space      = ["10.0.0.0/16"]
  subnet_names            = ["web", "data"]
  subnet_address_prefixes = ["10.0.1.0/24", "10.0.2.0/24"]
  
  tags = var.tags
}

module "database" {
  source = "../../modules/database"
  
  name                = var.app_name
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  admin_username      = var.db_admin_username
  admin_password      = var.db_admin_password
  
  tags = var.tags
}

module "app_service" {
  source = "../../modules/app_service"
  
  app_name             = var.app_name
  location             = var.location
  resource_group_name  = azurerm_resource_group.this.name
  sku_tier             = "Standard"
  sku_size             = "S1"
  db_connection_string = "Server=tcp:${module.database.sql_server_fqdn},1433;Initial Catalog=${module.database.database_name};Persist Security Info=False;User ID=${var.db_admin_username};Password=${var.db_admin_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  
  tags = var.tags
}
```

### Complete Pipeline Configuration

```yaml
# pipeline/azure-pipelines.yml
trigger:
  branches:
    include:
    - main
  paths:
    include:
    - 'environments/dev/**'
    - 'modules/**'
    - 'pipeline/**'

pool:
  vmImage: 'ubuntu-latest'

variables:
- group: Terraform-Azure-Secrets
- name: TF_VERSION
  value: '1.3.6'
- name: ENVIRONMENT
  value: 'dev'
- name: TF_WORKING_DIR
  value: '$(System.DefaultWorkingDirectory)/environments/$(ENVIRONMENT)'

stages:
- stage: Validate
  jobs:
  - job: TerraformValidate
    steps:
    - task: TerraformInstaller@0
      displayName: 'Install Terraform $(TF_VERSION)'
      inputs:
        terraformVersion: '$(TF_VERSION)'
    
    - task: TerraformTaskV3@3
      displayName: 'Terraform Init'
      inputs:
        provider: 'azurerm'
        command: 'init'
        workingDirectory: '$(TF_WORKING_DIR)'
        backendServiceArm: 'Terraform-ServiceConnection'
        backendAzureRmResourceGroupName: 'terraform-state-rg'
        backendAzureRmStorageAccountName: 'tfstate$(ENVIRONMENT)'
        backendAzureRmContainerName: 'tfstate'
        backendAzureRmKey: 'terraform.tfstate'
    
    - task: TerraformTaskV3@3
      displayName: 'Terraform Validate'
      inputs:
        provider: 'azurerm'
        command: 'validate'
        workingDirectory: '$(TF_WORKING_DIR)'
    
    - task: TerraformTaskV3@3
      displayName: 'Terraform Plan'
      inputs:
        provider: 'azurerm'
        command: 'plan'
        workingDirectory: '$(TF_WORKING_DIR)'
        environmentServiceNameAzureRM: 'Terraform-ServiceConnection'
        commandOptions: '-out=$(TF_WORKING_DIR)/plan.tfplan -var="db_admin_password=$(DB_ADMIN_PASSWORD)"'
    
    - task: PublishPipelineArtifact@1
      displayName: 'Publish Terraform Plan'
      inputs:
        targetPath: '$(TF_WORKING_DIR)/plan.tfplan'
        artifact: 'TerraformPlan'
        publishLocation: 'pipeline'

- stage: Deploy
  dependsOn: Validate
  condition: succeeded()
  jobs:
  - deployment: ApplyTerraform
    environment: 'Dev'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: TerraformInstaller@0
            displayName: 'Install Terraform $(TF_VERSION)'
            inputs:
              terraformVersion: '$(TF_VERSION)'
          
          - task: DownloadPipelineArtifact@2
            inputs:
              artifactName: 'TerraformPlan'
              targetPath: '$(TF_WORKING_DIR)'
          
          - task: TerraformTaskV3@3
            displayName: 'Terraform Init'
            inputs:
              provider: 'azurerm'
              command: 'init'
              workingDirectory: '$(TF_WORKING_DIR)'
              backendServiceArm: 'Terraform-ServiceConnection'
              backendAzureRmResourceGroupName: 'terraform-state-rg'
              backendAzureRmStorageAccountName: 'tfstate$(ENVIRONMENT)'
              backendAzureRmContainerName: 'tfstate'
              backendAzureRmKey: 'terraform.tfstate'
          
          - task: TerraformTaskV3@3
            displayName: 'Terraform Apply'
            inputs:
              provider: 'azurerm'
              command: 'apply'
              workingDirectory: '$(TF_WORKING_DIR)'
              environmentServiceNameAzureRM: 'Terraform-ServiceConnection'
              commandOptions: '$(TF_WORKING_DIR)/plan.tfplan'
```

## Advanced Scenarios

### Multi-Environment Deployment Pipeline

For managing deployments across multiple environments:

```yaml
# pipeline/multi-env-pipeline.yml
trigger:
  branches:
    include:
    - main
  paths:
    include:
    - 'environments/**'
    - 'modules/**'
    - 'pipeline/**'

pool:
  vmImage: 'ubuntu-latest'

variables:
- group: Terraform-Azure-Secrets
- name: TF_VERSION
  value: '1.3.6'

stages:
- stage: DeployDev
  jobs:
  - template: templates/terraform-deploy.yml
    parameters:
      environment: 'dev'
      serviceConnection: 'Terraform-ServiceConnection'

- stage: DeployStaging
  dependsOn: DeployDev
  condition: succeeded()
  jobs:
  - template: templates/terraform-deploy.yml
    parameters:
      environment: 'staging'
      serviceConnection: 'Terraform-ServiceConnection'

- stage: DeployProd
  dependsOn: DeployStaging
  condition: succeeded()
  jobs:
  - template: templates/terraform-deploy.yml
    parameters:
      environment: 'prod'
      serviceConnection: 'Terraform-ServiceConnection'
```

With a template file (`pipeline/templates/terraform-deploy.yml`):

```yaml
parameters:
  environment: 'dev'
  serviceConnection: 'Terraform-ServiceConnection'

jobs:
- deployment: TerraformDeploy
  environment: ${{ parameters.environment }}
  strategy:
    runOnce:
      deploy:
        steps:
        - task: TerraformInstaller@0
          displayName: 'Install Terraform $(TF_VERSION)'
          inputs:
            terraformVersion: '$(TF_VERSION)'
        
        - task: TerraformTaskV3@3
          displayName: 'Terraform Init'
          inputs:
            provider: 'azurerm'
            command: 'init'
            workingDirectory: '$(System.DefaultWorkingDirectory)/environments/${{ parameters.environment }}'
            backendServiceArm: '${{ parameters.serviceConnection }}'
            backendAzureRmResourceGroupName: 'terraform-state-rg'
            backendAzureRmStorageAccountName: 'tfstate${{ parameters.environment }}'
            backendAzureRmContainerName: 'tfstate'
            backendAzureRmKey: 'terraform.tfstate'
        
        - task: TerraformTaskV3@3
          displayName: 'Terraform Plan'
          inputs:
            provider: 'azurerm'
            command: 'plan'
            workingDirectory: '$(System.DefaultWorkingDirectory)/environments/${{ parameters.environment }}'
            environmentServiceNameAzureRM: '${{ parameters.serviceConnection }}'
            commandOptions: '-out=$(System.DefaultWorkingDirectory)/environments/${{ parameters.environment }}/plan.tfplan'
        
        - task: TerraformTaskV3@3
          displayName: 'Terraform Apply'
          inputs:
            provider: 'azurerm'
            command: 'apply'
            workingDirectory: '$(System.DefaultWorkingDirectory)/environments/${{ parameters.environment }}'
            environmentServiceNameAzureRM: '${{ parameters.serviceConnection }}'
            commandOptions: '$(System.DefaultWorkingDirectory)/environments/${{ parameters.environment }}/plan.tfplan'
```

### Implementing Terraform Workspaces

For managing multiple environments with workspaces:

```yaml
# pipeline/workspace-pipeline.yml
trigger:
  branches:
    include:
    - main
  paths:
    include:
    - 'terraform/**'
    - 'pipeline/**'

pool:
  vmImage: 'ubuntu-latest'

variables:
- group: Terraform-Azure-Secrets
- name: TF_VERSION
  value: '1.3.6'
- name: TF_WORKING_DIR
  value: '$(System.DefaultWorkingDirectory)/terraform'

stages:
- stage: DeployToEnvironment
  jobs:
  - deployment: TerraformDeploy
    environment: ${{ parameters.environment }}
    strategy:
      runOnce:
        deploy:
          steps:
          - task: TerraformInstaller@0
            displayName: 'Install Terraform $(TF_VERSION)'
            inputs:
              terraformVersion: '$(TF_VERSION)'
          
          - task: TerraformTaskV3@3
            displayName: 'Terraform Init'
            inputs:
              provider: 'azurerm'
              command: 'init'
              workingDirectory: '$(TF_WORKING_DIR)'
              backendServiceArm: 'Terraform-ServiceConnection'
              backendAzureRmResourceGroupName: 'terraform-state-rg'
              backendAzureRmStorageAccountName: 'tfstateall'
              backendAzureRmContainerName: 'tfstate'
              backendAzureRmKey: 'terraform.tfstate'
          
          - task: TerraformTaskV3@3
            displayName: 'Terraform Workspace'
            inputs:
              provider: 'azurerm'
              command: 'custom'
              workingDirectory: '$(TF_WORKING_DIR)'
              customCommand: 'workspace select $(ENVIRONMENT) || terraform workspace new $(ENVIRONMENT)'
          
          - task: TerraformTaskV3@3
            displayName: 'Terraform Plan'
            inputs:
              provider: 'azurerm'
              command: 'plan'
              workingDirectory: '$(TF_WORKING_DIR)'
              environmentServiceNameAzureRM: 'Terraform-ServiceConnection'
              commandOptions: '-out=$(TF_WORKING_DIR)/plan.tfplan -var-file="environments/$(ENVIRONMENT).tfvars"'
          
          - task: TerraformTaskV3@3
            displayName: 'Terraform Apply'
            inputs:
              provider: 'azurerm'
              command: 'apply'
              workingDirectory: '$(TF_WORKING_DIR)'
              environmentServiceNameAzureRM: 'Terraform-ServiceConnection'
              commandOptions: '$(TF_WORKING_DIR)/plan.tfplan'
```

### Implementing Terraform Import

For importing existing resources:

```yaml
# pipeline/import-pipeline.yml
trigger: none

pool:
  vmImage: 'ubuntu-latest'

variables:
- group: Terraform-Azure-Secrets
- name: TF_VERSION
  value: '1.3.6'
- name: TF_WORKING_DIR
  value: '$(System.DefaultWorkingDirectory)/terraform'
- name: RESOURCE_ADDRESS
  value: 'azurerm_resource_group.example'
- name: RESOURCE_ID
  value: '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-rg'

steps:
- task: TerraformInstaller@0
  displayName: 'Install Terraform $(TF_VERSION)'
  inputs:
    terraformVersion: '$(TF_VERSION)'

- task: TerraformTaskV3@3
  displayName: 'Terraform Init'
  inputs:
    provider: 'azurerm'
    command: 'init'
    workingDirectory: '$(TF_WORKING_DIR)'
    backendServiceArm: 'Terraform-ServiceConnection'
    backendAzureRmResourceGroupName: 'terraform-state-rg'
    backendAzureRmStorageAccountName: 'tfstatedev'
    backendAzureRmContainerName: 'tfstate'
    backendAzureRmKey: 'terraform.tfstate'

- task: TerraformTaskV3@3
  displayName: 'Terraform Import'
  inputs:
    provider: 'azurerm'
    command: 'custom'
    workingDirectory: '$(TF_WORKING_DIR)'
    customCommand: 'import $(RESOURCE_ADDRESS) $(RESOURCE_ID)'
    environmentServiceNameAzureRM: 'Terraform-ServiceConnection'
```

## Troubleshooting

### Common Issues and Solutions

1. **Authentication Failures**:
   - Ensure service principal has correct permissions
   - Verify secret values in variable group are up to date

2. **State Locking Issues**:
   - Check for abandoned locks in Azure Storage
   - Ensure storage account is accessible

3. **Pipeline Failures**:
   - Check logs for detailed error messages
   - Validate Terraform code locally before pushing

4. **Backend Configuration Problems**:
   - Ensure backend resource group and storage account exist
   - Verify backend configuration matches in pipeline and Terraform

5. **Permission Issues**:
   - Ensure service principal has Contributor access to subscription
   - Check storage account permissions for state management

### Debugging Tips

- Use `-no-color` option for better log readability in pipelines
- Add `TF_LOG=DEBUG` as an environment variable for verbose logging
- Run `terraform validate` locally before committing changes
- Use `terraform fmt` to maintain consistent code style

---

This guide provides a comprehensive approach to integrating Terraform with Azure DevOps for Infrastructure as Code. By following these practices, you can implement a robust, secure, and efficient CI/CD pipeline for your infrastructure deployments.
