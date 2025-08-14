# Multi-Cloud Deployment Strategies with Azure

This guide covers comprehensive strategies for implementing multi-cloud deployments with Azure as a primary cloud platform, focusing on best practices, tools, and real-world implementation patterns.

## Table of Contents

1. [Introduction to Multi-Cloud](#introduction-to-multi-cloud)
2. [Multi-Cloud Benefits and Challenges](#multi-cloud-benefits-and-challenges)
3. [Azure as a Primary Cloud Platform](#azure-as-a-primary-cloud-platform)
4. [Multi-Cloud Architecture Patterns](#multi-cloud-architecture-patterns)
5. [Identity and Access Management](#identity-and-access-management)
6. [Network Connectivity and Security](#network-connectivity-and-security)
7. [Data Management and Consistency](#data-management-and-consistency)
8. [Multi-Cloud Deployment Tools](#multi-cloud-deployment-tools)
9. [Monitoring and Observability](#monitoring-and-observability)
10. [Cost Management](#cost-management)
11. [Disaster Recovery and Business Continuity](#disaster-recovery-and-business-continuity)
12. [Hands-on Lab: Azure + AWS Deployment](#hands-on-lab-azure--aws-deployment)

## Introduction to Multi-Cloud

### Definition and Scope

Multi-cloud refers to the use of cloud computing services from two or more cloud providers to run applications and workloads. This strategy differs from hybrid cloud, which combines public and private cloud environments.

### Evolution of Multi-Cloud

1. **Single Cloud (2006-2012)**
   - Organizations adopted a single cloud provider
   - Limited service offerings and regional presence
   - Concerns about vendor lock-in

2. **Hybrid Cloud (2012-2018)**
   - Combined on-premises and public cloud
   - Focused on extending data centers
   - Limited cross-cloud integration

3. **Multi-Cloud (2018-Present)**
   - Strategic use of multiple cloud providers
   - Best-of-breed services from different providers
   - Emphasis on avoiding lock-in and optimizing workloads

### Types of Multi-Cloud Strategies

1. **Diversification**
   - Spreading workloads across providers for risk mitigation
   - Avoiding vendor lock-in
   - Optimizing costs across providers

2. **Best-of-Breed**
   - Selecting specific services from different providers
   - Utilizing unique strengths of each cloud
   - Maximizing service capabilities

3. **Geographical Distribution**
   - Deploying to different regions across providers
   - Meeting data sovereignty requirements
   - Optimizing for user proximity

## Multi-Cloud Benefits and Challenges

### Benefits

1. **Risk Mitigation**
   - Reduced impact of provider outages
   - Protection against vendor lock-in
   - Diversified business risk

2. **Best-of-Breed Services**
   - Access to unique capabilities across providers
   - Optimization for specific workloads
   - Flexibility to adopt new services

3. **Global Reach**
   - Expanded geographical presence
   - Meeting regional compliance requirements
   - Optimizing for end-user experience

4. **Negotiation Leverage**
   - Improved pricing negotiation position
   - Flexible contract terms
   - Alternative options for services

### Challenges

1. **Operational Complexity**
   - Multiple management interfaces
   - Different service models and APIs
   - Increased operational overhead

2. **Skill Requirements**
   - Broader expertise needed
   - Learning curve for multiple platforms
   - Training and certification needs

3. **Integration Challenges**
   - Cross-cloud service integration
   - Data consistency and synchronization
   - Identity and access management

4. **Cost Management**
   - Complex billing across providers
   - Potential for increased costs
   - Optimization challenges

## Azure as a Primary Cloud Platform

### Azure's Multi-Cloud Strengths

1. **Hybrid and Multi-Cloud Tools**
   - Azure Arc for cross-cloud resource management
   - Azure Stack for consistent experience
   - Multi-cloud management through Azure portal

2. **Open Source Commitment**
   - Strong support for Kubernetes and containers
   - Participation in open-source projects
   - Cross-platform tools and SDKs

3. **Identity and Security**
   - Azure Active Directory for cross-cloud identity
   - Centralized security management
   - Consistent security policies

4. **Data Services**
   - Azure Cosmos DB multi-region support
   - Azure Database for PostgreSQL/MySQL flexibility
   - Data synchronization capabilities

### Azure Arc

Azure Arc extends Azure management to any infrastructure, including other clouds:

1. **Key Capabilities**
   - Manage Kubernetes clusters across clouds
   - Deploy Azure services anywhere
   - Apply consistent governance and policy

2. **Supported Resources**
   - Servers (Windows and Linux)
   - Kubernetes clusters
   - Data services
   - Azure SQL Managed Instance

3. **Implementation Example**

```yaml
# Example: Azure Arc-enabled Kubernetes configuration
apiVersion: source.toolkit.fluxcd.io/v1beta1
kind: GitRepository
metadata:
  name: flux-system
  namespace: flux-system
spec:
  interval: 1m0s
  ref:
    branch: main
  url: https://github.com/Azure/arc-k8s-demo

---
apiVersion: kustomize.toolkit.fluxcd.io/v1beta1
kind: Kustomization
metadata:
  name: flux-system
  namespace: flux-system
spec:
  interval: 10m0s
  path: ./clusters/azure-arc
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-system
  validation: client
```

### Azure Multi-Cloud Management

1. **Azure Monitor**
   - Cross-cloud resource monitoring
   - Centralized logging and analytics
   - Custom dashboards for multi-cloud visibility

2. **Azure Policy**
   - Policy enforcement across environments
   - Compliance assessment
   - Remediation capabilities

3. **Azure Blueprints**
   - Standardized environment deployment
   - Consistent governance
   - Compliant cloud setups

## Multi-Cloud Architecture Patterns

### Distributed Application Patterns

1. **Active-Active**
   - Workloads running simultaneously across clouds
   - Load balancing between environments
   - High availability and performance optimization

2. **Active-Passive**
   - Primary workloads in one cloud
   - Standby environment in second cloud
   - Failover capabilities for disaster recovery

3. **Distributed Microservices**
   - Services distributed based on cloud strengths
   - API-driven integration between services
   - Independent scaling and management

### Example: Active-Active Web Application

![Active-Active Architecture](https://docs.microsoft.com/en-us/azure/architecture/reference-architectures/hybrid/images/hybrid-ha.png)

```
┌─────────────────────┐     ┌─────────────────────┐
│       Azure         │     │         AWS         │
│  ┌───────────────┐  │     │  ┌───────────────┐  │
│  │  Application  │  │     │  │  Application  │  │
│  │    Gateway    │  │     │  │  Load Balancer│  │
│  └───────┬───────┘  │     │  └───────┬───────┘  │
│          │          │     │          │          │
│  ┌───────┴───────┐  │     │  ┌───────┴───────┐  │
│  │ AKS Cluster   │  │     │  │  EKS Cluster  │  │
│  │ ┌───────────┐ │  │     │  │ ┌───────────┐ │  │
│  │ │ Web Pods  │ │  │     │  │ │ Web Pods  │ │  │
│  │ └───────────┘ │  │     │  │ └───────────┘ │  │
│  └───────┬───────┘  │     │  └───────┬───────┘  │
│          │          │     │          │          │
│  ┌───────┴───────┐  │     │  ┌───────┴───────┐  │
│  │ Cosmos DB     │←─┼─────┼─→│ DynamoDB     │  │
│  └───────────────┘  │     │  └───────────────┘  │
└─────────────────────┘     └─────────────────────┘
         ↑                             ↑
         └─────────────────────────────┘
                 Data Replication
```

### Data Distribution Patterns

1. **Data Replication**
   - Real-time or near-real-time data synchronization
   - Multi-master or master-slave configurations
   - Conflict resolution mechanisms

2. **Data Partitioning**
   - Horizontal or vertical data distribution
   - Geographical partitioning
   - Service-specific data stores

3. **Caching Strategies**
   - Distributed caching across clouds
   - Local cache with synchronization
   - Cache invalidation patterns

### Example: Multi-Cloud Data Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Global Traffic Manager              │
└───────────────┬─────────────────────┬───────────────┘
                │                     │
                ↓                     ↓
┌───────────────────────┐   ┌───────────────────────┐
│       Region A        │   │       Region B        │
│       (Azure)         │   │        (AWS)          │
│                       │   │                       │
│  ┌─────────────────┐  │   │  ┌─────────────────┐  │
│  │  API Gateway    │  │   │  │  API Gateway    │  │
│  └────────┬────────┘  │   │  └────────┬────────┘  │
│           │           │   │           │           │
│  ┌────────┴────────┐  │   │  ┌────────┴────────┐  │
│  │  Microservices  │  │   │  │  Microservices  │  │
│  └────────┬────────┘  │   │  └────────┬────────┘  │
│           │           │   │           │           │
│  ┌────────┴────────┐  │   │  ┌────────┴────────┐  │
│  │   Azure SQL     │◄─┼───┼─►│     Aurora      │  │
│  └─────────────────┘  │   │  └─────────────────┘  │
│                       │   │                       │
│  ┌─────────────────┐  │   │  ┌─────────────────┐  │
│  │  Cosmos DB      │◄─┼───┼─►│   DynamoDB      │  │
│  └─────────────────┘  │   │  └─────────────────┘  │
│                       │   │                       │
│  ┌─────────────────┐  │   │  ┌─────────────────┐  │
│  │  Event Hub      │◄─┼───┼─►│   Kinesis       │  │
│  └─────────────────┘  │   │  └─────────────────┘  │
└───────────────────────┘   └───────────────────────┘
```

## Identity and Access Management

### Centralized Identity

1. **Azure Active Directory (Azure AD)**
   - Central identity provider
   - Single sign-on across clouds
   - Conditional access policies

2. **Federation Patterns**
   - Federation with AWS IAM
   - Federation with Google Cloud IAM
   - SAML and OAuth integration

3. **Role-Based Access Control**
   - Consistent role definitions
   - Privilege management
   - Least privilege principle

### Example: Azure AD Integration with AWS

```powershell
# PowerShell script to set up Azure AD integration with AWS

# 1. Create Enterprise Application in Azure AD
$awsApp = New-AzureADApplication -DisplayName "AWS Single Sign-On" `
                                -Homepage "https://signin.aws.amazon.com/saml" `
                                -ReplyUrls "https://signin.aws.amazon.com/saml" `
                                -IdentifierUris "https://signin.aws.amazon.com/saml" `
                                -GroupMembershipClaims "All"

# 2. Create Service Principal
$spn = New-AzureADServicePrincipal -AppId $awsApp.AppId

# 3. Generate SAML certificate
$certParams = @{
    DisplayName = "AWS SSO Certificate"
    StartDate = Get-Date
    EndDate = (Get-Date).AddYears(3)
    Type = "AsymmetricX509Cert"
    Usage = "Verify"
}
New-AzureADApplicationKeyCredential -ObjectId $awsApp.ObjectId @certParams

# 4. Download the Federation Metadata XML
$metadataUrl = "https://login.microsoftonline.com/$tenantId/federationmetadata/2007-06/federationmetadata.xml"
Invoke-WebRequest -Uri $metadataUrl -OutFile "AzureADMetadata.xml"
```

### Access Management Strategies

1. **Just-in-Time Access**
   - Temporary privileged access
   - Approval workflows
   - Time-limited permissions

2. **Privileged Identity Management**
   - Role activation
   - Access reviews
   - Auditing and monitoring

3. **Managed Identities**
   - Service authentication without credentials
   - Automatic credential management
   - Secure service-to-service communication

## Network Connectivity and Security

### Connectivity Options

1. **VPN Solutions**
   - Site-to-site VPN connections
   - Software-defined WAN
   - VPN peering

2. **Express Route and Direct Connect**
   - Dedicated connections to Azure and AWS
   - High bandwidth and low latency
   - Private connectivity

3. **Software-Defined Networking**
   - Virtual networks across clouds
   - Network policy management
   - Traffic routing and filtering

### Example: Azure to AWS Connectivity

```
┌───────────────────────┐              ┌───────────────────────┐
│       Azure           │              │         AWS           │
│  ┌─────────────────┐  │              │  ┌─────────────────┐  │
│  │   Azure VNet    │  │              │  │     VPC         │  │
│  │                 │  │              │  │                 │  │
│  │  ┌───────────┐  │  │              │  │  ┌───────────┐  │  │
│  │  │  Subnet   │  │  │              │  │  │  Subnet   │  │  │
│  │  └─────┬─────┘  │  │              │  │  └─────┬─────┘  │  │
│  │        │        │  │              │  │        │        │  │
│  │  ┌─────┴─────┐  │  │   IPsec VPN  │  │  ┌─────┴─────┐  │  │
│  │  │   VNet    │  │  │  or Express  │  │  │  Customer │  │  │
│  │  │  Gateway  │◄─┼──┼──Connection──┼──┼─►│  Gateway  │  │  │
│  │  └───────────┘  │  │              │  │  └───────────┘  │  │
│  │                 │  │              │  │                 │  │
│  └─────────────────┘  │              │  └─────────────────┘  │
│                       │              │                       │
└───────────────────────┘              └───────────────────────┘
```

### Security Patterns

1. **Network Security**
   - Consistent security groups
   - Web application firewalls
   - DDoS protection

2. **Data Protection**
   - Encryption in transit and at rest
   - Key management across clouds
   - Data classification and protection

3. **Security Monitoring**
   - Centralized security information and event management (SIEM)
   - Threat detection across environments
   - Security automation and orchestration

### Example: Bicep Template for Network Security Group

```bicep
@description('The name of the Network Security Group')
param nsgName string

@description('The location for the resource')
param location string = resourceGroup().location

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowHTTPSInbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4096
          direction: 'Inbound'
        }
      }
    ]
  }
}

output nsgId string = networkSecurityGroup.id
```

## Data Management and Consistency

### Data Synchronization

1. **Database Replication**
   - Native database replication
   - Change data capture
   - Log shipping

2. **Message-Based Synchronization**
   - Event-driven architecture
   - Message queues for consistency
   - Event sourcing patterns

3. **ETL and Data Pipelines**
   - Scheduled data movement
   - Transformation during transfer
   - Data quality and validation

### Example: Azure to AWS Data Synchronization

```csharp
// C# example using Azure Event Grid and AWS SNS for cross-cloud event synchronization

// Azure Function that receives events from Event Grid and forwards to AWS SNS
public static class EventSynchronizer
{
    [FunctionName("SyncEventToAWS")]
    public static async Task Run(
        [EventGridTrigger] EventGridEvent eventGridEvent,
        ILogger log)
    {
        log.LogInformation($"Processing event: {eventGridEvent.Subject}");

        // Configure AWS SNS client
        var credentials = new BasicAWSCredentials(
            Environment.GetEnvironmentVariable("AWS_ACCESS_KEY"),
            Environment.GetEnvironmentVariable("AWS_SECRET_KEY"));
        
        var snsClient = new AmazonSimpleNotificationServiceClient(credentials, 
            RegionEndpoint.GetBySystemName(Environment.GetEnvironmentVariable("AWS_REGION")));

        // Forward the event to AWS SNS
        var request = new PublishRequest
        {
            TopicArn = Environment.GetEnvironmentVariable("AWS_SNS_TOPIC_ARN"),
            Message = JsonConvert.SerializeObject(new
            {
                Source = "Azure",
                EventId = eventGridEvent.Id,
                EventType = eventGridEvent.EventType,
                Subject = eventGridEvent.Subject,
                Data = eventGridEvent.Data,
                EventTime = eventGridEvent.EventTime
            })
        };

        try
        {
            var response = await snsClient.PublishAsync(request);
            log.LogInformation($"Event forwarded to AWS SNS. MessageId: {response.MessageId}");
        }
        catch (Exception ex)
        {
            log.LogError($"Error forwarding event to AWS: {ex.Message}");
            throw;
        }
    }
}
```

### Data Consistency Models

1. **Strong Consistency**
   - Synchronous replication
   - Transaction guarantees
   - Higher latency, lower availability

2. **Eventual Consistency**
   - Asynchronous replication
   - Optimistic concurrency
   - Lower latency, higher availability

3. **Conflict Resolution**
   - Last-writer-wins
   - Custom merge logic
   - Versioning and timestamps

### Shared Database Services

1. **Managed Database Services**
   - Azure Cosmos DB multi-region
   - Azure SQL Database geo-replication
   - PostgreSQL/MySQL cross-region replication

2. **Distributed Caching**
   - Redis Cache across clouds
   - Content Delivery Networks
   - Edge caching strategies

## Multi-Cloud Deployment Tools

### Infrastructure as Code

1. **Terraform**
   - Multi-cloud provider support
   - Consistent resource definitions
   - State management across clouds

2. **ARM Templates and Bicep**
   - Azure-native IaC
   - Integration with other deployment tools
   - Resource consistency

3. **AWS CloudFormation**
   - AWS-native IaC
   - Stack sets for multi-account deployment
   - Cross-stack references

### Example: Terraform for Multi-Cloud

```hcl
# Terraform configuration for multi-cloud deployment

# Azure provider configuration
provider "azurerm" {
  features {}
}

# AWS provider configuration
provider "aws" {
  region = "us-west-2"
}

# Azure resource group
resource "azurerm_resource_group" "example" {
  name     = "multicloud-example-rg"
  location = "East US"
}

# Azure virtual network
resource "azurerm_virtual_network" "example" {
  name                = "multicloud-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

# Azure subnet
resource "azurerm_subnet" "example" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}

# AWS VPC
resource "aws_vpc" "example" {
  cidr_block = "10.1.0.0/16"
  
  tags = {
    Name = "multicloud-vpc"
  }
}

# AWS subnet
resource "aws_subnet" "example" {
  vpc_id     = aws_vpc.example.id
  cidr_block = "10.1.1.0/24"
  
  tags = {
    Name = "multicloud-subnet"
  }
}

# Azure Cosmos DB account
resource "azurerm_cosmosdb_account" "example" {
  name                = "multicloud-cosmos-db"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.example.location
    failover_priority = 0
  }
}

# AWS DynamoDB table
resource "aws_dynamodb_table" "example" {
  name           = "multicloud-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

# Output the connection strings
output "cosmos_db_connection_string" {
  value     = azurerm_cosmosdb_account.example.connection_strings[0]
  sensitive = true
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.example.name
}
```

### Container Orchestration

1. **Kubernetes**
   - Platform-agnostic container orchestration
   - Multi-cluster management
   - Consistent application deployment

2. **Azure Kubernetes Service (AKS)**
   - Managed Kubernetes in Azure
   - Integration with Azure services
   - Advanced networking options

3. **AWS Elastic Kubernetes Service (EKS)**
   - Managed Kubernetes in AWS
   - Integration with AWS services
   - Fargate serverless option

### Example: Multi-Cloud Kubernetes with Helm

```yaml
# Helm chart for multi-cloud deployment (values.yaml)
global:
  environment: production

# Database configuration
database:
  azure:
    enabled: true
    connectionStringSecret: azure-cosmos-connection
    type: cosmosdb
  aws:
    enabled: true
    connectionStringSecret: aws-dynamodb-connection
    type: dynamodb

# Frontend configuration
frontend:
  replicaCount: 3
  image:
    repository: myregistry.azurecr.io/frontend
    tag: latest
  service:
    type: LoadBalancer
    port: 80
  ingress:
    enabled: true
    annotations:
      kubernetes.io/ingress.class: azure/application-gateway
      cert-manager.io/cluster-issuer: letsencrypt
    hosts:
      - host: app.example.com
        paths:
          - /

# Backend configuration
backend:
  replicaCount: 3
  image:
    repository: myregistry.azurecr.io/backend
    tag: latest
  service:
    type: ClusterIP
    port: 8080
  autoscaling:
    enabled: true
    minReplicas: 3
    maxReplicas: 10
    targetCPUUtilizationPercentage: 80

# Cloud-specific configuration
cloudProvider:
  azure:
    resourceGroup: multicloud-example-rg
    location: eastus
    storageClass: managed-premium
  aws:
    region: us-west-2
    storageClass: gp2

# Monitoring configuration
monitoring:
  enabled: true
  prometheus:
    enabled: true
  grafana:
    enabled: true
```

### CI/CD for Multi-Cloud

1. **GitHub Actions**
   - Multi-environment workflows
   - Conditional deployment steps
   - Support for multiple clouds

2. **Azure DevOps Pipelines**
   - Multi-stage pipelines
   - Environment targeting
   - Integration with Azure and other clouds

3. **Jenkins**
   - Customizable pipelines
   - Plugin support for various clouds
   - Advanced orchestration

### Example: GitHub Actions for Multi-Cloud Deployment

```yaml
# GitHub workflow for multi-cloud deployment
name: Multi-Cloud Deployment

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Set up .NET Core
      uses: actions/setup-dotnet@v1
      with:
        dotnet-version: '6.0.x'
        
    - name: Build and test
      run: |
        dotnet restore
        dotnet build --configuration Release --no-restore
        dotnet test --no-restore --verbosity normal
        
    - name: Build Docker image
      run: docker build -t myapp:${{ github.sha }} .
      
    - name: Login to Azure Container Registry
      uses: azure/docker-login@v1
      with:
        login-server: myregistry.azurecr.io
        username: ${{ secrets.ACR_USERNAME }}
        password: ${{ secrets.ACR_PASSWORD }}
        
    - name: Push to Azure Container Registry
      run: |
        docker tag myapp:${{ github.sha }} myregistry.azurecr.io/myapp:${{ github.sha }}
        docker tag myapp:${{ github.sha }} myregistry.azurecr.io/myapp:latest
        docker push myregistry.azurecr.io/myapp:${{ github.sha }}
        docker push myregistry.azurecr.io/myapp:latest
        
    - name: Login to Amazon ECR
      uses: aws-actions/amazon-ecr-login@v1
      
    - name: Push to Amazon ECR
      env:
        ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
      run: |
        docker tag myapp:${{ github.sha }} $ECR_REGISTRY/myapp:${{ github.sha }}
        docker tag myapp:${{ github.sha }} $ECR_REGISTRY/myapp:latest
        docker push $ECR_REGISTRY/myapp:${{ github.sha }}
        docker push $ECR_REGISTRY/myapp:latest
  
  deploy-to-azure:
    needs: build
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Login to Azure
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
        
    - name: Deploy to AKS
      uses: azure/k8s-deploy@v1
      with:
        namespace: production
        manifests: |
          kubernetes/azure/deployment.yaml
          kubernetes/azure/service.yaml
        images: |
          myregistry.azurecr.io/myapp:${{ github.sha }}
        kubectl-version: 'latest'
        
  deploy-to-aws:
    needs: build
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v1
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-west-2
        
    - name: Update kubeconfig
      run: aws eks update-kubeconfig --name my-cluster --region us-west-2
        
    - name: Deploy to EKS
      run: |
        kubectl apply -f kubernetes/aws/deployment.yaml
        kubectl apply -f kubernetes/aws/service.yaml
        kubectl set image deployment/myapp myapp=${{ steps.login-ecr.outputs.registry }}/myapp:${{ github.sha }}
```

## Monitoring and Observability

### Unified Monitoring Approach

1. **Azure Monitor**
   - Cross-cloud resource monitoring
   - Centralized log management
   - Application insights

2. **Distributed Tracing**
   - End-to-end transaction tracking
   - Cross-cloud service dependencies
   - Performance analysis

3. **Custom Dashboards**
   - Multi-cloud overview
   - Service health monitoring
   - Cost and utilization tracking

### Example: Azure Monitor for Multi-Cloud

```bicep
@description('The name of the Log Analytics workspace')
param logAnalyticsWorkspaceName string

@description('The location for the resources')
param location string = resourceGroup().location

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'multicloud-app-insights'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
    RetentionInDays: 90
    IngestionMode: 'LogAnalytics'
  }
}

output workspaceId string = logAnalyticsWorkspace.id
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
```

### Monitoring Tools Integration

1. **Third-Party Solutions**
   - Datadog for multi-cloud monitoring
   - New Relic for application performance
   - Splunk for centralized logging

2. **Service Mesh**
   - Istio for cross-cloud service mesh
   - Traffic management and observability
   - Security and policy enforcement

### Alerting and Incident Management

1. **Unified Alerting**
   - Cross-cloud alert definition
   - Correlation of related alerts
   - Automated remediation

2. **Incident Response**
   - Centralized incident management
   - Runbooks for cross-cloud issues
   - Post-incident analysis

## Cost Management

### Cost Visibility

1. **Azure Cost Management**
   - Integration with AWS and GCP
   - Cost allocation and chargeback
   - Budget tracking

2. **Cloud-Specific Tools**
   - AWS Cost Explorer
   - Google Cloud Billing
   - Third-party cost management

3. **Tagging Strategies**
   - Consistent tagging across clouds
   - Cost allocation tags
   - Resource ownership and lifecycle

### Example: Terraform with Consistent Tagging

```hcl
# Define common tags
locals {
  common_tags = {
    Environment     = var.environment
    Project         = var.project_name
    Owner           = var.owner
    CostCenter      = var.cost_center
    DeploymentType  = "multi-cloud"
  }
  
  azure_tags = merge(local.common_tags, {
    Source = "Terraform"
  })
  
  aws_tags = merge(local.common_tags, {
    Provisioner = "Terraform"
  })
}

# Azure resources with consistent tags
resource "azurerm_resource_group" "example" {
  name     = "multicloud-example-rg"
  location = "East US"
  tags     = local.azure_tags
}

# AWS resources with consistent tags
resource "aws_vpc" "example" {
  cidr_block = "10.1.0.0/16"
  tags       = local.aws_tags
}
```

### Cost Optimization

1. **Right-Sizing**
   - Resource optimization
   - Scaling policies
   - Reservation planning

2. **Spot Instances and Low-Priority VMs**
   - Cost-effective compute
   - Resilient workload design
   - Automated management

3. **Cloud-Specific Optimizations**
   - Azure Hybrid Benefit
   - AWS Savings Plans
   - Reserved Instances

## Disaster Recovery and Business Continuity

### Multi-Cloud Resilience

1. **Cross-Cloud Backup**
   - Data backup across clouds
   - Snapshot management
   - Retention policies

2. **Failover Strategies**
   - Active-passive configurations
   - Traffic redirection
   - Data synchronization

3. **Service Continuity**
   - Application deployment across clouds
   - Service-level replication
   - State management

### Example: Azure Site Recovery for Multi-Cloud

```powershell
# PowerShell script to set up Azure Site Recovery for AWS EC2 instances

# 1. Create a Recovery Services vault
$vault = New-AzRecoveryServicesVault -Name "MultiCloudRecoveryVault" `
                                    -ResourceGroupName "DR-RG" `
                                    -Location "East US"

# 2. Set vault context
Set-AzRecoveryServicesAsrVaultContext -Vault $vault

# 3. Create a fabric for the primary site (AWS)
$awsFabric = New-AzRecoveryServicesAsrFabric -Name "AWS-Fabric" `
                                            -Type HyperVSite

# 4. Create a fabric for the recovery site (Azure)
$azureFabric = New-AzRecoveryServicesAsrFabric -Name "Azure-Fabric" `
                                              -Type Azure

# 5. Create a protection container in the AWS fabric
$awsContainer = New-AzRecoveryServicesAsrProtectionContainer `
                    -Name "AWS-Container" `
                    -Fabric $awsFabric

# 6. Create a protection container in the Azure fabric
$azureContainer = New-AzRecoveryServicesAsrProtectionContainer `
                      -Name "Azure-Container" `
                      -Fabric $azureFabric

# 7. Create a replication policy
$policyName = "MultiCloudReplicationPolicy"
$policyResult = New-AzRecoveryServicesAsrPolicy -Name $policyName `
                                               -RecoveryPointRetentionInHours 24 `
                                               -ApplicationConsistentSnapshotFrequencyInHours 4 `
                                               -ReplicationInterval 30

# 8. Create a protection container mapping between AWS and Azure
$mapping = New-AzRecoveryServicesAsrProtectionContainerMapping `
               -Name "AWS-To-Azure" `
               -Policy $policyResult `
               -PrimaryProtectionContainer $awsContainer `
               -RecoveryProtectionContainer $azureContainer
```

### Business Continuity Testing

1. **Regular DR Drills**
   - Scheduled failover testing
   - Recovery time validation
   - Process documentation

2. **Chaos Engineering**
   - Controlled failure testing
   - System resilience verification
   - Automated recovery validation

## Hands-on Lab: Azure + AWS Deployment

This hands-on lab guides you through setting up a multi-cloud application deployment across Azure and AWS.

### Prerequisites

1. Azure subscription
2. AWS account
3. Azure CLI installed
4. AWS CLI installed
5. Terraform installed
6. Sample application code (containerized)

### Step 1: Configure Authentication

1. Log in to Azure:

```bash
az login
```

2. Configure AWS credentials:

```bash
aws configure
```

3. Create a Terraform variables file (`terraform.tfvars`):

```hcl
# Azure variables
azure_subscription_id = "your-subscription-id"
azure_tenant_id       = "your-tenant-id"
azure_location        = "eastus"

# AWS variables
aws_region            = "us-west-2"
```

### Step 2: Create a Terraform Configuration

Create a `main.tf` file:

```hcl
# Configure the providers
provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  tenant_id       = var.azure_tenant_id
}

provider "aws" {
  region = var.aws_region
}

# Azure resources
resource "azurerm_resource_group" "example" {
  name     = "multicloud-demo-rg"
  location = var.azure_location
}

resource "azurerm_container_registry" "example" {
  name                = "multicloudacr"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku                 = "Standard"
  admin_enabled       = true
}

resource "azurerm_kubernetes_cluster" "example" {
  name                = "multicloud-aks"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  dns_prefix          = "multicloud-aks"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_cosmosdb_account" "example" {
  name                = "multicloud-cosmos"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.example.location
    failover_priority = 0
  }

  capabilities {
    name = "EnableServerless"
  }
}

# AWS resources
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "multicloud-vpc"
  }
}

resource "aws_subnet" "example" {
  count = 2
  
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone = "${var.aws_region}${count.index == 0 ? "a" : "b"}"
  
  tags = {
    Name = "multicloud-subnet-${count.index}"
  }
}

resource "aws_eks_cluster" "example" {
  name     = "multicloud-eks"
  role_arn = aws_iam_role.eks.arn

  vpc_config {
    subnet_ids = aws_subnet.example[*].id
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_service_policy,
  ]
}

resource "aws_iam_role" "eks" {
  name = "eks-cluster-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks.name
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks.name
}

resource "aws_dynamodb_table" "example" {
  name           = "multicloud-data"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

# Outputs
output "azure_acr_login_server" {
  value = azurerm_container_registry.example.login_server
}

output "azure_acr_admin_username" {
  value = azurerm_container_registry.example.admin_username
}

output "azure_acr_admin_password" {
  value     = azurerm_container_registry.example.admin_password
  sensitive = true
}

output "azure_aks_kube_config" {
  value     = azurerm_kubernetes_cluster.example.kube_config_raw
  sensitive = true
}

output "cosmos_db_endpoint" {
  value = azurerm_cosmosdb_account.example.endpoint
}

output "cosmos_db_key" {
  value     = azurerm_cosmosdb_account.example.primary_key
  sensitive = true
}

output "aws_eks_endpoint" {
  value = aws_eks_cluster.example.endpoint
}

output "aws_dynamodb_table_name" {
  value = aws_dynamodb_table.example.name
}
```

### Step 3: Create Variable Definitions

Create a `variables.tf` file:

```hcl
variable "azure_subscription_id" {
  description = "The Azure subscription ID"
  type        = string
}

variable "azure_tenant_id" {
  description = "The Azure tenant ID"
  type        = string
}

variable "azure_location" {
  description = "The Azure region to deploy resources"
  type        = string
  default     = "eastus"
}

variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}
```

### Step 4: Deploy the Infrastructure

1. Initialize Terraform:

```bash
terraform init
```

2. Plan the deployment:

```bash
terraform plan -out=tfplan
```

3. Apply the deployment:

```bash
terraform apply tfplan
```

### Step 5: Configure Kubernetes Clusters

1. Configure kubectl for AKS:

```bash
az aks get-credentials --resource-group multicloud-demo-rg --name multicloud-aks
```

2. Configure kubectl for EKS:

```bash
aws eks update-kubeconfig --name multicloud-eks --region us-west-2
```

3. Verify connections:

```bash
# Check AKS connection
kubectl config use-context multicloud-aks
kubectl get nodes

# Check EKS connection
kubectl config use-context multicloud-eks
kubectl get nodes
```

### Step 6: Create Kubernetes Deployment Files

1. Create an Azure Kubernetes deployment file (`azure-deployment.yaml`):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: multicloud-app
  labels:
    app: multicloud-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: multicloud-app
  template:
    metadata:
      labels:
        app: multicloud-app
    spec:
      containers:
      - name: multicloud-app
        image: multicloudacr.azurecr.io/multicloud-app:latest
        ports:
        - containerPort: 80
        env:
        - name: COSMOS_DB_ENDPOINT
          valueFrom:
            secretKeyRef:
              name: azure-secrets
              key: cosmos-endpoint
        - name: COSMOS_DB_KEY
          valueFrom:
            secretKeyRef:
              name: azure-secrets
              key: cosmos-key
        - name: DYNAMODB_TABLE
          value: multicloud-data
        - name: AWS_REGION
          value: us-west-2
---
apiVersion: v1
kind: Service
metadata:
  name: multicloud-app
spec:
  selector:
    app: multicloud-app
  ports:
  - port: 80
    targetPort: 80
  type: LoadBalancer
```

2. Create an AWS Kubernetes deployment file (`aws-deployment.yaml`):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: multicloud-app
  labels:
    app: multicloud-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: multicloud-app
  template:
    metadata:
      labels:
        app: multicloud-app
    spec:
      containers:
      - name: multicloud-app
        image: ${AWS_ACCOUNT_ID}.dkr.ecr.us-west-2.amazonaws.com/multicloud-app:latest
        ports:
        - containerPort: 80
        env:
        - name: COSMOS_DB_ENDPOINT
          valueFrom:
            secretKeyRef:
              name: azure-secrets
              key: cosmos-endpoint
        - name: COSMOS_DB_KEY
          valueFrom:
            secretKeyRef:
              name: azure-secrets
              key: cosmos-key
        - name: DYNAMODB_TABLE
          value: multicloud-data
        - name: AWS_REGION
          value: us-west-2
---
apiVersion: v1
kind: Service
metadata:
  name: multicloud-app
spec:
  selector:
    app: multicloud-app
  ports:
  - port: 80
    targetPort: 80
  type: LoadBalancer
```

### Step 7: Build and Push the Container Image

1. Build the container image:

```bash
docker build -t multicloud-app:latest .
```

2. Push to Azure Container Registry:

```bash
# Get ACR login information
ACR_SERVER=$(terraform output -raw azure_acr_login_server)
ACR_USERNAME=$(terraform output -raw azure_acr_admin_username)
ACR_PASSWORD=$(terraform output -raw azure_acr_admin_password)

# Log in to ACR
docker login $ACR_SERVER -u $ACR_USERNAME -p $ACR_PASSWORD

# Tag and push the image
docker tag multicloud-app:latest $ACR_SERVER/multicloud-app:latest
docker push $ACR_SERVER/multicloud-app:latest
```

3. Push to AWS ECR:

```bash
# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create ECR repository
aws ecr create-repository --repository-name multicloud-app --region us-west-2

# Log in to ECR
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com

# Tag and push the image
docker tag multicloud-app:latest $AWS_ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com/multicloud-app:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com/multicloud-app:latest
```

### Step 8: Create Kubernetes Secrets

1. Create secrets in AKS:

```bash
kubectl config use-context multicloud-aks

# Get Cosmos DB credentials
COSMOS_ENDPOINT=$(terraform output -raw cosmos_db_endpoint)
COSMOS_KEY=$(terraform output -raw cosmos_db_key)

# Create secret
kubectl create secret generic azure-secrets \
  --from-literal=cosmos-endpoint=$COSMOS_ENDPOINT \
  --from-literal=cosmos-key=$COSMOS_KEY
```

2. Create secrets in EKS:

```bash
kubectl config use-context multicloud-eks

# Create secret
kubectl create secret generic azure-secrets \
  --from-literal=cosmos-endpoint=$COSMOS_ENDPOINT \
  --from-literal=cosmos-key=$COSMOS_KEY
```

### Step 9: Deploy the Application

1. Deploy to AKS:

```bash
kubectl config use-context multicloud-aks
kubectl apply -f azure-deployment.yaml
```

2. Deploy to EKS:

```bash
kubectl config use-context multicloud-eks

# Replace placeholder with actual AWS account ID
sed "s/\${AWS_ACCOUNT_ID}/$AWS_ACCOUNT_ID/g" aws-deployment.yaml > aws-deployment-updated.yaml

kubectl apply -f aws-deployment-updated.yaml
```

### Step 10: Set Up Cross-Cloud Monitoring

1. Create an Azure Log Analytics workspace:

```bash
az monitor log-analytics workspace create \
  --resource-group multicloud-demo-rg \
  --workspace-name multicloud-workspace \
  --location eastus
```

2. Get the workspace ID and key:

```bash
WORKSPACE_ID=$(az monitor log-analytics workspace show \
  --resource-group multicloud-demo-rg \
  --workspace-name multicloud-workspace \
  --query customerId -o tsv)

WORKSPACE_KEY=$(az monitor log-analytics workspace get-shared-keys \
  --resource-group multicloud-demo-rg \
  --workspace-name multicloud-workspace \
  --query primarySharedKey -o tsv)
```

3. Enable Azure Monitor for Containers on AKS:

```bash
az aks enable-addons \
  --resource-group multicloud-demo-rg \
  --name multicloud-aks \
  --addons monitoring \
  --workspace-resource-id "/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/multicloud-demo-rg/providers/Microsoft.OperationalInsights/workspaces/multicloud-workspace"
```

4. Install Azure Monitor agent on EKS (using Helm):

```bash
# Add Azure Monitor for Containers Helm repo
helm repo add azure-monitor-for-containers https://raw.githubusercontent.com/microsoft/Docker-Provider/ci_prod/charts/

# Install the agent
helm install azure-monitor-containers azure-monitor-for-containers/azuremonitor-containers \
  --set omsagent.secret.wsid=$WORKSPACE_ID \
  --set omsagent.secret.key=$WORKSPACE_KEY \
  --set omsagent.env.clusterName=multicloud-eks
```

### Step 11: Test Multi-Cloud Failover

1. Create a DNS-based load balancing solution:

```bash
# Get service IP addresses
AKS_IP=$(kubectl --context=multicloud-aks get service multicloud-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
EKS_IP=$(kubectl --context=multicloud-eks get service multicloud-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Create Azure Traffic Manager profile
az network traffic-manager profile create \
  --name multicloud-tm \
  --resource-group multicloud-demo-rg \
  --routing-method Performance \
  --unique-dns-name multicloud-app

# Add AKS endpoint
az network traffic-manager endpoint create \
  --name aks-endpoint \
  --profile-name multicloud-tm \
  --resource-group multicloud-demo-rg \
  --type externalEndpoints \
  --target $AKS_IP \
  --endpoint-location eastus \
  --endpoint-status enabled

# Add EKS endpoint
az network traffic-manager endpoint create \
  --name eks-endpoint \
  --profile-name multicloud-tm \
  --resource-group multicloud-demo-rg \
  --type externalEndpoints \
  --target $EKS_IP \
  --endpoint-location westus \
  --endpoint-status enabled
```

2. Test failover:

```bash
# Simulate failure in AKS by scaling down
kubectl --context=multicloud-aks scale deployment multicloud-app --replicas=0

# Verify traffic is routed to EKS
curl -v http://multicloud-app.trafficmanager.net

# Restore AKS
kubectl --context=multicloud-aks scale deployment multicloud-app --replicas=3
```

### Step 12: Clean Up Resources

```bash
# Delete Kubernetes resources
kubectl --context=multicloud-aks delete -f azure-deployment.yaml
kubectl --context=multicloud-eks delete -f aws-deployment-updated.yaml

# Delete Azure Traffic Manager
az network traffic-manager profile delete \
  --name multicloud-tm \
  --resource-group multicloud-demo-rg

# Delete Terraform-provisioned resources
terraform destroy
```

This hands-on lab demonstrates a complete multi-cloud deployment using Azure and AWS, including infrastructure provisioning, application deployment, cross-cloud monitoring, and failover testing.
