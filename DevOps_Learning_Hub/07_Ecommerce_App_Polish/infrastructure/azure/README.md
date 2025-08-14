# Azure Resource Deployment

This directory contains the Azure Resource Manager (ARM) templates and Bicep files for deploying the e-commerce application infrastructure to Azure.

## Table of Contents

1. [Overview](#overview)
2. [Infrastructure Components](#infrastructure-components)
3. [Deployment Instructions](#deployment-instructions)
4. [Environment Configuration](#environment-configuration)
5. [Security Considerations](#security-considerations)
6. [Monitoring and Maintenance](#monitoring-and-maintenance)

## Overview

The e-commerce application is deployed to Azure using Infrastructure as Code (IaC) principles. We use Bicep for defining our infrastructure, which provides a more concise and maintainable syntax compared to ARM templates.

The infrastructure is deployed across three environments:

- **Development**: For feature development and testing
- **Staging**: For pre-production validation
- **Production**: For live customer-facing services

## Infrastructure Components

The Azure infrastructure includes the following components:

### Compute Resources

- **Azure Kubernetes Service (AKS)**: Hosts the containerized application components
- **Azure Container Registry (ACR)**: Stores and manages container images
- **Azure App Service**: Hosts the API documentation and developer portal

### Data Resources

- **Azure Database for PostgreSQL**: Primary relational database
- **Azure Cache for Redis**: Caching layer for improved performance
- **Azure Storage Account**: Blob storage for static assets and backups

### Networking

- **Virtual Network**: Isolated network for the application components
- **Application Gateway**: Handles SSL termination and routing
- **Azure Front Door**: Global load balancing and CDN capabilities

### Security

- **Azure Key Vault**: Securely stores secrets and certificates
- **Azure Entra ID**: Authentication and authorization
- **Network Security Groups**: Network-level security

### Monitoring

- **Azure Monitor**: Core monitoring service
- **Application Insights**: Application performance monitoring
- **Log Analytics**: Centralized logging solution

## Deployment Instructions

### Prerequisites

- Azure CLI installed and configured
- Access to an Azure subscription with appropriate permissions
- Knowledge of the target environment (Dev, Staging, Production)

### Deployment Steps

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-org/ecommerce-app.git
   cd ecommerce-app/infrastructure/azure
   ```

2. **Log in to Azure**:
   ```bash
   az login
   az account set --subscription <subscription-id>
   ```

3. **Create Resource Group (if needed)**:
   ```bash
   az group create --name <resource-group-name> --location <location>
   ```

4. **Deploy the infrastructure**:
   ```bash
   az deployment sub create \
     --name ecommerce-deployment \
     --location <location> \
     --template-file main.bicep \
     --parameters environmentType=<dev|staging|prod> \
                  prefix=ecommerce
   ```

5. **Verify the deployment**:
   ```bash
   az deployment sub show \
     --name ecommerce-deployment \
     --query properties.outputs
   ```

## Environment Configuration

Each environment has its own configuration parameters defined in the corresponding parameter files:

- `parameters.dev.json`
- `parameters.staging.json`
- `parameters.prod.json`

These files contain environment-specific settings such as:

- VM sizes and SKUs
- Scaling parameters
- Network configurations
- Feature flags

## Security Considerations

The infrastructure deployment follows Azure security best practices:

- **Managed Identities**: Used for service-to-service authentication
- **Private Endpoints**: For secure connectivity to PaaS services
- **Role-Based Access Control (RBAC)**: Least privilege access model
- **Network Isolation**: Restricted network access to resources
- **Encryption**: Data encrypted at rest and in transit

## Monitoring and Maintenance

The deployed infrastructure includes comprehensive monitoring:

- **Diagnostic Settings**: Enabled for all resources
- **Alerts**: Configured for critical metrics
- **Dashboard**: Custom Azure dashboard for infrastructure overview
- **Backup Policies**: Regular backups of critical data

To update the infrastructure:

1. Modify the Bicep files as needed
2. Run the deployment command with the `--what-if` flag to preview changes
3. Deploy the updated infrastructure
4. Monitor the changes in Azure Monitor

## Resource Naming Conventions

All resources follow a standardized naming convention:

```
<prefix>-<resource-type>-<environment>[-<instance>]
```

For example:
- `ecommerce-aks-prod`: Production AKS cluster
- `ecommerce-redis-staging`: Staging Redis cache
- `ecommerce-psql-dev-01`: Development PostgreSQL server, instance 01
