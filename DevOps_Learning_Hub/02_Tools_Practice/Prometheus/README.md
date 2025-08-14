# Prometheus - Monitoring and Alerting

## Overview
Prometheus is an open-source monitoring and alerting toolkit designed for reliability and scalability. It collects metrics from configured targets at given intervals, evaluates rule expressions, displays results, and can trigger alerts when specified conditions are observed.

## Learning Objectives
- Master Prometheus architecture and components
- Configure metric collection and storage
- Write powerful PromQL queries
- Implement alerting rules and notifications
- Scale Prometheus for production environments
- Integrate with service discovery systems
- Implement high availability and federation

## Prerequisites
- Basic understanding of monitoring concepts
- Linux/Unix system administration
- Docker and Kubernetes knowledge
- Basic networking concepts
- YAML configuration syntax

---

## Lab 1: Prometheus Installation and Basic Setup

### Objective
Install Prometheus and configure basic metric collection.

### Steps

1. **Docker Installation**
```bash
# Run Prometheus with Docker
docker run -d \
  --name prometheus \
  -p 9090:9090 \
  -v $(pwd)/prometheus.yml:/etc/prometheus/prometheus.yml \
  prom/prometheus:latest

# Access Prometheus UI
curl http://localhost:9090
```

2. **Basic Configuration**
```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

rule_files:
  - "alert_rules.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['localhost:9100']

  - job_name: 'application'
    static_configs:
      - targets: ['localhost:8080']
    metrics_path: /metrics
    scrape_interval: 5s
```

3. **Node Exporter Setup**
```bash
# Install Node Exporter
wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
tar xzf node_exporter-1.6.1.linux-amd64.tar.gz
cd node_exporter-1.6.1.linux-amd64
./node_exporter

# Or with Docker
docker run -d \
  --name node-exporter \
  -p 9100:9100 \
  --net="host" \
  --pid="host" \
  -v "/:/host:ro,rslave" \
  quay.io/prometheus/node-exporter:latest \
  --path.rootfs=/host
```

4. **Service File for Node Exporter**
```ini
# /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/node_exporter
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

### Exercise
- Install Prometheus and Node Exporter
- Configure basic scraping
- Explore the Prometheus UI and basic metrics

---

## Lab 2: PromQL Fundamentals

### Objective
Master Prometheus Query Language (PromQL) for metric analysis.

### Steps

1. **Basic PromQL Queries**
```promql
# Instant vector - current value
up

# Time series selection with labels
up{job="prometheus"}

# Metric with specific label values
node_cpu_seconds_total{mode="idle"}

# Multiple label filters
node_cpu_seconds_total{job="node-exporter", mode="idle", cpu="0"}
```

2. **Range Vectors and Functions**
```promql
# Range vector - values over time
up[5m]

# Rate function - per-second rate
rate(node_cpu_seconds_total[5m])

# Increase function - total increase
increase(prometheus_http_requests_total[1h])

# Average over time
avg_over_time(node_memory_MemAvailable_bytes[10m])

# Max and Min over time
max_over_time(node_load1[1h])
min_over_time(node_load1[1h])
```

3. **Aggregation Operators**
```promql
# Sum across all CPUs
sum(rate(node_cpu_seconds_total[5m])) by (mode)

# Average memory usage across instances
avg(node_memory_MemAvailable_bytes) by (instance)

# Maximum CPU usage
max(rate(node_cpu_seconds_total[5m])) by (instance)

# Count instances
count(up == 1)

# Top K values
topk(5, rate(prometheus_http_requests_total[5m]))

# Percentiles
quantile(0.95, rate(node_cpu_seconds_total[5m]))
```

4. **Advanced PromQL Patterns**
```promql
# CPU utilization percentage
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory utilization percentage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Disk usage percentage
100 - ((node_filesystem_avail_bytes * 100) / node_filesystem_size_bytes)

# Network I/O rate
rate(node_network_receive_bytes_total[5m]) + rate(node_network_transmit_bytes_total[5m])

# HTTP error rate
rate(prometheus_http_requests_total{code!~"2.."}[5m]) / rate(prometheus_http_requests_total[5m]) * 100

# Prediction - linear regression
predict_linear(node_filesystem_free_bytes[6h], 24 * 3600)
```

5. **Binary Operators and Functions**
```promql
# Arithmetic operators
node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes

# Comparison operators
node_load1 > 2

# Logical operators
(up == 1) and (rate(node_cpu_seconds_total[5m]) > 0.8)

# Set operations
rate(node_cpu_seconds_total[5m]) unless ignoring(mode) rate(node_cpu_seconds_total{mode="idle"}[5m])

# Vector matching
rate(prometheus_http_requests_total[5m]) / on(job, instance) group_left prometheus_http_requests_total offset 1h
```

### Exercise
- Write queries to monitor system resources
- Create complex aggregations across multiple metrics
- Implement SLI (Service Level Indicator) queries

---

## Lab 3: Recording Rules and Alert Rules

### Objective
Implement recording rules for performance and alerting rules for notifications.

### Steps

1. **Recording Rules Configuration**
```yaml
# recording_rules.yml
groups:
  - name: instance_rules
    interval: 30s
    rules:
      - record: instance:node_cpu_utilization:rate5m
        expr: 100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) by (instance) * 100)
        labels:
          metric_type: "utilization"
      
      - record: instance:node_memory_utilization:ratio
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes))
        labels:
          metric_type: "utilization"
      
      - record: instance:node_filesystem_utilization:ratio
        expr: 1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes)
        labels:
          metric_type: "utilization"

  - name: application_rules
    interval: 15s
    rules:
      - record: job:http_request_rate:5m
        expr: sum(rate(prometheus_http_requests_total[5m])) by (job)
      
      - record: job:http_request_latency_p95:5m
        expr: histogram_quantile(0.95, sum(rate(prometheus_http_request_duration_seconds_bucket[5m])) by (job, le))
      
      - record: job:http_error_rate:5m
        expr: sum(rate(prometheus_http_requests_total{code!~"2.."}[5m])) by (job) / sum(rate(prometheus_http_requests_total[5m])) by (job)
```

2. **Alert Rules Configuration**
```yaml
# alert_rules.yml
groups:
  - name: system_alerts
    rules:
      - alert: InstanceDown
        expr: up == 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Instance {{ $labels.instance }} down"
          description: "{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 5 minutes."

      - alert: HighCPUUsage
        expr: instance:node_cpu_utilization:rate5m > 80
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          description: "CPU usage is above 80% for more than 10 minutes on {{ $labels.instance }}."

      - alert: HighMemoryUsage
        expr: instance:node_memory_utilization:ratio > 0.85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage on {{ $labels.instance }}"
          description: "Memory usage is above 85% on {{ $labels.instance }}."

      - alert: DiskSpaceLow
        expr: instance:node_filesystem_utilization:ratio > 0.9
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Disk space low on {{ $labels.instance }}"
          description: "Disk usage is above 90% on {{ $labels.instance }} filesystem {{ $labels.mountpoint }}."

  - name: application_alerts
    rules:
      - alert: HighErrorRate
        expr: job:http_error_rate:5m > 0.05
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "High error rate on {{ $labels.job }}"
          description: "Error rate is above 5% for {{ $labels.job }}."

      - alert: HighLatency
        expr: job:http_request_latency_p95:5m > 0.5
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High latency on {{ $labels.job }}"
          description: "95th percentile latency is above 500ms for {{ $labels.job }}."

      - alert: LowRequestRate
        expr: job:http_request_rate:5m < 10
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Low request rate on {{ $labels.job }}"
          description: "Request rate is below 10 requests/second for {{ $labels.job }}."
```

3. **Complex Alert Rules**
```yaml
# advanced_alerts.yml
groups:
  - name: slo_alerts
    rules:
      # SLO: 99.9% availability
      - alert: SLOViolation
        expr: |
          (
            sum(rate(prometheus_http_requests_total{code!~"5.."}[5m]))
            /
            sum(rate(prometheus_http_requests_total[5m]))
          ) < 0.999
        for: 1m
        labels:
          severity: critical
          slo: availability
        annotations:
          summary: "SLO violation: Availability below 99.9%"
          description: "Current availability: {{ $value | humanizePercentage }}"

      # Predictive alert
      - alert: DiskWillFillIn4Hours
        expr: predict_linear(node_filesystem_free_bytes[1h], 4 * 3600) < 0
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Disk will fill in 4 hours on {{ $labels.instance }}"
          description: "Based on current usage trend, disk {{ $labels.mountpoint }} will be full in 4 hours."

      # Multi-condition alert
      - alert: SystemUnderStress
        expr: |
          (
            instance:node_cpu_utilization:rate5m > 80
          and
            instance:node_memory_utilization:ratio > 0.8
          and
            rate(node_context_switches_total[5m]) > 50000
          )
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "System under stress on {{ $labels.instance }}"
          description: "High CPU, memory usage and context switches detected."
```

### Exercise
- Create recording rules for your application metrics
- Implement comprehensive alerting rules
- Test alert conditions and notifications

---

## Lab 4: Service Discovery Integration

### Objective
Configure Prometheus with various service discovery mechanisms.

### Steps

1. **Kubernetes Service Discovery**
```yaml
# kubernetes_sd_config.yml
scrape_configs:
  # Pod discovery
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
        action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: ${1}:${2}
        target_label: __address__
      - action: labelmap
        regex: __meta_kubernetes_pod_label_(.+)
      - source_labels: [__meta_kubernetes_namespace]
        action: replace
        target_label: kubernetes_namespace
      - source_labels: [__meta_kubernetes_pod_name]
        action: replace
        target_label: kubernetes_pod_name

  # Service discovery
  - job_name: 'kubernetes-services'
    kubernetes_sd_configs:
      - role: service
    relabel_configs:
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scheme]
        action: replace
        target_label: __scheme__
        regex: (https?)
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels: [__address__, __meta_kubernetes_service_annotation_prometheus_io_port]
        action: replace
        target_label: __address__
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: ${1}:${2}
      - action: labelmap
        regex: __meta_kubernetes_service_label_(.+)
      - source_labels: [__meta_kubernetes_namespace]
        action: replace
        target_label: kubernetes_namespace
      - source_labels: [__meta_kubernetes_service_name]
        action: replace
        target_label: kubernetes_service_name

  # Node discovery
  - job_name: 'kubernetes-nodes'
    kubernetes_sd_configs:
      - role: node
    relabel_configs:
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)
      - target_label: __address__
        replacement: kubernetes.default.svc:443
      - source_labels: [__meta_kubernetes_node_name]
        regex: (.+)
        target_label: __metrics_path__
        replacement: /api/v1/nodes/${1}/proxy/metrics
```

2. **Consul Service Discovery**
```yaml
# consul_sd_config.yml
scrape_configs:
  - job_name: 'consul-services'
    consul_sd_configs:
      - server: 'consul.service.consul:8500'
        services: []
        tags:
          - prometheus
    relabel_configs:
      - source_labels: [__meta_consul_service]
        target_label: job
      - source_labels: [__meta_consul_service_address]
        target_label: __address__
      - source_labels: [__meta_consul_service_port]
        target_label: __port__
      - source_labels: [__meta_consul_tags]
        regex: '.*,prometheus_path=([^,]*).*'
        target_label: __metrics_path__
      - source_labels: [__meta_consul_dc]
        target_label: datacenter
```

3. **AWS EC2 Service Discovery**
```yaml
# aws_sd_config.yml
scrape_configs:
  - job_name: 'aws-ec2'
    ec2_sd_configs:
      - region: us-west-2
        port: 9100
        filters:
          - name: tag:Environment
            values: [production]
          - name: instance-state-name
            values: [running]
    relabel_configs:
      - source_labels: [__meta_ec2_tag_Name]
        target_label: instance_name
      - source_labels: [__meta_ec2_tag_Environment]
        target_label: environment
      - source_labels: [__meta_ec2_private_ip]
        target_label: __address__
        replacement: '${1}:9100'
```

4. **DNS Service Discovery**
```yaml
# dns_sd_config.yml
scrape_configs:
  - job_name: 'dns-srv-discovery'
    dns_sd_configs:
      - names:
          - '_prometheus._tcp.monitoring.example.com'
        type: 'SRV'
        port: 9090
    relabel_configs:
      - source_labels: [__meta_dns_name]
        target_label: __address__
```

### Exercise
- Configure service discovery for your infrastructure
- Implement relabeling rules for proper metric organization
- Test dynamic service registration and deregistration

---

## Lab 5: Kubernetes Monitoring Stack

### Objective
Deploy comprehensive Prometheus monitoring stack on Kubernetes.

### Steps

1. **Prometheus Operator Installation**
```bash
# Install Prometheus Operator using Helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=100Gi \
  --set grafana.adminPassword=admin123
```

2. **Custom Prometheus Configuration**
```yaml
# prometheus-config.yaml
apiVersion: monitoring.coreos.com/v1
kind: Prometheus
metadata:
  name: prometheus
  namespace: monitoring
spec:
  serviceAccountName: prometheus
  serviceMonitorSelector:
    matchLabels:
      team: frontend
  ruleSelector:
    matchLabels:
      prometheus: kube-prometheus
      role: alert-rules
  resources:
    requests:
      memory: 400Mi
      cpu: 100m
    limits:
      memory: 2Gi
      cpu: 1000m
  retention: 30d
  storage:
    volumeClaimTemplate:
      spec:
        storageClassName: fast-ssd
        resources:
          requests:
            storage: 100Gi
  securityContext:
    fsGroup: 2000
    runAsNonRoot: true
    runAsUser: 1000
  additionalScrapeConfigs:
    name: additional-scrape-configs
    key: prometheus-additional.yaml
```

3. **ServiceMonitor for Application**
```yaml
# app-servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: myapp-metrics
  namespace: monitoring
  labels:
    app: myapp
    release: prometheus
spec:
  selector:
    matchLabels:
      app: myapp
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
    honorLabels: true
  namespaceSelector:
    matchNames:
    - production
    - staging
```

4. **PodMonitor Configuration**
```yaml
# pod-monitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: pod-metrics
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: myapp
  podMetricsEndpoints:
  - port: metrics
    interval: 15s
    path: /metrics
    relabelings:
    - sourceLabels: [__meta_kubernetes_pod_node_name]
      targetLabel: node
    - sourceLabels: [__meta_kubernetes_pod_name]
      targetLabel: pod
```

5. **PrometheusRule for Kubernetes**
```yaml
# kubernetes-rules.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: kubernetes-rules
  namespace: monitoring
  labels:
    prometheus: kube-prometheus
    role: alert-rules
spec:
  groups:
  - name: kubernetes.rules
    rules:
    - alert: KubePodCrashLooping
      expr: max_over_time(kube_pod_container_status_waiting_reason{reason="CrashLoopBackOff"}[5m]) >= 1
      for: 15m
      labels:
        severity: warning
      annotations:
        description: 'Pod {{ $labels.namespace }}/{{ $labels.pod }} ({{ $labels.container }}) is in waiting state (reason: "CrashLoopBackOff").'
        summary: Pod is crash looping.

    - alert: KubePodNotReady
      expr: sum by (namespace, pod) (max by(namespace, pod) (kube_pod_status_phase{phase=~"Pending|Unknown"}) * on(namespace, pod) group_left(owner_kind) topk by(namespace, pod) (1, max by(namespace, pod, owner_kind) (kube_pod_owner{owner_kind!="Job"}))) > 0
      for: 15m
      labels:
        severity: warning
      annotations:
        description: 'Pod {{ $labels.namespace }}/{{ $labels.pod }} has been in a non-ready state for longer than 15 minutes.'
        summary: Pod has been in a non-ready state for more than 15 minutes.

    - alert: KubeNodeNotReady
      expr: kube_node_status_condition{condition="Ready",status="true"} == 0
      for: 15m
      labels:
        severity: warning
      annotations:
        description: '{{ $labels.node }} has been unready for a long time'
        summary: Node is not ready.
```

### Exercise
- Deploy Prometheus on Kubernetes with operator
- Create ServiceMonitors for your applications
- Implement Kubernetes-specific alerting rules

---

## Lab 6: High Availability and Federation

### Objective
Implement Prometheus high availability and federation for scalable monitoring.

### Steps

1. **Prometheus High Availability Setup**
```yaml
# prometheus-ha.yaml
apiVersion: monitoring.coreos.com/v1
kind: Prometheus
metadata:
  name: prometheus-ha
  namespace: monitoring
spec:
  replicas: 2
  retention: 15d
  storage:
    volumeClaimTemplate:
      spec:
        storageClassName: fast-ssd
        resources:
          requests:
            storage: 50Gi
  serviceAccountName: prometheus
  serviceMonitorSelector: {}
  ruleSelector: {}
  resources:
    requests:
      memory: 2Gi
      cpu: 500m
    limits:
      memory: 4Gi
      cpu: 2000m
  externalLabels:
    cluster: production
    region: us-west-2
    replica: '{{.Replica}}'
```

2. **Thanos Integration for Long-term Storage**
```yaml
# thanos-sidecar.yaml
apiVersion: monitoring.coreos.com/v1
kind: Prometheus
metadata:
  name: prometheus-thanos
  namespace: monitoring
spec:
  replicas: 2
  thanos:
    image: quay.io/thanos/thanos:v0.32.5
    version: v0.32.5
    objectStorageConfig:
      name: thanos-objstore-config
      key: objstore.yml
  storage:
    volumeClaimTemplate:
      spec:
        storageClassName: fast-ssd
        resources:
          requests:
            storage: 100Gi
  retention: 2h  # Short retention with Thanos
  externalLabels:
    cluster: production
    replica: '{{.Replica}}'

---
apiVersion: v1
kind: Secret
metadata:
  name: thanos-objstore-config
  namespace: monitoring
type: Opaque
stringData:
  objstore.yml: |
    type: S3
    config:
      bucket: thanos-metrics
      endpoint: s3.amazonaws.com
      region: us-west-2
      access_key: ACCESS_KEY
      secret_key: SECRET_KEY
```

3. **Federation Configuration**
```yaml
# federation-config.yml
scrape_configs:
  # Global Prometheus federating from regional instances
  - job_name: 'federate-us-west'
    scrape_interval: 15s
    honor_labels: true
    metrics_path: '/federate'
    params:
      'match[]':
        - '{job=~"kubernetes-.*"}'
        - '{__name__=~"job:.*"}'
        - '{__name__=~"instance:.*"}'
        - 'up'
        - 'node_load1'
        - 'node_memory_utilization'
        - 'node_cpu_utilization'
    static_configs:
      - targets:
        - 'prometheus-us-west.monitoring.svc.cluster.local:9090'
    relabel_configs:
      - source_labels: [__address__]
        target_label: region
        replacement: 'us-west'

  - job_name: 'federate-us-east'
    scrape_interval: 15s
    honor_labels: true
    metrics_path: '/federate'
    params:
      'match[]':
        - '{job=~"kubernetes-.*"}'
        - '{__name__=~"job:.*"}'
        - '{__name__=~"instance:.*"}'
        - 'up'
    static_configs:
      - targets:
        - 'prometheus-us-east.monitoring.svc.cluster.local:9090'
    relabel_configs:
      - source_labels: [__address__]
        target_label: region
        replacement: 'us-east'
```

4. **Remote Write Configuration**
```yaml
# remote-write-config.yml
global:
  external_labels:
    cluster: production
    region: us-west-2

remote_write:
  - url: "https://prometheus-remote-write.company.com/api/v1/write"
    queue_config:
      max_samples_per_send: 1000
      max_shards: 200
      capacity: 2500
    write_relabel_configs:
      - source_labels: [__name__]
        regex: 'go_.*|process_.*|promhttp_.*'
        action: drop

remote_read:
  - url: "https://prometheus-remote-read.company.com/api/v1/read"
    read_recent: true
```

### Exercise
- Set up highly available Prometheus deployment
- Configure federation between multiple Prometheus instances
- Implement long-term storage with Thanos

---

## Lab 7: Custom Metrics and Exporters

### Objective
Create custom metrics and exporters for application monitoring.

### Steps

1. **Custom Application Metrics (Python)**
```python
# app_metrics.py
from prometheus_client import Counter, Histogram, Gauge, start_http_server
import time
import random

# Define metrics
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint'])
REQUEST_LATENCY = Histogram('http_request_duration_seconds', 'HTTP request latency')
ACTIVE_USERS = Gauge('active_users_total', 'Number of active users')
QUEUE_SIZE = Gauge('queue_size', 'Current queue size')

class MetricsMiddleware:
    def __init__(self, app):
        self.app = app
    
    def __call__(self, environ, start_response):
        start_time = time.time()
        method = environ['REQUEST_METHOD']
        path = environ['PATH_INFO']
        
        REQUEST_COUNT.labels(method=method, endpoint=path).inc()
        
        def new_start_response(status, response_headers, exc_info=None):
            REQUEST_LATENCY.observe(time.time() - start_time)
            return start_response(status, response_headers, exc_info)
        
        return self.app(environ, new_start_response)

# Business logic metrics
def update_business_metrics():
    # Simulate business metrics
    ACTIVE_USERS.set(random.randint(100, 1000))
    QUEUE_SIZE.set(random.randint(0, 50))

if __name__ == '__main__':
    # Start metrics server
    start_http_server(8000)
    
    # Simulate application
    while True:
        update_business_metrics()
        time.sleep(30)
```

2. **Custom Exporter (Go)**
```go
// custom_exporter.go
package main

import (
    "log"
    "net/http"
    "time"
    "math/rand"
    
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
    applicationHealth = prometheus.NewGaugeVec(
        prometheus.GaugeOpts{
            Name: "application_health_status",
            Help: "Current health status of the application",
        },
        []string{"service", "component"},
    )
    
    databaseConnections = prometheus.NewGaugeVec(
        prometheus.GaugeOpts{
            Name: "database_connections_active",
            Help: "Number of active database connections",
        },
        []string{"database", "pool"},
    )
    
    cacheOperations = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "cache_operations_total",
            Help: "Total number of cache operations",
        },
        []string{"operation", "result"},
    )
)

func init() {
    prometheus.MustRegister(applicationHealth)
    prometheus.MustRegister(databaseConnections)
    prometheus.MustRegister(cacheOperations)
}

func updateMetrics() {
    // Simulate health checks
    applicationHealth.With(prometheus.Labels{"service": "api", "component": "auth"}).Set(1)
    applicationHealth.With(prometheus.Labels{"service": "api", "component": "user"}).Set(1)
    
    // Simulate database connections
    databaseConnections.With(prometheus.Labels{"database": "users", "pool": "read"}).Set(float64(rand.Intn(50)))
    databaseConnections.With(prometheus.Labels{"database": "users", "pool": "write"}).Set(float64(rand.Intn(10)))
    
    // Simulate cache operations
    cacheOperations.With(prometheus.Labels{"operation": "get", "result": "hit"}).Inc()
    cacheOperations.With(prometheus.Labels{"operation": "get", "result": "miss"}).Inc()
}

func main() {
    go func() {
        for {
            updateMetrics()
            time.Sleep(10 * time.Second)
        }
    }()
    
    http.Handle("/metrics", promhttp.Handler())
    log.Fatal(http.ListenAndServe(":8080", nil))
}
```

3. **JMX Exporter for Java Applications**
```yaml
# jmx_exporter_config.yml
startDelaySeconds: 0
ssl: false
lowercaseOutputName: false
lowercaseOutputLabelNames: false
rules:
  # JVM metrics
  - pattern: 'java.lang<type=Memory><HeapMemoryUsage>(\w+)'
    name: jvm_memory_heap_$1
    type: GAUGE
    
  - pattern: 'java.lang<type=GarbageCollector, name=(.+)><(\w+)>'
    name: jvm_gc_$2
    type: GAUGE
    labels:
      gc_name: $1
      
  # Application metrics
  - pattern: 'com.myapp<type=RequestProcessor><(\w+)>'
    name: myapp_requests_$1
    type: GAUGE
    
  - pattern: 'com.myapp<type=DatabasePool, name=(.+)><(\w+)>'
    name: myapp_db_pool_$2
    labels:
      pool_name: $1
```

4. **Database Exporter Configuration**
```yaml
# postgres_exporter.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'postgres'
    static_configs:
      - targets: ['localhost:9187']
    
# Custom queries for postgres_exporter
queries:
  - name: "custom_query_1"
    query: "SELECT count(*) as active_sessions FROM pg_stat_activity WHERE state = 'active'"
    metrics:
      - active_sessions:
          usage: "GAUGE"
          description: "Number of active sessions"
          
  - name: "slow_queries"
    query: "SELECT query, mean_time, calls FROM pg_stat_statements WHERE mean_time > 1000 ORDER BY mean_time DESC LIMIT 10"
    metrics:
      - slow_query_time:
          usage: "GAUGE"
          description: "Slow query execution time"
      - slow_query_calls:
          usage: "COUNTER" 
          description: "Number of slow query calls"
```

### Exercise
- Create custom metrics for your application
- Build a custom exporter for your technology stack
- Implement business-specific metrics

---

## Lab 8: Performance Optimization and Scaling

### Objective
Optimize Prometheus performance and implement scaling strategies.

### Steps

1. **Prometheus Configuration Tuning**
```yaml
# optimized-prometheus.yml
global:
  scrape_interval: 30s  # Increase interval to reduce load
  evaluation_interval: 30s
  external_labels:
    cluster: production
    region: us-west-2

# Storage optimization
storage:
  tsdb:
    retention.time: 15d
    retention.size: 100GB
    wal-compression: true
    head-chunks-write-queue-size: 10000

# Query optimization
query:
  max-concurrency: 20
  timeout: 2m
  max-samples: 50000000

scrape_configs:
  - job_name: 'high-frequency'
    scrape_interval: 15s
    static_configs:
      - targets: ['critical-service:9090']
    
  - job_name: 'low-frequency'
    scrape_interval: 300s  # 5 minutes for less critical services
    static_configs:
      - targets: ['batch-service:9090']
    
  - job_name: 'sample-limit'
    sample_limit: 10000
    static_configs:
      - targets: ['noisy-service:9090']
```

2. **Recording Rules for Performance**
```yaml
# performance-rules.yml
groups:
  - name: performance.rules
    interval: 30s
    rules:
      # Pre-aggregate expensive queries
      - record: cluster:cpu_usage:rate5m
        expr: sum(rate(node_cpu_seconds_total{mode!="idle"}[5m])) by (cluster)
        
      - record: cluster:memory_usage:bytes
        expr: sum(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) by (cluster)
        
      - record: namespace:pod_memory_usage:sum
        expr: sum(container_memory_working_set_bytes{container!=""}) by (namespace)
        
      - record: namespace:pod_cpu_usage:sum
        expr: sum(rate(container_cpu_usage_seconds_total{container!=""}[5m])) by (namespace)

  - name: sli.rules
    interval: 60s
    rules:
      # Service Level Indicators
      - record: sli:http_success_rate:5m
        expr: sum(rate(prometheus_http_requests_total{code!~"5.."}[5m])) by (job) / sum(rate(prometheus_http_requests_total[5m])) by (job)
        
      - record: sli:http_latency_p99:5m
        expr: histogram_quantile(0.99, sum(rate(prometheus_http_request_duration_seconds_bucket[5m])) by (job, le))
```

3. **Relabeling for Efficiency**
```yaml
# efficient-relabeling.yml
scrape_configs:
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      # Drop unnecessary labels
      - regex: '__meta_kubernetes_pod_label_pod_template_.*'
        action: labeldrop
      - regex: '__meta_kubernetes_pod_annotation_kubectl_.*'
        action: labeldrop
        
      # Keep only required metrics
      - source_labels: [__name__]
        regex: 'go_.*|process_.*|prometheus_.*'
        action: drop
        
      # Efficient label mapping
      - source_labels: [__meta_kubernetes_pod_label_app]
        target_label: app
      - source_labels: [__meta_kubernetes_pod_label_version]
        target_label: version
      - source_labels: [__meta_kubernetes_namespace]
        target_label: namespace
```

4. **Sharding Configuration**
```yaml
# prometheus-shard-0.yml
global:
  external_labels:
    prometheus: prometheus-0
    shard: "0"

scrape_configs:
  - job_name: 'kubernetes-pods-shard-0'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      # Shard based on hash of instance
      - source_labels: [__meta_kubernetes_pod_name]
        target_label: __tmp_hash
        modulus: 2
        action: hashmod
      - source_labels: [__tmp_hash]
        regex: "0"
        action: keep

# prometheus-shard-1.yml  
global:
  external_labels:
    prometheus: prometheus-1
    shard: "1"

scrape_configs:
  - job_name: 'kubernetes-pods-shard-1'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_name]
        target_label: __tmp_hash
        modulus: 2
        action: hashmod
      - source_labels: [__tmp_hash]
        regex: "1"
        action: keep
```

### Exercise
- Optimize Prometheus configuration for your workload
- Implement efficient relabeling rules
- Set up Prometheus sharding for scalability

---

## Lab 9: Prometheus with Microservices

### Objective
Implement comprehensive monitoring for microservices architecture.

### Steps

1. **Service Mesh Integration (Istio)**
```yaml
# istio-prometheus.yml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  name: istio-control-plane
spec:
  values:
    telemetry:
      v2:
        prometheus:
          configOverride:
            metric_relabeling_configs:
              - source_labels: [__name__]
                regex: 'istio_.*'
                target_label: __tmp_istio_metric
            disable_host_header_fallback: true
  components:
    pilot:
      k8s:
        env:
          - name: PILOT_ENABLE_WORKLOAD_ENTRY_AUTOREGISTRATION
            value: true

---
# ServiceMonitor for Istio
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: istio-proxy
  namespace: istio-system
spec:
  selector:
    matchLabels:
      app: istiod
  endpoints:
  - port: http-monitoring
    interval: 15s
    path: /stats/prometheus
    relabelings:
    - sourceLabels: [__meta_kubernetes_pod_name]
      targetLabel: pod_name
```

2. **Distributed Tracing Integration**
```yaml
# jaeger-prometheus.yml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: jaeger-metrics
  namespace: observability
spec:
  selector:
    matchLabels:
      app: jaeger
  endpoints:
  - port: admin-http
    interval: 30s
    path: /metrics
    relabelings:
    - sourceLabels: [__meta_kubernetes_service_name]
      targetLabel: service
```

3. **Microservice SLI/SLO Configuration**
```yaml
# microservice-slos.yml
groups:
  - name: microservice.slos
    rules:
      # API Gateway SLI
      - record: sli:gateway_success_rate:5m
        expr: |
          sum(rate(istio_requests_total{source_app="istio-gateway", response_code!~"5.."}[5m])) by (destination_service_name)
          /
          sum(rate(istio_requests_total{source_app="istio-gateway"}[5m])) by (destination_service_name)
      
      # Service-to-service SLI
      - record: sli:service_success_rate:5m
        expr: |
          sum(rate(istio_requests_total{response_code!~"5.."}[5m])) by (source_app, destination_service_name)
          /
          sum(rate(istio_requests_total[5m])) by (source_app, destination_service_name)
      
      # Latency SLI
      - record: sli:service_latency_p99:5m
        expr: histogram_quantile(0.99, sum(rate(istio_request_duration_milliseconds_bucket[5m])) by (destination_service_name, le))

  - name: microservice.alerts
    rules:
      - alert: ServiceSLOViolation
        expr: sli:service_success_rate:5m < 0.99
        for: 2m
        labels:
          severity: critical
          slo: availability
        annotations:
          summary: "Service {{ $labels.destination_service_name }} SLO violation"
          description: "Service availability is {{ $value | humanizePercentage }}, below 99% SLO"
      
      - alert: ServiceHighLatency
        expr: sli:service_latency_p99:5m > 500
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High latency for {{ $labels.destination_service_name }}"
          description: "99th percentile latency is {{ $value }}ms"
```

4. **Circuit Breaker Monitoring**
```yaml
# circuit-breaker-rules.yml
groups:
  - name: circuit-breaker
    rules:
      - record: circuit_breaker:failure_rate:5m
        expr: |
          sum(rate(hystrix_command_total{event="failure"}[5m])) by (command_group, command_name)
          /
          sum(rate(hystrix_command_total[5m])) by (command_group, command_name)
      
      - record: circuit_breaker:open_duration:current
        expr: time() - hystrix_circuit_breaker_open_time
      
      - alert: CircuitBreakerOpen
        expr: hystrix_circuit_breaker_open == 1
        for: 1m
        labels:
          severity: warning
        annotations:
          summary: "Circuit breaker open for {{ $labels.command_name }}"
          description: "Circuit breaker has been open for {{ $value | humanizeDuration }}"
```

### Exercise
- Set up monitoring for your microservices architecture
- Implement SLI/SLO monitoring for critical services
- Configure distributed tracing correlation with metrics

---

## Lab 10: Prometheus Ecosystem Integration

### Objective
Integrate Prometheus with the broader observability ecosystem.

### Steps

1. **Grafana Integration**
```yaml
# grafana-datasource.yml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    jsonData:
      httpMethod: POST
      manageAlerts: true
      prometheusType: Prometheus
      prometheusVersion: 2.40.0
      cacheLevel: 'High'
      incrementalQueries: true
      incrementalQueryOverlapWindow: 10m
```

2. **Alertmanager Configuration**
```yaml
# alertmanager.yml
global:
  smtp_smarthost: 'smtp.company.com:587'
  smtp_from: 'alerts@company.com'
  slack_api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'

route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 10s
  group_interval: 5m
  repeat_interval: 12h
  receiver: 'default'
  routes:
  - match:
      severity: critical
    receiver: 'critical-alerts'
    group_wait: 5s
    repeat_interval: 5m
  
  - match:
      team: platform
    receiver: 'platform-team'
  
  - match_re:
      service: ^(frontend|backend)$
    receiver: 'application-team'

receivers:
- name: 'default'
  slack_configs:
  - channel: '#alerts'
    title: 'Alert: {{ .GroupLabels.alertname }}'
    text: |
      {{ range .Alerts }}
      *Alert:* {{ .Annotations.summary }}
      *Description:* {{ .Annotations.description }}
      *Severity:* {{ .Labels.severity }}
      {{ end }}

- name: 'critical-alerts'
  slack_configs:
  - channel: '#critical-alerts'
    title: 'CRITICAL: {{ .GroupLabels.alertname }}'
    text: |
      {{ range .Alerts }}
      🚨 *CRITICAL ALERT* 🚨
      *Summary:* {{ .Annotations.summary }}
      *Description:* {{ .Annotations.description }}
      *Labels:* {{ range .Labels.SortedPairs }}{{ .Name }}={{ .Value }} {{ end }}
      {{ end }}
  email_configs:
  - to: 'oncall@company.com'
    subject: 'CRITICAL: {{ .GroupLabels.alertname }}'
    body: |
      {{ range .Alerts }}
      Alert: {{ .Annotations.summary }}
      Description: {{ .Annotations.description }}
      Labels: {{ range .Labels.SortedPairs }}{{ .Name }}={{ .Value }} {{ end }}
      {{ end }}

- name: 'platform-team'
  slack_configs:
  - channel: '#platform-alerts'
    title: 'Platform Alert: {{ .GroupLabels.alertname }}'

inhibit_rules:
- source_match:
    severity: 'critical'
  target_match:
    severity: 'warning'
  equal: ['alertname', 'cluster', 'service']
```

3. **VictoriaMetrics Integration**
```yaml
# victoria-metrics.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: victoria-metrics
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: victoria-metrics
  template:
    metadata:
      labels:
        app: victoria-metrics
    spec:
      containers:
      - name: victoria-metrics
        image: victoriametrics/victoria-metrics:latest
        args:
          - -storageDataPath=/victoria-metrics-data
          - -httpListenAddr=:8428
          - -retentionPeriod=12m
          - -memory.allowedPercent=60
        ports:
        - containerPort: 8428
        volumeMounts:
        - name: storage
          mountPath: /victoria-metrics-data
        resources:
          requests:
            memory: 2Gi
            cpu: 500m
          limits:
            memory: 4Gi
            cpu: 2000m
      volumes:
      - name: storage
        persistentVolumeClaim:
          claimName: victoria-metrics-storage

---
# Remote write to VictoriaMetrics
remote_write:
  - url: http://victoria-metrics:8428/api/v1/write
    queue_config:
      max_samples_per_send: 10000
      capacity: 20000
      max_shards: 30
```

4. **OpenTelemetry Integration**
```yaml
# otel-collector.yml
apiVersion: opentelemetry.io/v1alpha1
kind: OpenTelemetryCollector
metadata:
  name: otel-collector
  namespace: monitoring
spec:
  config: |
    receivers:
      prometheus:
        config:
          scrape_configs:
            - job_name: 'otel-collector'
              scrape_interval: 30s
              static_configs:
                - targets: ['localhost:8888']
    
    processors:
      batch:
        timeout: 1s
        send_batch_size: 1024
      
      resource:
        attributes:
          - key: service.name
            value: otel-collector
            action: upsert
    
    exporters:
      prometheus:
        endpoint: "0.0.0.0:8889"
        namespace: otel
        const_labels:
          collector: otelcol
      
      otlp/jaeger:
        endpoint: jaeger-collector:14250
        tls:
          insecure: true
    
    service:
      pipelines:
        metrics:
          receivers: [prometheus]
          processors: [batch, resource]
          exporters: [prometheus]
        
        traces:
          receivers: [otlp]
          processors: [batch]
          exporters: [otlp/jaeger]
```

### Exercise
- Set up comprehensive alerting with Alertmanager
- Integrate Prometheus with Grafana for visualization
- Configure long-term storage with VictoriaMetrics or Thanos

---

## Best Practices

### 1. Metric Design
- Use consistent naming conventions
- Choose appropriate metric types (counter, gauge, histogram)
- Avoid high cardinality labels
- Document your metrics

### 2. Performance Optimization
- Use recording rules for expensive queries
- Implement efficient relabeling
- Monitor Prometheus resource usage
- Use sharding for large deployments

### 3. Security
- Enable authentication and authorization
- Use TLS for secure communication
- Implement network segmentation
- Regular security updates

### 4. Operational Excellence
- Monitor Prometheus itself
- Implement backup and recovery procedures
- Use infrastructure as code
- Document operational procedures

---

## Common Use Cases

1. **Infrastructure Monitoring**
   - Server health and performance
   - Network monitoring
   - Storage monitoring

2. **Application Monitoring**
   - Application metrics and SLIs
   - Business metrics
   - User experience monitoring

3. **Container and Orchestration**
   - Docker container monitoring
   - Kubernetes cluster monitoring
   - Service mesh observability

4. **Cloud Native Monitoring**
   - Multi-cloud monitoring
   - Serverless monitoring
   - Auto-scaling metrics

---

## Troubleshooting Guide

### Common Issues

1. **High Memory Usage**
   - Reduce retention period
   - Optimize queries
   - Implement metric filtering
   - Use recording rules

2. **Slow Queries**
   - Optimize PromQL queries
   - Use recording rules
   - Implement proper indexing
   - Reduce query range

3. **Missing Metrics**
   - Check service discovery
   - Verify scrape configuration
   - Check network connectivity
   - Review relabeling rules

4. **Alert Fatigue**
   - Implement proper alert hygiene
   - Use inhibition rules
   - Adjust alert thresholds
   - Group related alerts

---

## Advanced Topics

- Prometheus internals and TSDB
- Custom exporters development
- Advanced PromQL techniques
- Multi-tenant Prometheus
- Cost optimization strategies
- Compliance and governance

---

## Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [PromQL Tutorial](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Alerting Rules](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/)
- [Best Practices Guide](https://prometheus.io/docs/practices/)
- [Prometheus Operator](https://prometheus-operator.dev/)
