# Azure Monitoring and Observability

This guide covers comprehensive monitoring and observability practices for Azure resources, focusing on implementing a complete observability strategy for your cloud workloads.

## Table of Contents

1. [Monitoring Strategy Overview](#monitoring-strategy-overview)
2. [Azure Monitor Fundamentals](#azure-monitor-fundamentals)
3. [Application Insights](#application-insights)
4. [Log Analytics](#log-analytics)
5. [Azure Monitor Alerts](#azure-monitor-alerts)
6. [Azure Monitor Workbooks](#azure-monitor-workbooks)
7. [Azure Monitor for Containers](#azure-monitor-for-containers)
8. [Azure Monitor for VMs](#azure-monitor-for-vms)
9. [Azure Monitor for Databases](#azure-monitor-for-databases)
10. [Integration with DevOps Processes](#integration-with-devops-processes)
11. [Hands-on Lab: Setting up End-to-End Monitoring](#hands-on-lab-setting-up-end-to-end-monitoring)

## Monitoring Strategy Overview

### The Observability Pillars

1. **Metrics**
   - Numerical data points collected at regular intervals
   - Used for real-time monitoring and alerting
   - Low-cardinality data for performance monitoring

2. **Logs**
   - Structured or semi-structured data
   - Used for troubleshooting and forensics
   - High-cardinality data with rich context

3. **Traces**
   - Distributed tracing for requests across services
   - Used for performance analysis and bottleneck identification
   - Shows causal relationships between operations

4. **Dashboards and Visualization**
   - Real-time visibility into system health
   - Historical trends and patterns
   - Custom views for different stakeholders

### Monitoring Levels

1. **Infrastructure Level**
   - Virtual machines, networking, storage
   - Resource utilization and availability
   - Capacity planning and optimization

2. **Platform Level**
   - PaaS services like App Service, Functions, Kubernetes
   - Service-specific metrics and health
   - Platform-level diagnostics

3. **Application Level**
   - Custom application metrics and telemetry
   - User experience and business metrics
   - Application errors and exceptions

4. **Business Level**
   - Key performance indicators (KPIs)
   - User behavior and journeys
   - Business outcomes and impact

## Azure Monitor Fundamentals

### Azure Monitor Architecture

Azure Monitor provides a comprehensive solution for collecting, analyzing, and acting on telemetry from your cloud and on-premises environments.

![Azure Monitor Architecture](https://docs.microsoft.com/en-us/azure/azure-monitor/media/overview/azure-monitor-overview.png)

### Data Collection

1. **Metrics Collection**
   - Platform metrics (automatically collected)
   - Custom metrics (application-defined)
   - Prometheus metrics (for containers)

2. **Log Collection**
   - Azure Activity logs
   - Resource logs
   - VM guest logs
   - Application logs

3. **Distributed Tracing**
   - End-to-end transaction monitoring
   - Service dependencies and interactions
   - Performance timing for operations

### Data Storage

1. **Metrics Database**
   - Time-series database optimized for metrics
   - 93-day retention for platform metrics
   - Configurable retention for custom metrics

2. **Log Analytics Workspace**
   - Centralized repository for all logs
   - Configurable retention (30-730 days)
   - Supports Kusto Query Language (KQL)

### Example: Basic Azure Monitor Setup with Bicep

```bicep
@description('The name of the Log Analytics workspace')
param logAnalyticsWorkspaceName string

@description('The region for the resources')
param location string = resourceGroup().location

@description('Number of days to retain log data')
param retentionInDays int = 30

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: retentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

resource diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diagnostics'
  scope: keyVault
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'AuditEvent'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// Example Key Vault resource to be monitored
resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: 'mykeyvault${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    enableRbacAuthorization: true
    tenantId: subscription().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
  }
}

output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
```

## Application Insights

### Key Features

1. **Application Performance Monitoring**
   - Request rates, response times, failure rates
   - Dependency tracking (databases, external services)
   - Performance counters

2. **Usage Analysis**
   - User flows and journeys
   - Page views and events
   - User demographics and devices

3. **Exception Tracking**
   - Server-side exceptions
   - Client-side errors
   - Custom exception tracking

4. **Availability Testing**
   - URL ping tests
   - Multi-step web tests
   - Global distribution of test locations

### Integration Methods

1. **Auto-Instrumentation**
   - Application Insights SDKs
   - Agent-based monitoring
   - Codeless integration for Azure services

2. **Manual Instrumentation**
   - Custom events and metrics
   - Dependency tracking
   - User context and properties

### Example: Instrumenting a .NET Core Application

```csharp
// Program.cs
var builder = WebApplication.CreateBuilder(args);

// Add Application Insights
builder.Services.AddApplicationInsightsTelemetry();

// Add services to the container
builder.Services.AddControllers();

var app = builder.Build();

// Configure middleware
app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

app.Run();
```

```csharp
// Controller with custom telemetry
using Microsoft.ApplicationInsights;
using Microsoft.AspNetCore.Mvc;

[ApiController]
[Route("[controller]")]
public class OrdersController : ControllerBase
{
    private readonly TelemetryClient _telemetryClient;

    public OrdersController(TelemetryClient telemetryClient)
    {
        _telemetryClient = telemetryClient;
    }

    [HttpPost]
    public IActionResult CreateOrder(OrderModel order)
    {
        try
        {
            // Process order...
            
            // Track custom event
            _telemetryClient.TrackEvent("OrderCreated", new Dictionary<string, string>
            {
                { "OrderId", order.Id.ToString() },
                { "CustomerId", order.CustomerId },
                { "Amount", order.TotalAmount.ToString() }
            });
            
            return Ok();
        }
        catch (Exception ex)
        {
            // Track exception
            _telemetryClient.TrackException(ex, new Dictionary<string, string>
            {
                { "OrderId", order.Id.ToString() },
                { "Operation", "CreateOrder" }
            });
            
            return StatusCode(500);
        }
    }
}
```

### Example: Deploying Application Insights with Bicep

```bicep
@description('The name of the Application Insights resource')
param appInsightsName string

@description('The location for the resources')
param location string = resourceGroup().location

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: '${appInsightsName}-workspace'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
    RetentionInDays: 90
    IngestionMode: 'LogAnalytics'
    SamplingPercentage: 100
  }
}

output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
output appInsightsConnectionString string = appInsights.properties.ConnectionString
```

## Log Analytics

### Data Sources

1. **Azure Services**
   - Azure Activity logs
   - Resource logs
   - Azure Security Center
   - Azure Sentinel

2. **Virtual Machines**
   - Windows event logs
   - Syslog (Linux)
   - Performance counters
   - IIS logs

3. **Containers**
   - Container logs
   - Kubernetes cluster logs
   - Container insights

4. **Custom Sources**
   - Custom logs
   - HTTP Data Collector API
   - Logic Apps and Azure Functions

### Kusto Query Language (KQL)

KQL is a powerful query language used to analyze data in Log Analytics.

#### Basic Query Structure

```kusto
// Table selection
AppRequests
| where TimeGenerated >= ago(1h)
| where Success == false
| summarize FailureCount = count() by OperationName
| sort by FailureCount desc
```

#### Common KQL Operations

1. **Filtering**

```kusto
AppExceptions
| where TimeGenerated >= ago(24h)
| where ExceptionType contains "SqlException"
```

2. **Aggregation**

```kusto
AppRequests
| where TimeGenerated >= ago(1d)
| summarize 
    RequestCount = count(),
    AvgDuration = avg(DurationMs),
    p95Duration = percentile(DurationMs, 95)
  by OperationName
| sort by RequestCount desc
```

3. **Joining Data**

```kusto
let exceptions = AppExceptions
| where TimeGenerated >= ago(1d);
AppRequests
| where TimeGenerated >= ago(1d)
| where Success == false
| join kind=inner exceptions on $left.OperationId == $right.OperationId
| project TimeGenerated, OperationName, ExceptionType, ExceptionMessage
```

4. **Time Series Analysis**

```kusto
AppRequests
| where TimeGenerated >= ago(7d)
| summarize RequestCount = count() by bin(TimeGenerated, 1h), OperationName
| render timechart
```

### Example: Custom Log Collection

```yaml
# azure-monitor-agent-config.yaml
data_sources:
  custom_logs:
  - name: application_logs
    streams: ["Custom-ApplicationLogs"]
    file_patterns: ["/var/log/myapp/*.log"]
    parse_settings:
      timestamp_format: "ISO 8601"
  - name: access_logs
    streams: ["Custom-AccessLogs"]
    file_patterns: ["/var/log/nginx/access.log"]
    parse_settings:
      timestamp_format: "yyyy/MM/dd HH:mm:ss"
streams:
  Custom-ApplicationLogs:
    destinations: ["log_analytics_workspace"]
  Custom-AccessLogs:
    destinations: ["log_analytics_workspace"]
destinations:
  log_analytics_workspace:
    workspace_id: "<workspace-id>"
    workspace_key: "<workspace-key>"
```

## Azure Monitor Alerts

### Alert Types

1. **Metric Alerts**
   - Based on platform or custom metrics
   - Near real-time monitoring
   - Support for dynamic thresholds

2. **Log Alerts**
   - Based on Log Analytics queries
   - Scheduled evaluation
   - Complex conditions and correlations

3. **Activity Log Alerts**
   - Service health issues
   - Administrative actions
   - Security events

4. **Smart Detection Alerts**
   - Anomaly detection
   - Failure anomalies
   - Usage anomalies

### Alert Response

1. **Action Groups**
   - Email notifications
   - SMS and push notifications
   - Webhook integrations
   - Automation runbooks

2. **Alert Processing Rules**
   - Suppression rules
   - Action overrides
   - Routing rules

### Example: Creating Metric Alerts with Bicep

```bicep
@description('The name of the metric alert')
param alertName string

@description('The resource ID of the resource to monitor')
param resourceId string

@description('The threshold value that activates the alert')
param threshold int = 90

@description('The Azure Monitor action group resource ID')
param actionGroupId string

resource metricAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: alertName
  location: 'global'
  properties: {
    description: 'Alert when CPU usage exceeds ${threshold}%'
    severity: 2
    enabled: true
    scopes: [
      resourceId
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'CPU Alert'
          metricName: 'Percentage CPU'
          dimensions: []
          operator: 'GreaterThan'
          threshold: threshold
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroupId
      }
    ]
  }
}
```

### Example: Creating Log Alerts

```bicep
@description('The name of the log alert')
param alertName string

@description('The Log Analytics workspace resource ID')
param workspaceId string

@description('The Azure Monitor action group resource ID')
param actionGroupId string

resource logAlert 'Microsoft.Insights/scheduledQueryRules@2021-08-01' = {
  name: alertName
  location: resourceGroup().location
  properties: {
    description: 'Alert on high error rate'
    displayName: 'High Error Rate Alert'
    enabled: true
    scopes: [
      workspaceId
    ]
    targetResourceTypes: [
      'Microsoft.OperationalInsights/workspaces'
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    severity: 2
    criteria: {
      allOf: [
        {
          query: '''
          AppRequests
          | where TimeGenerated >= ago(15m)
          | where Success == false
          | summarize ErrorCount = count() by bin(TimeGenerated, 5m)
          | where ErrorCount > 10
          '''
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    actions: {
      actionGroups: [
        actionGroupId
      ]
    }
  }
}
```

## Azure Monitor Workbooks

### Workbook Capabilities

1. **Interactive Reports**
   - Parameterized reports
   - Dynamic filtering
   - Time range selection

2. **Visualization Types**
   - Charts and graphs
   - Grids and tables
   - Text and markdown

3. **Data Sources**
   - Log Analytics queries
   - Metrics data
   - Azure Resource Graph
   - Azure Resource Manager API

### Common Workbook Scenarios

1. **Application Monitoring**
   - Performance dashboards
   - Failure analysis
   - User journey tracking

2. **Infrastructure Monitoring**
   - VM performance
   - Capacity planning
   - Resource utilization

3. **Security Monitoring**
   - Security incident investigation
   - Compliance reporting
   - Access review

### Example: Workbook Template (ARM Format)

```json
{
  "type": "Microsoft.Insights/workbooks",
  "name": "[parameters('workbookName')]",
  "location": "[parameters('location')]",
  "kind": "shared",
  "apiVersion": "2021-08-01",
  "properties": {
    "displayName": "Application Performance Dashboard",
    "serializedData": "{\"version\":\"Notebook/1.0\",\"items\":[{\"type\":1,\"content\":{\"json\":\"# Application Performance Dashboard\\r\\n\\r\\nThis dashboard provides an overview of application performance metrics.\"},\"name\":\"Title\"},{\"type\":9,\"content\":{\"version\":\"KqlParameterItem/1.0\",\"parameters\":[{\"id\":\"4f883c2c-8e3e-4b62-a4a8-7ae1d92c0e9c\",\"version\":\"KqlParameterItem/1.0\",\"name\":\"TimeRange\",\"type\":4,\"isRequired\":true,\"value\":{\"durationMs\":86400000},\"typeSettings\":{\"selectableValues\":[{\"durationMs\":300000},{\"durationMs\":900000},{\"durationMs\":1800000},{\"durationMs\":3600000},{\"durationMs\":14400000},{\"durationMs\":43200000},{\"durationMs\":86400000},{\"durationMs\":172800000},{\"durationMs\":259200000},{\"durationMs\":604800000}]}}],\"style\":\"pills\",\"queryType\":0,\"resourceType\":\"microsoft.insights/components\"},\"name\":\"Parameters\"},{\"type\":3,\"content\":{\"version\":\"KqlItem/1.0\",\"query\":\"AppRequests\\r\\n| where TimeGenerated >= ago({TimeRange})\\r\\n| summarize RequestCount = count(), AvgDuration = avg(DurationMs), FailureCount = countif(Success == false) by bin(TimeGenerated, {TimeRange:grain})\\r\\n| extend FailureRate = FailureCount * 100.0 / RequestCount\\r\\n| project TimeGenerated, RequestCount, AvgDuration, FailureRate\",\"size\":0,\"aggregation\":5,\"title\":\"Request Overview\",\"timeContext\":{\"durationMs\":86400000},\"queryType\":0,\"resourceType\":\"microsoft.insights/components\",\"visualization\":\"linechart\"},\"name\":\"Request Overview\"},{\"type\":3,\"content\":{\"version\":\"KqlItem/1.0\",\"query\":\"AppRequests\\r\\n| where TimeGenerated >= ago({TimeRange})\\r\\n| summarize RequestCount = count(), AvgDuration = avg(DurationMs), FailureCount = countif(Success == false) by OperationName\\r\\n| extend FailureRate = FailureCount * 100.0 / RequestCount\\r\\n| sort by RequestCount desc\",\"size\":0,\"title\":\"Operation Statistics\",\"timeContext\":{\"durationMs\":86400000},\"queryType\":0,\"resourceType\":\"microsoft.insights/components\"},\"name\":\"Operation Statistics\"}],\"isLocked\":false}",
    "version": "1.0",
    "sourceId": "[parameters('appInsightsId')]",
    "category": "workbook"
  }
}
```

## Azure Monitor for Containers

### Capabilities

1. **Container Insights**
   - Real-time performance monitoring
   - Container logs
   - Pod metrics and health

2. **Kubernetes Monitoring**
   - Cluster health
   - Node metrics
   - Workload monitoring

3. **Integration Points**
   - AKS integration
   - Azure Container Instances
   - Self-managed Kubernetes

### Deployment Methods

1. **AKS Native Integration**
   - Enable monitoring during cluster creation
   - Add through Azure Portal
   - Use ARM/Bicep templates

2. **Container Insights Add-on**
   - Deploy as Kubernetes add-on
   - Support for non-AKS clusters
   - Customizable configuration

### Example: Enabling Container Insights with Bicep

```bicep
@description('The name of the AKS cluster')
param aksClusterName string

@description('The location for the resources')
param location string = resourceGroup().location

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: '${aksClusterName}-workspace'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource aksCluster 'Microsoft.ContainerService/managedClusters@2021-10-01' = {
  name: aksClusterName
  location: location
  properties: {
    kubernetesVersion: '1.23.5'
    enableRBAC: true
    dnsPrefix: aksClusterName
    agentPoolProfiles: [
      {
        name: 'agentpool'
        count: 3
        vmSize: 'Standard_DS2_v2'
        osType: 'Linux'
        mode: 'System'
      }
    ]
    addonProfiles: {
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspace.id
        }
      }
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}
```

### Common Container Monitoring Queries

```kusto
// Cluster-wide CPU utilization
KubePodInventory
| where TimeGenerated >= ago(1h)
| project TimeGenerated, ClusterName, Namespace, Name, PodStatus
| join (Perf
    | where TimeGenerated >= ago(1h)
    | where ObjectName == 'K8SContainer'
    | where CounterName == 'cpuUsageNanoCores'
    | project TimeGenerated, PodName=Name, CounterValue, Computer)
    on $left.Name == $right.PodName
| summarize CPUUsageNanoCores = sum(CounterValue) by bin(TimeGenerated, 5m), ClusterName
| render timechart

// Container restart counts
KubePodInventory
| where TimeGenerated >= ago(1d)
| distinct ClusterName, Namespace, Name, ContainerName, ContainerRestartCount
| summarize MaxRestarts = max(ContainerRestartCount) by ClusterName, Namespace, Name, ContainerName
| where MaxRestarts > 0
| sort by MaxRestarts desc

// Pod status count
KubePodInventory
| where TimeGenerated >= ago(15m)
| distinct ClusterName, Name, PodStatus
| summarize count() by ClusterName, PodStatus
| render barchart
```

## Azure Monitor for VMs

### Capabilities

1. **VM Insights**
   - Performance monitoring
   - Dependency mapping
   - Health monitoring

2. **Data Collection**
   - Performance counters
   - Event logs and syslog
   - Inventory data
   - Change tracking

3. **Guest OS Monitoring**
   - OS performance metrics
   - Process monitoring
   - Service monitoring

### Deployment Methods

1. **Azure VM Extension**
   - Log Analytics agent
   - Dependency agent
   - Azure Monitor agent

2. **Azure Arc Integration**
   - Monitor non-Azure VMs
   - Consistent management
   - Hybrid environments

### Example: Enabling VM Insights with Bicep

```bicep
@description('The name of the virtual machine')
param vmName string

@description('The location for the resources')
param location string = resourceGroup().location

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: '${vmName}-workspace'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v3'
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    osProfile: {
      computerName: vmName
      adminUsername: 'azureadmin'
      adminPassword: 'P@ssw0rd1234!'
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
  }
}

resource monitoringAgent 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = {
  parent: virtualMachine
  name: 'MMAExtension'
  location: location
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'MicrosoftMonitoringAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: reference(logAnalyticsWorkspace.id, '2021-06-01').customerId
    }
    protectedSettings: {
      workspaceKey: listKeys(logAnalyticsWorkspace.id, '2021-06-01').primarySharedKey
    }
  }
}

resource dependencyAgent 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = {
  parent: virtualMachine
  name: 'DependencyAgentLinux'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitoring.DependencyAgent'
    type: 'DependencyAgentLinux'
    typeHandlerVersion: '9.5'
    autoUpgradeMinorVersion: true
  }
  dependsOn: [
    monitoringAgent
  ]
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2021-05-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${virtualNetwork.id}/subnets/default'
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: '${vmName}-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
    ]
  }
}
```

### Common VM Monitoring Queries

```kusto
// CPU utilization by VM
Perf
| where TimeGenerated >= ago(1h)
| where ObjectName == "Processor" and CounterName == "% Processor Time" and InstanceName == "_Total"
| summarize avg(CounterValue) by Computer, bin(TimeGenerated, 5m)
| render timechart

// Memory usage by VM
Perf
| where TimeGenerated >= ago(1h)
| where ObjectName == "Memory" and CounterName == "% Committed Bytes In Use"
| summarize avg(CounterValue) by Computer, bin(TimeGenerated, 5m)
| render timechart

// Disk space utilization
Perf
| where TimeGenerated >= ago(1d)
| where ObjectName == "LogicalDisk" and CounterName == "% Free Space"
| summarize min(CounterValue) by Computer, InstanceName
| where min_CounterValue < 20
| sort by min_CounterValue asc
```

## Azure Monitor for Databases

### Supported Database Services

1. **Azure SQL Database**
   - Query performance insights
   - Intelligent performance features
   - Resource utilization monitoring

2. **Azure Cosmos DB**
   - Request unit monitoring
   - Throughput utilization
   - Storage monitoring

3. **Azure Database for MySQL/PostgreSQL**
   - Server metrics
   - Query performance
   - Storage and connections

### Monitoring Capabilities

1. **Performance Monitoring**
   - Query execution statistics
   - Resource utilization
   - Connection metrics

2. **Availability Monitoring**
   - Uptime tracking
   - Failover events
   - Replication lag

3. **Security and Compliance**
   - Audit logging
   - Firewall rule changes
   - Authentication attempts

### Example: Azure SQL Database Monitoring with Bicep

```bicep
@description('The name of the SQL server')
param sqlServerName string

@description('The name of the SQL database')
param sqlDatabaseName string

@description('The location for the resources')
param location string = resourceGroup().location

@description('The Log Analytics workspace resource ID')
param logAnalyticsWorkspaceId string

resource sqlServer 'Microsoft.Sql/servers@2021-08-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: 'sqladmin'
    administratorLoginPassword: 'P@ssw0rd1234!'
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2021-08-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
  }
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${sqlDatabaseName}-diagnostics'
  scope: sqlDatabase
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'SQLInsights'
        enabled: true
      }
      {
        category: 'AutomaticTuning'
        enabled: true
      }
      {
        category: 'QueryStoreRuntimeStatistics'
        enabled: true
      }
      {
        category: 'QueryStoreWaitStatistics'
        enabled: true
      }
      {
        category: 'Errors'
        enabled: true
      }
      {
        category: 'DatabaseWaitStatistics'
        enabled: true
      }
      {
        category: 'Timeouts'
        enabled: true
      }
      {
        category: 'Blocks'
        enabled: true
      }
      {
        category: 'Deadlocks'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'Basic'
        enabled: true
      }
      {
        category: 'InstanceAndAppAdvanced'
        enabled: true
      }
      {
        category: 'WorkloadManagement'
        enabled: true
      }
    ]
  }
}
```

### Common Database Monitoring Queries

```kusto
// SQL Database DTU utilization
AzureMetrics
| where TimeGenerated >= ago(1h)
| where ResourceProvider == "MICROSOFT.SQL"
| where MetricName == "dtu_consumption_percent"
| summarize avg(Average) by bin(TimeGenerated, 5m), Resource
| render timechart

// SQL Database storage utilization
AzureMetrics
| where TimeGenerated >= ago(1d)
| where ResourceProvider == "MICROSOFT.SQL"
| where MetricName == "storage_percent"
| summarize max(Maximum) by Resource
| sort by max_Maximum desc

// Cosmos DB RU consumption
AzureMetrics
| where TimeGenerated >= ago(1h)
| where ResourceProvider == "MICROSOFT.DOCUMENTDB"
| where MetricName == "NormalizedRUConsumption"
| summarize max(Maximum) by bin(TimeGenerated, 5m), Resource
| render timechart
```

## Integration with DevOps Processes

### Monitoring in CI/CD Pipelines

1. **Deployment Monitoring**
   - Track deployment success rates
   - Monitor post-deployment performance
   - Automated rollbacks based on metrics

2. **Release Gates**
   - Use metrics and logs as deployment gates
   - Ensure service health before promotion
   - Verify application performance

3. **Pipeline Analytics**
   - Build and release success rates
   - Pipeline duration and efficiency
   - Test coverage and results

### Example: Azure DevOps Release Gate

```yaml
# azure-pipelines.yml
stages:
- stage: Deploy
  jobs:
  - deployment: DeployWebApp
    environment: 
      name: Production
      resourceType: VirtualMachine
    strategy:
      runOnce:
        deploy:
          steps:
          - script: echo "Deploying application..."

- stage: PostDeploymentChecks
  dependsOn: Deploy
  jobs:
  - job: MonitorApplication
    pool:
      vmImage: 'ubuntu-latest'
    steps:
    - task: AzureCLI@2
      inputs:
        azureSubscription: 'Production'
        scriptType: 'bash'
        scriptLocation: 'inlineScript'
        inlineScript: |
          # Get metrics from the last 15 minutes
          ALERT_COUNT=$(az monitor metrics alert list \
            --resource-group myResourceGroup \
            --query "[?properties.windowSize=='PT15M' && properties.evaluationFrequency=='PT5M' && properties.severity==0].properties.status" \
            --output tsv)
          
          # Check if any alerts are active
          if [ "$ALERT_COUNT" -gt 0 ]; then
            echo "##vso[task.logissue type=error]Critical alerts detected during deployment window!"
            echo "##vso[task.complete result=Failed;]"
          else
            echo "No critical alerts detected. Deployment verification passed."
          fi
```

### Example: Azure Function for Automated Remediation

```csharp
using System;
using System.Threading.Tasks;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Microsoft.Azure.Management.Fluent;
using Microsoft.Azure.Management.ResourceManager.Fluent;
using Microsoft.Azure.Management.ResourceManager.Fluent.Authentication;

public static class AutoRemediation
{
    [FunctionName("ScaleOutWebApp")]
    public static async Task Run(
        [HttpTrigger(AuthorizationLevel.Function, "post", Route = null)] HttpRequest req,
        ILogger log)
    {
        log.LogInformation("C# HTTP trigger function processed a request for auto-remediation.");

        // Get credentials from managed identity
        var credentials = new AzureCredentials(
            new MSILoginInformation(MSIResourceType.AppService),
            AzureEnvironment.AzureGlobalCloud);

        // Initialize Azure Management client
        var azure = Azure.Configure()
            .WithLogLevel(HttpLoggingDelegatingHandler.Level.Basic)
            .Authenticate(credentials)
            .WithDefaultSubscription();

        // Scale out the app service plan
        var resourceGroup = req.Query["resourceGroup"];
        var appServicePlanName = req.Query["appServicePlan"];
        
        var appServicePlan = await azure.AppServices.AppServicePlans
            .GetByResourceGroupAsync(resourceGroup, appServicePlanName);
            
        await appServicePlan.Update()
            .WithCapacity(appServicePlan.Capacity + 1)
            .ApplyAsync();
            
        log.LogInformation($"Scaled out {appServicePlanName} to {appServicePlan.Capacity + 1} instances");
    }
}
```

## Hands-on Lab: Setting up End-to-End Monitoring

This hands-on lab guides you through setting up a comprehensive monitoring solution for a web application hosted on Azure.

### Prerequisites

1. Azure subscription
2. Azure DevOps account
3. Sample web application (preferably .NET Core or Node.js)
4. Azure CLI installed

### Step 1: Create Base Resources

1. Create a resource group:

```bash
az group create --name monitoring-lab-rg --location eastus
```

2. Create a Log Analytics workspace:

```bash
az monitor log-analytics workspace create \
  --resource-group monitoring-lab-rg \
  --workspace-name monitoring-lab-workspace \
  --location eastus \
  --sku PerGB2018
```

3. Create an Application Insights resource:

```bash
az monitor app-insights component create \
  --app monitoring-lab-appinsights \
  --location eastus \
  --resource-group monitoring-lab-rg \
  --workspace "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/monitoring-lab-rg/providers/Microsoft.OperationalInsights/workspaces/monitoring-lab-workspace"
```

### Step 2: Deploy Application Infrastructure

1. Create an App Service Plan:

```bash
az appservice plan create \
  --name monitoring-lab-plan \
  --resource-group monitoring-lab-rg \
  --location eastus \
  --sku S1
```

2. Create a Web App:

```bash
az webapp create \
  --name monitoring-lab-webapp \
  --resource-group monitoring-lab-rg \
  --plan monitoring-lab-plan
```

3. Enable App Service logging:

```bash
az webapp config appsettings set \
  --resource-group monitoring-lab-rg \
  --name monitoring-lab-webapp \
  --settings \
    APPINSIGHTS_INSTRUMENTATIONKEY=$(az monitor app-insights component show --app monitoring-lab-appinsights --resource-group monitoring-lab-rg --query instrumentationKey -o tsv) \
    APPLICATIONINSIGHTS_CONNECTION_STRING="InstrumentationKey=$(az monitor app-insights component show --app monitoring-lab-appinsights --resource-group monitoring-lab-rg --query instrumentationKey -o tsv)" \
    ApplicationInsightsAgent_EXTENSION_VERSION=~2
```

4. Enable diagnostic settings:

```bash
az monitor diagnostic-settings create \
  --name "webapp-diagnostics" \
  --resource "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/monitoring-lab-rg/providers/Microsoft.Web/sites/monitoring-lab-webapp" \
  --workspace "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/monitoring-lab-rg/providers/Microsoft.OperationalInsights/workspaces/monitoring-lab-workspace" \
  --logs '[{"category": "AppServiceHTTPLogs", "enabled": true}, {"category": "AppServiceConsoleLogs", "enabled": true}, {"category": "AppServiceAppLogs", "enabled": true}]' \
  --metrics '[{"category": "AllMetrics", "enabled": true}]'
```

### Step 3: Instrument Your Application

1. For .NET Core applications, add the Application Insights SDK:

```bash
dotnet add package Microsoft.ApplicationInsights.AspNetCore
```

2. Update Program.cs:

```csharp
var builder = WebApplication.CreateBuilder(args);

// Add Application Insights
builder.Services.AddApplicationInsightsTelemetry();

// Add services to the container
builder.Services.AddControllers();

var app = builder.Build();

// Configure middleware
app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

app.Run();
```

3. Deploy your application to the Web App:

```bash
cd /path/to/your/app
az webapp deployment source config-zip -g monitoring-lab-rg -n monitoring-lab-webapp --src ./publish.zip
```

### Step 4: Create Monitoring Alerts

1. Create an action group:

```bash
az monitor action-group create \
  --name monitoring-lab-actiongroup \
  --resource-group monitoring-lab-rg \
  --action email admin monitoring-admin@example.com \
  --short-name MonLab
```

2. Create a metric alert:

```bash
az monitor metrics alert create \
  --name "High CPU Alert" \
  --resource-group monitoring-lab-rg \
  --scopes "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/monitoring-lab-rg/providers/Microsoft.Web/sites/monitoring-lab-webapp" \
  --condition "avg Percentage CPU > 80" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --severity 2 \
  --action "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/monitoring-lab-rg/providers/Microsoft.Insights/actionGroups/monitoring-lab-actiongroup"
```

3. Create a log alert:

```bash
az monitor scheduled-query create \
  --name "HTTP Error Alert" \
  --resource-group monitoring-lab-rg \
  --scopes "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/monitoring-lab-rg/providers/Microsoft.OperationalInsights/workspaces/monitoring-lab-workspace" \
  --severity 2 \
  --evaluation-frequency 5m \
  --window-size 15m \
  --action-group "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/monitoring-lab-rg/providers/Microsoft.Insights/actionGroups/monitoring-lab-actiongroup" \
  --query "AppServiceHTTPLogs | where ScStatus >= 500 | summarize count() by bin(TimeGenerated, 5m) | where count_ > 5"
```

### Step 5: Create Azure Monitor Workbook

1. Create a workbook template file named `workbook.json`:

```json
{
  "version": "Notebook/1.0",
  "items": [
    {
      "type": 1,
      "content": {
        "json": "# Web Application Monitoring Dashboard\n\nThis dashboard provides an overview of your web application's performance and health."
      },
      "name": "Title"
    },
    {
      "type": 9,
      "content": {
        "version": "KqlParameterItem/1.0",
        "parameters": [
          {
            "id": "d6da4785-fa41-4807-a19a-0f6e53eb76f7",
            "version": "KqlParameterItem/1.0",
            "name": "TimeRange",
            "type": 4,
            "isRequired": true,
            "value": {
              "durationMs": 86400000
            },
            "typeSettings": {
              "selectableValues": [
                {
                  "durationMs": 900000
                },
                {
                  "durationMs": 1800000
                },
                {
                  "durationMs": 3600000
                },
                {
                  "durationMs": 14400000
                },
                {
                  "durationMs": 43200000
                },
                {
                  "durationMs": 86400000
                },
                {
                  "durationMs": 172800000
                },
                {
                  "durationMs": 259200000
                },
                {
                  "durationMs": 604800000
                }
              ],
              "allowCustom": true
            }
          }
        ],
        "style": "pills",
        "queryType": 0,
        "resourceType": "microsoft.insights/components"
      },
      "name": "Parameters"
    },
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "AppRequests\n| where TimeGenerated >= ago({TimeRange})\n| summarize RequestCount = count(), FailedCount = countif(Success == false), AvgDuration = avg(DurationMs) by bin(TimeGenerated, {TimeRange:grain})\n| extend FailureRate = 100.0 * FailedCount / RequestCount\n| project TimeGenerated, RequestCount, AvgDuration, FailureRate",
        "size": 0,
        "aggregation": 3,
        "title": "Request Overview",
        "timeContext": {
          "durationMs": 86400000
        },
        "queryType": 0,
        "resourceType": "microsoft.insights/components",
        "visualization": "linechart",
        "graphSettings": {
          "type": 0,
          "topContent": {
            "columnMatch": "RequestCount",
            "formatter": 1
          },
          "centerContent": {
            "columnMatch": "AvgDuration",
            "formatter": 1,
            "numberFormat": {
              "unit": 23,
              "options": {
                "style": "decimal",
                "maximumFractionDigits": 2
              }
            }
          },
          "bottomContent": {
            "columnMatch": "FailureRate",
            "formatter": 1,
            "numberFormat": {
              "unit": 1,
              "options": {
                "style": "decimal",
                "maximumFractionDigits": 2
              }
            }
          }
        }
      },
      "name": "RequestOverview"
    },
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "AppRequests\n| where TimeGenerated >= ago({TimeRange})\n| summarize RequestCount = count(), FailedCount = countif(Success == false), AvgDuration = avg(DurationMs), p95Duration = percentile(DurationMs, 95) by OperationName\n| extend FailureRate = 100.0 * FailedCount / RequestCount\n| sort by RequestCount desc",
        "size": 0,
        "title": "Operations Performance",
        "timeContext": {
          "durationMs": 86400000
        },
        "queryType": 0,
        "resourceType": "microsoft.insights/components"
      },
      "name": "OperationsPerformance"
    },
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "AppExceptions\n| where TimeGenerated >= ago({TimeRange})\n| summarize ExceptionCount = count() by ProblemId, Type, Method, outerMessage\n| top 10 by ExceptionCount desc",
        "size": 0,
        "title": "Top Exceptions",
        "timeContext": {
          "durationMs": 86400000
        },
        "queryType": 0,
        "resourceType": "microsoft.insights/components"
      },
      "name": "TopExceptions"
    },
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "AppDependencies\n| where TimeGenerated >= ago({TimeRange})\n| summarize CallCount = count(), FailedCount = countif(Success == false), AvgDuration = avg(DurationMs) by Type, Target, Name\n| extend FailureRate = 100.0 * FailedCount / CallCount\n| sort by CallCount desc",
        "size": 0,
        "title": "Dependencies Performance",
        "timeContext": {
          "durationMs": 86400000
        },
        "queryType": 0,
        "resourceType": "microsoft.insights/components"
      },
      "name": "DependenciesPerformance"
    }
  ],
  "fallbackResourceIds": [
    "/subscriptions/your-subscription-id/resourceGroups/monitoring-lab-rg/providers/Microsoft.Insights/components/monitoring-lab-appinsights"
  ],
  "$schema": "https://github.com/Microsoft/Application-Insights-Workbooks/blob/master/schema/workbook.json"
}
```

2. Deploy the workbook:

```bash
az portal workbook create \
  --resource-group monitoring-lab-rg \
  --location eastus \
  --category workbook \
  --display-name "Web Application Dashboard" \
  --source-id "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/monitoring-lab-rg/providers/Microsoft.Insights/components/monitoring-lab-appinsights" \
  --serialized-data @workbook.json
```

### Step 6: Set Up Availability Tests

1. Create an availability test for your web app:

```bash
az monitor app-insights web-test create \
  --resource-group monitoring-lab-rg \
  --app monitoring-lab-appinsights \
  --location eastus \
  --name "monitoring-lab-availability-test" \
  --web-test-kind "ping" \
  --frequency 300 \
  --retry-enabled true \
  --locations eastus westus2 \
  --geo-locations "us-ca-sjc" "us-tx-sn1" "us-il-ch1" \
  --enabled true \
  --tags "WebTest:monitoring-lab-webapp" \
  --test-definition "
<WebTest Name=\"WebTest\" Enabled=\"True\" Timeout=\"120\" xmlns=\"http://microsoft.com/schemas/VisualStudio/TeamTest/2010\">
  <Items>
    <Request Method=\"GET\" Version=\"1.1\" Url=\"https://monitoring-lab-webapp.azurewebsites.net/\" ThinkTime=\"0\" />
  </Items>
  <ValidationRules>
    <ValidationRule Classname=\"Microsoft.VisualStudio.TestTools.WebTesting.Rules.ValidationRuleFindText, Microsoft.VisualStudio.QualityTools.WebTestFramework, Version=10.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a\" DisplayName=\"Find Text\" Description=\"Verifies the specified text exists in the response.\" Level=\"High\" ExecutionOrder=\"BeforeDependents\">
      <RuleParameters>
        <RuleParameter Name=\"FindText\" Value=\"Welcome\" />
        <RuleParameter Name=\"IgnoreCase\" Value=\"True\" />
        <RuleParameter Name=\"UseRegularExpression\" Value=\"False\" />
      </RuleParameters>
    </ValidationRule>
  </ValidationRules>
</WebTest>"
```

### Step 7: Create a Logic App for Automated Remediation

1. Create a Logic App for auto-scaling:

```bash
az logic workflow create \
  --resource-group monitoring-lab-rg \
  --location eastus \
  --name "monitoring-lab-autoscale" \
  --definition '{
    "$schema": "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {},
    "triggers": {
      "http_trigger": {
        "type": "Request",
        "kind": "Http",
        "inputs": {
          "schema": {
            "type": "object",
            "properties": {
              "alertContext": {
                "type": "object",
                "properties": {}
              }
            }
          }
        }
      }
    },
    "actions": {
      "Scale_Out_App_Service": {
        "type": "ApiConnection",
        "inputs": {
          "host": {
            "connection": {
              "name": "@parameters(\'$connections\')[\'azurerm\'][\'connectionId\']"
            }
          },
          "method": "put",
          "path": "/subscriptions/@{encodeURIComponent(\'subscriptionId\')}/resourcegroups/@{encodeURIComponent(\'monitoring-lab-rg\')}/providers/Microsoft.Web/serverfarms/@{encodeURIComponent(\'monitoring-lab-plan\')}",
          "queries": {
            "x-ms-api-version": "2018-02-01"
          },
          "body": {
            "sku": {
              "name": "S1",
              "tier": "Standard",
              "size": "S1",
              "family": "S",
              "capacity": 2
            },
            "location": "eastus"
          }
        }
      },
      "Send_Email_Notification": {
        "type": "ApiConnection",
        "inputs": {
          "host": {
            "connection": {
              "name": "@parameters(\'$connections\')[\'office365\'][\'connectionId\']"
            }
          },
          "method": "post",
          "path": "/v2/Mail",
          "body": {
            "To": "admin@example.com",
            "Subject": "Auto-Scaling Triggered for monitoring-lab-webapp",
            "Body": "<p>High CPU detected. App Service Plan has been scaled out to 2 instances.</p>",
            "Importance": "High"
          }
        }
      }
    },
    "outputs": {}
  }'
```

### Step 8: Test the Monitoring Setup

1. Generate some load against your web application:

```bash
# Using Apache Bench (ab)
ab -n 1000 -c 10 https://monitoring-lab-webapp.azurewebsites.net/
```

2. Verify metrics and logs in Azure Portal:
   - Go to Application Insights > Metrics
   - Go to Log Analytics > Logs
   - View your custom Workbook

3. Test an alert by simulating errors:
   - Create an endpoint that generates 500 errors
   - Use Apache Bench to trigger it repeatedly

4. Review the entire monitoring solution:
   - Application Insights data
   - Log Analytics queries
   - Alerts configuration
   - Workbook visualizations
   - Auto-remediation Logic App

This hands-on lab provides a comprehensive setup for monitoring an Azure web application, covering all aspects from metrics and logs to alerts and automated remediation.
