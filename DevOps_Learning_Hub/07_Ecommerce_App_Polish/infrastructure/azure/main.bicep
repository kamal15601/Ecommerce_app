// main.bicep - Main deployment file for e-commerce application infrastructure

// Parameters
@description('Environment type (dev, staging, prod)')
@allowed([
  'dev'
  'staging'
  'prod'
])
param environmentType string

@description('Prefix for resource names')
param prefix string = 'ecommerce'

@description('Primary location for all resources')
param location string = resourceGroup().location

@description('AKS cluster SKU')
param aksSkuTier string = environmentType == 'prod' ? 'Standard' : 'Free'

@description('AKS node count')
param aksNodeCount int = environmentType == 'prod' ? 3 : (environmentType == 'staging' ? 2 : 1)

@description('AKS node size')
param aksNodeSize string = environmentType == 'prod' ? 'Standard_D4s_v3' : 'Standard_D2s_v3'

@description('PostgreSQL SKU')
param postgreSqlSkuName string = environmentType == 'prod' ? 'GP_Gen5_4' : 'B_Gen5_1'

@description('Redis Cache SKU')
param redisCacheSku string = environmentType == 'prod' ? 'Standard' : 'Basic'

@description('Redis Cache capacity')
param redisCacheCapacity int = environmentType == 'prod' ? 2 : 0

@description('Application Insights retention days')
param appInsightsRetentionDays int = environmentType == 'prod' ? 90 : 30

// Variables
var resourceNames = {
  vnet: '${prefix}-vnet-${environmentType}'
  aks: '${prefix}-aks-${environmentType}'
  acr: '${replace(prefix, '-', '')}acr${environmentType}'
  keyVault: '${prefix}-kv-${environmentType}'
  appInsights: '${prefix}-ai-${environmentType}'
  logAnalytics: '${prefix}-la-${environmentType}'
  postgresql: '${prefix}-psql-${environmentType}'
  redis: '${prefix}-redis-${environmentType}'
  storage: '${replace(prefix, '-', '')}storage${environmentType}'
  appGateway: '${prefix}-appgw-${environmentType}'
  frontDoor: '${prefix}-fd-${environmentType}'
  userManagedIdentity: '${prefix}-umi-${environmentType}'
}

// Network Security Group for AKS subnet
resource aksNsg 'Microsoft.Network/networkSecurityGroups@2022-07-01' = {
  name: '${resourceNames.aks}-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowHttpsInbound'
        properties: {
          priority: 100
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: resourceNames.vnet
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'aks-subnet'
        properties: {
          addressPrefix: '10.0.0.0/22'
          networkSecurityGroup: {
            id: aksNsg.id
          }
        }
      }
      {
        name: 'app-gateway-subnet'
        properties: {
          addressPrefix: '10.0.4.0/24'
        }
      }
      {
        name: 'database-subnet'
        properties: {
          addressPrefix: '10.0.5.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

// User Managed Identity for AKS
resource userManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: resourceNames.userManagedIdentity
  location: location
}

// Azure Container Registry
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: resourceNames.acr
  location: location
  sku: {
    name: environmentType == 'prod' ? 'Premium' : 'Standard'
  }
  properties: {
    adminUserEnabled: false
    dataEndpointEnabled: environmentType == 'prod'
    publicNetworkAccess: environmentType == 'prod' ? 'Disabled' : 'Enabled'
  }
}

// AKS Cluster
resource aks 'Microsoft.ContainerService/managedClusters@2023-07-02-preview' = {
  name: resourceNames.aks
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userManagedIdentity.id}': {}
    }
  }
  sku: {
    name: 'Base'
    tier: aksSkuTier
  }
  properties: {
    dnsPrefix: '${prefix}-${environmentType}'
    enableRBAC: true
    kubernetesVersion: '1.26.6'
    networkProfile: {
      networkPlugin: 'azure'
      networkPolicy: 'azure'
      serviceCidr: '10.1.0.0/16'
      dnsServiceIP: '10.1.0.10'
      dockerBridgeCidr: '172.17.0.1/16'
    }
    agentPoolProfiles: [
      {
        name: 'agentpool'
        count: aksNodeCount
        vmSize: aksNodeSize
        mode: 'System'
        maxPods: 30
        type: 'VirtualMachineScaleSets'
        vnetSubnetID: vnet.properties.subnets[0].id
        enableAutoScaling: environmentType == 'prod'
        minCount: environmentType == 'prod' ? 3 : null
        maxCount: environmentType == 'prod' ? 6 : null
        availabilityZones: environmentType == 'prod' ? [
          '1'
          '2'
          '3'
        ] : null
      }
    ]
    aadProfile: {
      managed: true
      enableAzureRBAC: true
    }
    addonProfiles: {
      azurePolicy: {
        enabled: true
      }
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalytics.id
        }
      }
      azureKeyvaultSecretsProvider: {
        enabled: true
        config: {
          enableSecretRotation: 'true'
        }
      }
    }
  }
  dependsOn: [
    vnet
  ]
}

// Log Analytics Workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: resourceNames.logAnalytics
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

// Application Insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: resourceNames.appInsights
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
    RetentionInDays: appInsightsRetentionDays
  }
}

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: resourceNames.keyVault
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
  }
}

// PostgreSQL Server
resource postgresql 'Microsoft.DBforPostgreSQL/flexibleServers@2022-12-01' = {
  name: resourceNames.postgresql
  location: location
  sku: {
    name: postgreSqlSkuName
    tier: environmentType == 'prod' ? 'GeneralPurpose' : 'Burstable'
  }
  properties: {
    version: '14'
    administratorLogin: 'ecommerceadmin'
    administratorLoginPassword: 'Placeholder-Password-To-Be-Changed'
    storage: {
      storageSizeGB: environmentType == 'prod' ? 256 : 32
    }
    backup: {
      backupRetentionDays: environmentType == 'prod' ? 35 : 7
      geoRedundantBackup: environmentType == 'prod' ? 'Enabled' : 'Disabled'
    }
    highAvailability: {
      mode: environmentType == 'prod' ? 'ZoneRedundant' : 'Disabled'
    }
  }
}

// Redis Cache
resource redis 'Microsoft.Cache/redis@2023-05-01' = {
  name: resourceNames.redis
  location: location
  properties: {
    sku: {
      name: redisCacheSku
      family: redisCacheSku == 'Premium' ? 'P' : 'C'
      capacity: redisCacheCapacity
    }
    enableNonSslPort: false
    minimumTlsVersion: '1.2'
  }
}

// Storage Account
resource storage 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: resourceNames.storage
  location: location
  kind: 'StorageV2'
  sku: {
    name: environmentType == 'prod' ? 'Standard_GRS' : 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    defaultToOAuthAuthentication: true
  }
}

// Role assignment for AKS to pull images from ACR
resource acrPullRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, userManagedIdentity.id, 'acrpull')
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d') // AcrPull role
    principalId: userManagedIdentity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Role assignment for AKS to access Key Vault secrets
resource keyVaultSecretsUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, userManagedIdentity.id, 'keyVaultSecretsUser')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User role
    principalId: userManagedIdentity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Outputs
output aksClusterName string = aks.name
output acrName string = acr.name
output keyVaultName string = keyVault.name
output postgreSqlServerName string = postgresql.name
output redisName string = redis.name
output storageName string = storage.name
output appInsightsName string = appInsights.name
output appInsightsConnectionString string = appInsights.properties.ConnectionString
output managedIdentityId string = userManagedIdentity.id
