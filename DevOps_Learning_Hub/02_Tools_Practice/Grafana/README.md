# Grafana - Data Visualization and Dashboards

## Overview
Grafana is an open-source analytics and interactive visualization web application. It provides charts, graphs, and alerts when connected to supported data sources like Prometheus, InfluxDB, Elasticsearch, and many others.

## Learning Objectives
- Master Grafana installation and configuration
- Create powerful dashboards and visualizations
- Implement alerting and notifications
- Manage users, teams, and permissions
- Integrate with multiple data sources
- Implement advanced dashboard patterns
- Scale Grafana for enterprise environments

## Prerequisites
- Basic understanding of monitoring concepts
- Familiarity with time series data
- Knowledge of at least one data source (Prometheus recommended)
- Basic web development knowledge (HTML, CSS, JavaScript)
- Docker and Kubernetes knowledge

---

## Lab 1: Grafana Installation and Setup

### Objective
Install Grafana and configure basic settings.

### Steps

1. **Docker Installation**
```bash
# Run Grafana with Docker
docker run -d \
  --name grafana \
  -p 3000:3000 \
  -e "GF_SECURITY_ADMIN_PASSWORD=admin123" \
  -v grafana-storage:/var/lib/grafana \
  grafana/grafana:latest

# Access Grafana UI
curl http://localhost:3000
# Default login: admin/admin123
```

2. **Configuration File Setup**
```ini
# grafana.ini
[server]
protocol = http
http_addr = 0.0.0.0
http_port = 3000
domain = grafana.company.com
root_url = %(protocol)s://%(domain)s:%(http_port)s/

[database]
type = postgres
host = postgres:5432
name = grafana
user = grafana
password = grafana_password

[security]
admin_user = admin
admin_password = $__env{GF_SECURITY_ADMIN_PASSWORD}
secret_key = $__env{GF_SECURITY_SECRET_KEY}
disable_gravatar = true
cookie_secure = true
cookie_samesite = strict

[auth]
disable_login_form = false
disable_signout_menu = false
oauth_auto_login = false

[auth.anonymous]
enabled = false

[smtp]
enabled = true
host = smtp.company.com:587
user = grafana@company.com
password = $__env{GF_SMTP_PASSWORD}
from_address = grafana@company.com
from_name = Grafana

[alerting]
enabled = true
execute_alerts = true

[metrics]
enabled = true
```

3. **Environment Variables**
```bash
# grafana.env
GF_SECURITY_ADMIN_PASSWORD=secure_admin_password
GF_SECURITY_SECRET_KEY=your_secret_key_here
GF_SMTP_PASSWORD=smtp_password
GF_DATABASE_PASSWORD=db_password
GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource,grafana-piechart-panel
```

4. **Kubernetes Deployment**
```yaml
# grafana-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:latest
        ports:
        - containerPort: 3000
        env:
        - name: GF_SECURITY_ADMIN_PASSWORD
          valueFrom:
            secretKeyRef:
              name: grafana-secret
              key: admin-password
        volumeMounts:
        - name: grafana-storage
          mountPath: /var/lib/grafana
        - name: grafana-config
          mountPath: /etc/grafana/grafana.ini
          subPath: grafana.ini
        resources:
          requests:
            memory: 256Mi
            cpu: 100m
          limits:
            memory: 512Mi
            cpu: 500m
      volumes:
      - name: grafana-storage
        persistentVolumeClaim:
          claimName: grafana-pvc
      - name: grafana-config
        configMap:
          name: grafana-config

---
apiVersion: v1
kind: Service
metadata:
  name: grafana
  namespace: monitoring
spec:
  selector:
    app: grafana
  ports:
  - port: 3000
    targetPort: 3000
  type: LoadBalancer
```

### Exercise
- Install Grafana using your preferred method
- Configure basic settings and security
- Set up persistent storage

---

## Lab 2: Data Source Configuration

### Objective
Configure various data sources for comprehensive monitoring.

### Steps

1. **Prometheus Data Source**
```yaml
# prometheus-datasource.yaml
apiVersion: 1
datasources:
- name: Prometheus
  type: prometheus
  access: proxy
  url: http://prometheus:9090
  isDefault: true
  basicAuth: false
  jsonData:
    httpMethod: POST
    manageAlerts: true
    prometheusType: Prometheus
    prometheusVersion: 2.40.0
    cacheLevel: 'High'
    incrementalQueries: true
    incrementalQueryOverlapWindow: 10m
    exemplarTraceIdDestinations:
    - name: traceID
      datasourceUid: jaeger-uid
      urlDisplayLabel: "View Trace"
  secureJsonData:
    httpHeaderValue1: 'Bearer your-api-token'
```

2. **InfluxDB Data Source**
```yaml
# influxdb-datasource.yaml
apiVersion: 1
datasources:
- name: InfluxDB
  type: influxdb
  access: proxy
  url: http://influxdb:8086
  database: monitoring
  user: grafana
  secureJsonData:
    password: influxdb_password
  jsonData:
    httpMode: GET
    keepCookies: []
```

3. **Elasticsearch Data Source**
```yaml
# elasticsearch-datasource.yaml
apiVersion: 1
datasources:
- name: Elasticsearch
  type: elasticsearch
  access: proxy
  url: http://elasticsearch:9200
  database: logstash-*
  jsonData:
    index: logstash-*
    timeField: "@timestamp"
    esVersion: "7.10.0"
    interval: Daily
    maxConcurrentShardRequests: 5
    logMessageField: message
    logLevelField: level
  secureJsonData:
    basicAuthPassword: elastic_password
```

4. **CloudWatch Data Source**
```yaml
# cloudwatch-datasource.yaml
apiVersion: 1
datasources:
- name: CloudWatch
  type: cloudwatch
  access: proxy
  jsonData:
    authType: keys
    defaultRegion: us-west-2
    customMetricsNamespaces: AWS/ApplicationELB,AWS/ELB,CWAgent
  secureJsonData:
    accessKey: your-access-key
    secretKey: your-secret-key
```

5. **Mixed Data Source Queries**
```json
{
  "datasource": {
    "type": "mixed",
    "uid": "-- Mixed --"
  },
  "targets": [
    {
      "datasource": {
        "type": "prometheus",
        "uid": "prometheus-uid"
      },
      "expr": "up",
      "legendFormat": "Prometheus - {{instance}}"
    },
    {
      "datasource": {
        "type": "influxdb",
        "uid": "influxdb-uid"
      },
      "query": "SELECT mean(\"value\") FROM \"cpu_usage\" WHERE $timeFilter GROUP BY time($__interval) fill(null)"
    }
  ]
}
```

### Exercise
- Configure multiple data sources
- Test connectivity and data retrieval
- Set up cross-data source queries

---

## Lab 3: Building Comprehensive Dashboards

### Objective
Create effective dashboards for monitoring different aspects of your infrastructure.

### Steps

1. **System Overview Dashboard**
```json
{
  "dashboard": {
    "id": null,
    "title": "System Overview",
    "tags": ["infrastructure", "overview"],
    "timezone": "browser",
    "refresh": "30s",
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "panels": [
      {
        "id": 1,
        "title": "System Load",
        "type": "stat",
        "targets": [
          {
            "expr": "node_load1",
            "legendFormat": "{{instance}}"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "thresholds": {
              "steps": [
                {"color": "green", "value": null},
                {"color": "yellow", "value": 0.8},
                {"color": "red", "value": 1.0}
              ]
            },
            "unit": "short"
          }
        },
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0}
      },
      {
        "id": 2,
        "title": "CPU Usage",
        "type": "timeseries",
        "targets": [
          {
            "expr": "100 - (avg(rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
            "legendFormat": "CPU Usage %"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "min": 0,
            "max": 100,
            "unit": "percent"
          }
        },
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0}
      }
    ]
  }
}
```

2. **Application Performance Dashboard**
```json
{
  "dashboard": {
    "title": "Application Performance",
    "panels": [
      {
        "id": 1,
        "title": "Request Rate",
        "type": "timeseries",
        "targets": [
          {
            "expr": "sum(rate(http_requests_total[5m])) by (method, status)",
            "legendFormat": "{{method}} - {{status}}"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "reqps"
          }
        }
      },
      {
        "id": 2,
        "title": "Response Time Distribution",
        "type": "heatmap",
        "targets": [
          {
            "expr": "sum(rate(http_request_duration_seconds_bucket[5m])) by (le)",
            "format": "heatmap",
            "legendFormat": "{{le}}"
          }
        ],
        "heatmap": {
          "xBucketSize": null,
          "yBucketSize": null,
          "yBucketBound": "auto"
        }
      },
      {
        "id": 3,
        "title": "Error Rate",
        "type": "stat",
        "targets": [
          {
            "expr": "sum(rate(http_requests_total{status=~\"5..\"}[5m])) / sum(rate(http_requests_total[5m])) * 100",
            "legendFormat": "Error Rate"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "thresholds": {
              "steps": [
                {"color": "green", "value": null},
                {"color": "yellow", "value": 1},
                {"color": "red", "value": 5}
              ]
            },
            "unit": "percent"
          }
        }
      }
    ]
  }
}
```

3. **Business Metrics Dashboard**
```json
{
  "dashboard": {
    "title": "Business Metrics",
    "panels": [
      {
        "id": 1,
        "title": "Active Users",
        "type": "timeseries",
        "targets": [
          {
            "expr": "active_users_total",
            "legendFormat": "Active Users"
          }
        ]
      },
      {
        "id": 2,
        "title": "Revenue per Hour",
        "type": "timeseries",
        "targets": [
          {
            "expr": "increase(revenue_total[1h])",
            "legendFormat": "Revenue/Hour"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "currencyUSD"
          }
        }
      },
      {
        "id": 3,
        "title": "Conversion Rate",
        "type": "gauge",
        "targets": [
          {
            "expr": "rate(conversions_total[5m]) / rate(page_views_total[5m]) * 100",
            "legendFormat": "Conversion Rate"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "min": 0,
            "max": 10,
            "unit": "percent",
            "thresholds": {
              "steps": [
                {"color": "red", "value": 0},
                {"color": "yellow", "value": 2},
                {"color": "green", "value": 5}
              ]
            }
          }
        }
      }
    ]
  }
}
```

4. **Custom Panel with HTML**
```javascript
// Custom HTML Panel
<div style="padding: 20px; text-align: center;">
  <h2>System Status</h2>
  <div id="status-indicator"></div>
  <script>
    const data = ${__data};
    const latestValue = data.series[0].fields[1].values.buffer[data.series[0].length - 1];
    const statusDiv = document.getElementById('status-indicator');
    
    if (latestValue > 0.95) {
      statusDiv.innerHTML = '<div style="color: green; font-size: 24px;">✅ All Systems Operational</div>';
    } else if (latestValue > 0.8) {
      statusDiv.innerHTML = '<div style="color: orange; font-size: 24px;">⚠️ Minor Issues Detected</div>';
    } else {
      statusDiv.innerHTML = '<div style="color: red; font-size: 24px;">🚨 Critical Issues</div>';
    }
  </script>
</div>
```

### Exercise
- Create dashboards for different audiences (technical, business)
- Implement proper dashboard organization and navigation
- Use template variables for dynamic dashboards

---

## Lab 4: Advanced Visualizations and Panel Types

### Objective
Master different visualization types and advanced panel configurations.

### Steps

1. **Time Series Visualizations**
```json
{
  "panel": {
    "type": "timeseries",
    "title": "CPU Usage with Predictions",
    "targets": [
      {
        "expr": "100 - (avg(rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
        "legendFormat": "Current CPU Usage"
      },
      {
        "expr": "predict_linear(node_cpu_seconds_total{mode=\"idle\"}[1h], 3600)",
        "legendFormat": "Predicted CPU (1h)"
      }
    ],
    "fieldConfig": {
      "defaults": {
        "custom": {
          "drawStyle": "line",
          "lineInterpolation": "linear",
          "barAlignment": 0,
          "lineWidth": 2,
          "fillOpacity": 10,
          "gradientMode": "opacity",
          "spanNulls": false,
          "insertNulls": false,
          "showPoints": "never",
          "pointSize": 5,
          "stacking": {
            "mode": "none",
            "group": "A"
          },
          "axisPlacement": "auto",
          "axisLabel": "",
          "scaleDistribution": {
            "type": "linear"
          },
          "hideFrom": {
            "legend": false,
            "tooltip": false,
            "vis": false
          },
          "thresholdsStyle": {
            "mode": "off"
          }
        }
      }
    }
  }
}
```

2. **Heatmap for Latency Distribution**
```json
{
  "panel": {
    "type": "heatmap",
    "title": "Response Time Heatmap",
    "targets": [
      {
        "expr": "sum(rate(http_request_duration_seconds_bucket[5m])) by (le)",
        "format": "heatmap",
        "legendFormat": "{{le}}"
      }
    ],
    "heatmap": {
      "xAxis": {
        "show": true
      },
      "yAxis": {
        "show": true,
        "logBase": 1,
        "min": null,
        "max": null
      },
      "colorScale": "sqrt",
      "colorScheme": "interpolateOranges",
      "dataFormat": "tsbuckets",
      "highlightCards": true,
      "cardColor": "#b4ff00",
      "cardPadding": null,
      "cardRound": null,
      "xBucketSize": null,
      "yBucketSize": null,
      "yBucketBound": "auto"
    }
  }
}
```

3. **Pie Chart for Resource Distribution**
```json
{
  "panel": {
    "type": "piechart",
    "title": "Memory Usage by Process",
    "targets": [
      {
        "expr": "topk(5, node_memory_rss_bytes)",
        "legendFormat": "{{comm}}"
      }
    ],
    "options": {
      "reduceOptions": {
        "values": false,
        "calcs": ["lastNotNull"],
        "fields": ""
      },
      "pieType": "pie",
      "tooltip": {
        "mode": "single"
      },
      "legend": {
        "displayMode": "table",
        "placement": "right",
        "values": ["value", "percent"]
      },
      "displayLabels": []
    }
  }
}
```

4. **Geo Map Visualization**
```json
{
  "panel": {
    "type": "geomap",
    "title": "Global Request Distribution",
    "targets": [
      {
        "expr": "sum(rate(http_requests_total[5m])) by (country)",
        "legendFormat": "{{country}}"
      }
    ],
    "options": {
      "view": {
        "id": "zero",
        "lat": 0,
        "lon": 0,
        "zoom": 1
      },
      "controls": {
        "mouseWheelZoom": true,
        "showZoom": true,
        "showAttribution": true
      },
      "layers": [
        {
          "type": "markers",
          "config": {
            "size": {
              "field": "Value",
              "fixed": 5,
              "min": 2,
              "max": 15
            },
            "color": {
              "field": "Value",
              "fixed": "dark-green"
            },
            "fillOpacity": 0.8,
            "strokeWidth": 1,
            "strokeColor": {
              "fixed": "dark-green"
            }
          },
          "location": {
            "mode": "auto"
          }
        }
      ]
    }
  }
}
```

5. **Table with Conditional Formatting**
```json
{
  "panel": {
    "type": "table",
    "title": "Service Health Status",
    "targets": [
      {
        "expr": "up",
        "format": "table",
        "instant": true
      }
    ],
    "transformations": [
      {
        "id": "organize",
        "options": {
          "excludeByName": {
            "__name__": true,
            "Time": true
          },
          "indexByName": {},
          "renameByName": {
            "instance": "Instance",
            "job": "Service",
            "Value": "Status"
          }
        }
      }
    ],
    "fieldConfig": {
      "defaults": {
        "custom": {
          "displayMode": "color-background",
          "inspect": false
        },
        "mappings": [
          {
            "options": {
              "0": {
                "text": "DOWN",
                "color": "red"
              },
              "1": {
                "text": "UP",
                "color": "green"
              }
            },
            "type": "value"
          }
        ],
        "thresholds": {
          "steps": [
            {"color": "red", "value": null},
            {"color": "green", "value": 1}
          ]
        }
      }
    }
  }
}
```

### Exercise
- Create visualizations for different data types
- Implement conditional formatting and mappings
- Use transformations to reshape data

---

## Lab 5: Template Variables and Dynamic Dashboards

### Objective
Create dynamic dashboards using template variables and advanced features.

### Steps

1. **Query Variables**
```json
{
  "templating": {
    "list": [
      {
        "name": "datasource",
        "type": "datasource",
        "query": "prometheus",
        "current": {
          "value": "prometheus",
          "text": "Prometheus"
        }
      },
      {
        "name": "job",
        "type": "query",
        "datasource": "${datasource}",
        "query": "label_values(up, job)",
        "current": {
          "value": "All",
          "text": "All"
        },
        "includeAll": true,
        "allValue": ".*",
        "multi": true
      },
      {
        "name": "instance",
        "type": "query",
        "datasource": "${datasource}",
        "query": "label_values(up{job=~\"$job\"}, instance)",
        "current": {
          "value": "All",
          "text": "All"
        },
        "includeAll": true,
        "allValue": ".*",
        "multi": true,
        "refresh": 2
      }
    ]
  }
}
```

2. **Custom Variables**
```json
{
  "templating": {
    "list": [
      {
        "name": "environment",
        "type": "custom",
        "query": "production,staging,development",
        "current": {
          "value": "production",
          "text": "production"
        },
        "multi": false,
        "includeAll": false
      },
      {
        "name": "region",
        "type": "custom",
        "query": "us-west-2,us-east-1,eu-west-1",
        "current": {
          "value": "All",
          "text": "All"
        },
        "multi": true,
        "includeAll": true
      }
    ]
  }
}
```

3. **Advanced Variable Usage**
```json
{
  "panel": {
    "targets": [
      {
        "expr": "up{job=~\"$job\", instance=~\"$instance\"}",
        "legendFormat": "{{instance}} - {{job}}"
      },
      {
        "expr": "rate(http_requests_total{job=~\"$job\", instance=~\"$instance\", environment=\"$environment\"}[5m])",
        "legendFormat": "{{instance}} - Requests/sec"
      }
    ],
    "title": "Status for $job on $instance"
  }
}
```

4. **Conditional Panels**
```json
{
  "panel": {
    "title": "Database Metrics",
    "targets": [
      {
        "expr": "mysql_up{job=~\"$job\"}",
        "legendFormat": "MySQL Status"
      }
    ],
    "datasource": "${datasource}",
    "hide": "$job != 'mysql'"
  }
}
```

5. **Variable Chaining**
```json
{
  "templating": {
    "list": [
      {
        "name": "cluster",
        "type": "query",
        "query": "label_values(kube_node_info, cluster)",
        "refresh": 1
      },
      {
        "name": "namespace",
        "type": "query",
        "query": "label_values(kube_namespace_labels{cluster=\"$cluster\"}, namespace)",
        "refresh": 2
      },
      {
        "name": "pod",
        "type": "query",
        "query": "label_values(kube_pod_info{cluster=\"$cluster\", namespace=\"$namespace\"}, pod)",
        "refresh": 2
      }
    ]
  }
}
```

### Exercise
- Create hierarchical template variables
- Implement dashboard filtering and navigation
- Use variables for multi-tenant dashboards

---

## Lab 6: Alerting and Notifications

### Objective
Set up comprehensive alerting within Grafana.

### Steps

1. **Alert Rules Configuration**
```json
{
  "alert": {
    "conditions": [
      {
        "evaluator": {
          "params": [80],
          "type": "gt"
        },
        "operator": {
          "type": "and"
        },
        "query": {
          "params": ["A", "5m", "now"]
        },
        "reducer": {
          "params": [],
          "type": "avg"
        },
        "type": "query"
      }
    ],
    "executionErrorState": "alerting",
    "for": "5m",
    "frequency": "10s",
    "handler": 1,
    "name": "High CPU Usage Alert",
    "noDataState": "no_data",
    "notifications": [
      {
        "uid": "slack-notifications"
      },
      {
        "uid": "email-notifications"
      }
    ]
  }
}
```

2. **Notification Channels**
```json
{
  "notificationChannels": [
    {
      "name": "slack-alerts",
      "type": "slack",
      "settings": {
        "url": "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK",
        "channel": "#alerts",
        "username": "Grafana",
        "title": "{{ range .Alerts }}{{ .AlertName }}{{ end }}",
        "text": "{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}"
      }
    },
    {
      "name": "email-alerts",
      "type": "email",
      "settings": {
        "addresses": "oncall@company.com;admin@company.com",
        "subject": "Grafana Alert: {{ range .Alerts }}{{ .AlertName }}{{ end }}",
        "body": "{{ range .Alerts }}{{ .Annotations.description }}{{ end }}"
      }
    },
    {
      "name": "webhook-alerts",
      "type": "webhook",
      "settings": {
        "url": "https://api.company.com/alerts",
        "httpMethod": "POST",
        "maxAlerts": 0
      }
    }
  ]
}
```

3. **Alert Rule Templates**
```json
{
  "alertRuleTemplates": [
    {
      "name": "Service Down Alert",
      "condition": "up == 0",
      "for": "1m",
      "severity": "critical",
      "annotations": {
        "summary": "Service {{ $labels.job }} is down",
        "description": "Service {{ $labels.job }} on {{ $labels.instance }} has been down for more than 1 minute"
      }
    },
    {
      "name": "High Memory Usage",
      "condition": "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85",
      "for": "5m",
      "severity": "warning",
      "annotations": {
        "summary": "High memory usage on {{ $labels.instance }}",
        "description": "Memory usage is above 85% for more than 5 minutes"
      }
    },
    {
      "name": "Disk Space Low",
      "condition": "(1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes)) * 100 > 90",
      "for": "2m",
      "severity": "critical",
      "annotations": {
        "summary": "Disk space low on {{ $labels.instance }}",
        "description": "Disk usage is above 90% on filesystem {{ $labels.mountpoint }}"
      }
    }
  ]
}
```

4. **PagerDuty Integration**
```json
{
  "notificationChannel": {
    "name": "pagerduty-critical",
    "type": "pagerduty",
    "settings": {
      "integrationKey": "your-pagerduty-integration-key",
      "severity": "critical",
      "autoResolve": true,
      "messageInDetails": false
    }
  }
}
```

### Exercise
- Create alert rules for different severity levels
- Set up multiple notification channels
- Test alert notifications and escalation

---

## Lab 7: User Management and Security

### Objective
Implement user management, authentication, and authorization.

### Steps

1. **LDAP Authentication**
```ini
# grafana.ini
[auth.ldap]
enabled = true
config_file = /etc/grafana/ldap.toml
allow_sign_up = true

[auth]
disable_login_form = false
oauth_auto_login = false
```

```toml
# ldap.toml
[[servers]]
host = "ldap.company.com"
port = 389
use_ssl = false
start_tls = false
ssl_skip_verify = false
bind_dn = "cn=admin,dc=company,dc=com"
bind_password = 'grafana'
search_filter = "(cn=%s)"
search_base_dns = ["dc=company,dc=com"]

[servers.attributes]
name = "givenName"
surname = "sn"
username = "cn"
member_of = "memberOf"
email =  "email"

[[servers.group_mappings]]
group_dn = "cn=admins,ou=groups,dc=company,dc=com"
org_role = "Admin"

[[servers.group_mappings]]
group_dn = "cn=developers,ou=groups,dc=company,dc=com"
org_role = "Editor"

[[servers.group_mappings]]
group_dn = "cn=viewers,ou=groups,dc=company,dc=com"
org_role = "Viewer"
```

2. **OAuth Configuration (Google)**
```ini
# grafana.ini
[auth.google]
enabled = true
client_id = your-google-client-id
client_secret = your-google-client-secret
scopes = https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/userinfo.email
auth_url = https://accounts.google.com/o/oauth2/auth
token_url = https://accounts.google.com/o/oauth2/token
allowed_domains = company.com
allow_sign_up = true
```

3. **Team Management API**
```bash
# Create team
curl -X POST \
  http://admin:admin123@localhost:3000/api/teams \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Platform Team",
    "email": "platform@company.com"
  }'

# Add user to team
curl -X POST \
  http://admin:admin123@localhost:3000/api/teams/1/members \
  -H 'Content-Type: application/json' \
  -d '{
    "userId": 2
  }'

# Set team permissions
curl -X POST \
  http://admin:admin123@localhost:3000/api/teams/1/permissions \
  -H 'Content-Type: application/json' \
  -d '{
    "permission": "Edit"
  }'
```

4. **Dashboard Permissions**
```json
{
  "dashboardPermissions": [
    {
      "role": "Viewer",
      "permission": 1
    },
    {
      "teamId": 1,
      "permission": 2
    },
    {
      "userId": 2,
      "permission": 4
    }
  ]
}
```

5. **API Key Management**
```bash
# Create API key
curl -X POST \
  http://admin:admin123@localhost:3000/api/auth/keys \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "monitoring-service",
    "role": "Editor",
    "secondsToLive": 86400
  }'

# Use API key
curl -H "Authorization: Bearer your-api-key" \
  http://localhost:3000/api/dashboards/home
```

### Exercise
- Set up SSO integration with your identity provider
- Create teams and assign appropriate permissions
- Implement API key rotation strategy

---

## Lab 8: Advanced Dashboard Patterns

### Objective
Implement advanced dashboard patterns for different use cases.

### Steps

1. **SLI/SLO Dashboard**
```json
{
  "dashboard": {
    "title": "SLI/SLO Dashboard",
    "panels": [
      {
        "id": 1,
        "title": "Availability SLI",
        "type": "stat",
        "targets": [
          {
            "expr": "sum(rate(http_requests_total{code!~\"5..\"}[30d])) / sum(rate(http_requests_total[30d])) * 100",
            "legendFormat": "30-day Availability"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "thresholds": {
              "steps": [
                {"color": "red", "value": null},
                {"color": "yellow", "value": 99},
                {"color": "green", "value": 99.9}
              ]
            },
            "unit": "percent",
            "min": 98,
            "max": 100
          }
        }
      },
      {
        "id": 2,
        "title": "Error Budget",
        "type": "bargauge",
        "targets": [
          {
            "expr": "(1 - (sum(rate(http_requests_total{code!~\"5..\"}[30d])) / sum(rate(http_requests_total[30d])))) * 100 / 0.1 * 100",
            "legendFormat": "Error Budget Used"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "min": 0,
            "max": 100,
            "unit": "percent",
            "thresholds": {
              "steps": [
                {"color": "green", "value": null},
                {"color": "yellow", "value": 75},
                {"color": "red", "value": 90}
              ]
            }
          }
        }
      }
    ]
  }
}
```

2. **Multi-Cluster Overview**
```json
{
  "dashboard": {
    "title": "Multi-Cluster Overview",
    "panels": [
      {
        "id": 1,
        "title": "Cluster Health",
        "type": "table",
        "targets": [
          {
            "expr": "up{job=\"kubernetes-nodes\"} == 1",
            "format": "table",
            "instant": true
          }
        ],
        "transformations": [
          {
            "id": "groupBy",
            "options": {
              "fields": {
                "cluster": {
                  "aggregations": ["count"],
                  "operation": "groupby"
                },
                "Value": {
                  "aggregations": ["sum"],
                  "operation": "aggregate"
                }
              }
            }
          }
        ]
      },
      {
        "id": 2,
        "title": "Cross-Cluster Resource Usage",
        "type": "timeseries",
        "targets": [
          {
            "expr": "sum(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) by (cluster) / sum(node_memory_MemTotal_bytes) by (cluster) * 100",
            "legendFormat": "{{cluster}} - Memory"
          },
          {
            "expr": "sum(rate(node_cpu_seconds_total{mode!=\"idle\"}[5m])) by (cluster) / sum(rate(node_cpu_seconds_total[5m])) by (cluster) * 100",
            "legendFormat": "{{cluster}} - CPU"
          }
        ]
      }
    ]
  }
}
```

3. **Application Dependency Map**
```json
{
  "dashboard": {
    "title": "Service Dependency Map",
    "panels": [
      {
        "id": 1,
        "title": "Service Map",
        "type": "nodeGraph",
        "targets": [
          {
            "expr": "sum(rate(istio_requests_total[5m])) by (source_app, destination_service_name)",
            "format": "table"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "custom": {
              "nodeOptions": {
                "mainStatUnit": "short",
                "secondaryStatUnit": "ms",
                "arcsField": "source_app",
                "colorField": "destination_service_name"
              }
            }
          }
        }
      }
    ]
  }
}
```

4. **Executive Summary Dashboard**
```json
{
  "dashboard": {
    "title": "Executive Summary",
    "panels": [
      {
        "id": 1,
        "title": "System Health Score",
        "type": "gauge",
        "targets": [
          {
            "expr": "(sum(up) / count(up)) * 100",
            "legendFormat": "Health Score"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "min": 0,
            "max": 100,
            "unit": "percent",
            "thresholds": {
              "steps": [
                {"color": "red", "value": 0},
                {"color": "yellow", "value": 95},
                {"color": "green", "value": 99}
              ]
            }
          }
        }
      },
      {
        "id": 2,
        "title": "Business KPIs",
        "type": "stat",
        "targets": [
          {
            "expr": "increase(revenue_total[24h])",
            "legendFormat": "Daily Revenue"
          },
          {
            "expr": "increase(user_registrations_total[24h])",
            "legendFormat": "New Users"
          },
          {
            "expr": "avg(user_satisfaction_score)",
            "legendFormat": "Satisfaction"
          }
        ]
      }
    ]
  }
}
```

### Exercise
- Create role-specific dashboards
- Implement drill-down navigation between dashboards
- Build comprehensive monitoring stories

---

## Lab 9: Performance Optimization

### Objective
Optimize Grafana performance for large-scale deployments.

### Steps

1. **Database Optimization**
```sql
-- PostgreSQL optimization
CREATE INDEX CONCURRENTLY idx_dashboard_org_id ON dashboard(org_id);
CREATE INDEX CONCURRENTLY idx_dashboard_slug ON dashboard(slug);
CREATE INDEX CONCURRENTLY idx_alert_state ON alert(state);
CREATE INDEX CONCURRENTLY idx_annotation_time ON annotation(epoch);

-- Query optimization
ANALYZE dashboard;
ANALYZE alert;
ANALYZE annotation;
```

2. **Caching Configuration**
```ini
# grafana.ini
[dataproxy]
timeout = 30
keep_alive_seconds = 30
idle_connections_per_host = 100

[caching]
enabled = true

[caching.memory]
# Configure in-memory cache
gc_interval = 1m

[caching.redis]
# Redis cache configuration
enabled = false
connstr = redis://localhost:6379/0
```

3. **Query Optimization**
```json
{
  "panel": {
    "targets": [
      {
        "expr": "rate(http_requests_total[5m])",
        "interval": "30s",
        "maxDataPoints": 1000,
        "cacheTimeout": "1m"
      }
    ],
    "options": {
      "dataLinks": [],
      "queryOptions": {
        "cacheTimeout": "5m",
        "queryCachingTTL": 86400000
      }
    }
  }
}
```

4. **Dashboard Loading Optimization**
```json
{
  "dashboard": {
    "meta": {
      "canSave": true,
      "canEdit": true,
      "canAdmin": false,
      "canStar": true,
      "slug": "optimized-dashboard",
      "url": "/d/optimized/optimized-dashboard",
      "expires": "0001-01-01T00:00:00Z",
      "created": "2023-01-01T00:00:00Z",
      "updated": "2023-01-01T00:00:00Z",
      "updatedBy": "admin",
      "createdBy": "admin",
      "version": 1,
      "hasAcl": false,
      "isFolder": false,
      "folderId": 0,
      "folderTitle": "General",
      "folderUrl": "",
      "provisioned": false,
      "provisionedExternalId": ""
    },
    "refresh": "1m",
    "schemaVersion": 30,
    "liveNow": false
  }
}
```

5. **Resource Limits**
```yaml
# kubernetes deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
spec:
  template:
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:latest
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
        env:
        - name: GF_DATABASE_MAX_OPEN_CONN
          value: "300"
        - name: GF_DATABASE_MAX_IDLE_CONN
          value: "300"
        - name: GF_RENDERING_SERVER_URL
          value: "http://grafana-image-renderer:8081/render"
```

### Exercise
- Monitor Grafana performance metrics
- Optimize slow-loading dashboards
- Implement caching strategies

---

## Lab 10: Enterprise Features and Scaling

### Objective
Implement enterprise features and scaling strategies.

### Steps

1. **High Availability Setup**
```yaml
# grafana-ha.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana-ha
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:latest
        env:
        - name: GF_DATABASE_TYPE
          value: postgres
        - name: GF_DATABASE_HOST
          value: postgres-ha:5432
        - name: GF_DATABASE_NAME
          value: grafana
        - name: GF_DATABASE_USER
          value: grafana
        - name: GF_DATABASE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: grafana-secret
              key: database-password
        - name: GF_SESSION_PROVIDER
          value: redis
        - name: GF_SESSION_PROVIDER_CONFIG
          value: addr=redis-ha:6379,pool_size=100
        ports:
        - containerPort: 3000
        readinessProbe:
          httpGet:
            path: /api/health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /api/health
            port: 3000
          initialDelaySeconds: 60
          periodSeconds: 30
```

2. **External Authentication**
```ini
# grafana.ini for SAML
[auth.saml]
enabled = true
certificate_path = /etc/grafana/saml.crt
private_key_path = /etc/grafana/saml.key
idp_metadata_url = https://idp.company.com/metadata
max_issue_delay = 90s
metadata_valid_duration = 48h
allow_idp_initiated = true
name_id_format = urn:oasis:names:tc:SAML:2.0:nameid-format:persistent
assertion_attribute_name = displayName
assertion_attribute_login = login
assertion_attribute_email = email
assertion_attribute_groups = groups
assertion_attribute_role = role
assertion_attribute_org = org
allowed_organizations = Company
org_mapping = Engineering:1:Editor,Platform:1:Admin
role_values_editor = editor
role_values_admin = admin
role_values_grafana_admin = admin
```

3. **Report Generation**
```json
{
  "reportConfig": {
    "name": "Weekly System Report",
    "schedule": "0 9 * * 1",
    "dashboards": [
      {
        "uid": "system-overview",
        "timeRange": {
          "from": "now-7d",
          "to": "now"
        }
      }
    ],
    "recipients": [
      "management@company.com",
      "platform@company.com"
    ],
    "format": "pdf",
    "orientation": "landscape"
  }
}
```

4. **Data Source Permissions**
```json
{
  "dataSourcePermissions": [
    {
      "dataSourceId": 1,
      "permission": 1,
      "teamId": 1
    },
    {
      "dataSourceId": 2,
      "permission": 2,
      "userId": 5
    }
  ]
}
```

5. **Plugin Management**
```bash
# Install plugins
grafana-cli plugins install grafana-clock-panel
grafana-cli plugins install grafana-piechart-panel
grafana-cli plugins install grafana-worldmap-panel

# Custom plugin installation
grafana-cli plugins install https://github.com/company/custom-plugin/archive/main.zip

# Plugin configuration
curl -X POST \
  http://admin:admin123@localhost:3000/api/plugins/custom-plugin/settings \
  -H 'Content-Type: application/json' \
  -d '{
    "enabled": true,
    "pinned": true,
    "jsonData": {
      "apiUrl": "https://api.company.com"
    },
    "secureJsonData": {
      "apiKey": "secret-api-key"
    }
  }'
```

### Exercise
- Set up high availability Grafana deployment
- Implement enterprise authentication
- Configure automated reporting

---

## Best Practices

### 1. Dashboard Design
- Follow the inverted pyramid principle
- Use consistent color schemes and layouts
- Implement proper drill-down navigation
- Keep dashboards focused and purposeful

### 2. Performance
- Optimize queries and reduce cardinality
- Use appropriate refresh intervals
- Implement caching strategies
- Monitor dashboard loading times

### 3. Security
- Implement proper authentication and authorization
- Use HTTPS for all communications
- Regular security audits and updates
- Principle of least privilege

### 4. Operational Excellence
- Version control dashboard configurations
- Implement backup and recovery procedures
- Monitor Grafana itself
- Document dashboard purposes and queries

---

## Common Use Cases

1. **Infrastructure Monitoring**
   - Server and network monitoring
   - Container and orchestration metrics
   - Cloud resource monitoring

2. **Application Performance**
   - Application metrics and SLIs
   - User experience monitoring
   - Business metrics tracking

3. **Security Monitoring**
   - Security event dashboards
   - Compliance reporting
   - Threat detection visualization

4. **Business Intelligence**
   - KPI dashboards
   - Executive reporting
   - Operational metrics

---

## Troubleshooting Guide

### Common Issues

1. **Dashboard Loading Slowly**
   - Optimize query complexity
   - Reduce time ranges
   - Check data source performance
   - Implement query caching

2. **Authentication Issues**
   - Verify SSO configuration
   - Check certificate validity
   - Review user mappings
   - Test connectivity to auth provider

3. **Missing Data**
   - Verify data source connectivity
   - Check query syntax
   - Review time ranges
   - Validate metric availability

4. **Alert Not Firing**
   - Test alert conditions
   - Check notification channel configuration
   - Verify alert rule evaluation
   - Review alert state history

---

## Advanced Topics

- Custom plugin development
- Advanced data transformations
- Grafana Enterprise features
- Integration with external systems
- Custom authentication providers
- Performance monitoring and optimization

---

## Resources

- [Grafana Documentation](https://grafana.com/docs/)
- [Dashboard Best Practices](https://grafana.com/docs/grafana/latest/best-practices/)
- [Plugin Development](https://grafana.com/docs/grafana/latest/developers/)
- [Grafana Community](https://community.grafana.com/)
- [Grafana Labs Blog](https://grafana.com/blog/)
