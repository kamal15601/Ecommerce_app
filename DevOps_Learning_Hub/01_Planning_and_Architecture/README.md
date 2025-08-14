# 📋 DevOps Planning and Architecture

This section covers the foundational concepts and architectural principles that guide successful DevOps implementations.

## 📚 Table of Contents

1. [DevOps Lifecycle Overview](#devops-lifecycle-overview)
2. [Infrastructure Design Principles](#infrastructure-design-principles)
3. [Cloud-Native Architecture](#cloud-native-architecture)
4. [Monolith vs Microservices](#monolith-vs-microservices)
5. [Environment Strategies](#environment-strategies)
6. [Security and Compliance](#security-and-compliance)
7. [Monitoring and Observability Strategy](#monitoring-and-observability-strategy)

## 🔄 DevOps Lifecycle Overview

### The DevOps Infinity Loop

```
    Plan → Code → Build → Test
    ↑                         ↓
Monitor ←── Deploy ←── Release ←── 
```

### 1. **Plan** 📋
- **Requirements gathering** and user story creation
- **Sprint planning** and backlog management
- **Architecture decisions** and technical design
- **Risk assessment** and mitigation strategies

**Tools**: Jira, Azure DevOps, GitHub Projects, Trello

### 2. **Code** 💻
- **Version control** with branching strategies
- **Code reviews** and collaborative development
- **Code quality** standards and linting
- **Documentation** and knowledge sharing

**Tools**: Git, GitHub, GitLab, Bitbucket, VS Code

### 3. **Build** 🔨
- **Continuous Integration** automation
- **Artifact creation** and dependency management
- **Code compilation** and package creation
- **Quality gates** and automated testing

**Tools**: Jenkins, GitHub Actions, GitLab CI, Azure Pipelines

### 4. **Test** 🧪
- **Unit testing** and code coverage
- **Integration testing** across services
- **Security scanning** and vulnerability assessment
- **Performance testing** and load validation

**Tools**: JUnit, PyTest, Selenium, SonarQube, OWASP ZAP

### 5. **Release** 🚀
- **Deployment automation** and rollback strategies
- **Configuration management** across environments
- **Database migrations** and schema updates
- **Blue-green deployments** and canary releases

**Tools**: ArgoCD, Spinnaker, Helm, Terraform, Ansible

### 6. **Deploy** 🌐
- **Infrastructure provisioning** and scaling
- **Container orchestration** and service mesh
- **Load balancing** and traffic management
- **SSL/TLS termination** and security policies

**Tools**: Kubernetes, Docker, Istio, NGINX, AWS ALB

### 7. **Monitor** 📊
- **Application performance** monitoring (APM)
- **Infrastructure metrics** and alerting
- **Log aggregation** and analysis
- **User experience** tracking and analytics

**Tools**: Prometheus, Grafana, ELK Stack, New Relic, DataDog

## 🏗️ Infrastructure Design Principles

### 1. **Immutable Infrastructure**
```yaml
# Example: Immutable server deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  template:
    spec:
      containers:
      - name: app
        image: myapp:v1.2.3  # Never modify, always replace
        ports:
        - containerPort: 8080
```

**Benefits**:
- Consistent deployments across environments
- Easier rollbacks and disaster recovery
- Reduced configuration drift
- Enhanced security through ephemeral instances

### 2. **Infrastructure as Code (IaC)**
```hcl
# Terraform example
resource "aws_instance" "web_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  
  vpc_security_group_ids = [aws_security_group.web.id]
  subnet_id              = aws_subnet.public.id
  
  user_data = templatefile("${path.module}/user_data.sh", {
    app_version = var.app_version
    environment = var.environment
  })
  
  tags = {
    Name        = "${var.project_name}-web-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}
```

**Key Principles**:
- **Version Control**: All infrastructure code in Git
- **Idempotency**: Same result regardless of execution count
- **Modularity**: Reusable components and modules
- **Documentation**: Self-documenting infrastructure

### 3. **Scalability Patterns**

#### Horizontal Scaling
```yaml
# Kubernetes HPA example
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

#### Load Balancing Strategies
- **Round Robin**: Equal distribution of requests
- **Weighted Round Robin**: Based on server capacity
- **Least Connections**: Route to server with fewest active connections
- **Geographic**: Route based on user location

### 4. **High Availability Design**

```yaml
# Multi-AZ deployment example
apiVersion: v1
kind: Service
metadata:
  name: web-app-service
spec:
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 8080
  type: LoadBalancer
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 6
  template:
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - web-app
              topologyKey: kubernetes.io/zone
```

**HA Components**:
- **Multi-region deployment** for disaster recovery
- **Load balancers** with health checks
- **Database replication** with automatic failover
- **Circuit breakers** for fault tolerance

## ☁️ Cloud-Native Architecture

### 12-Factor App Principles

1. **Codebase**: One codebase tracked in revision control
2. **Dependencies**: Explicitly declare and isolate dependencies
3. **Config**: Store config in the environment
4. **Backing Services**: Treat backing services as attached resources
5. **Build, Release, Run**: Strictly separate build and run stages
6. **Processes**: Execute the app as one or more stateless processes
7. **Port Binding**: Export services via port binding
8. **Concurrency**: Scale out via the process model
9. **Disposability**: Maximize robustness with fast startup and graceful shutdown
10. **Dev/Prod Parity**: Keep development, staging, and production as similar as possible
11. **Logs**: Treat logs as event streams
12. **Admin Processes**: Run admin/management tasks as one-off processes

### Cloud-Native Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Cloud-Native Architecture                │
├─────────────────────────────────────────────────────────────┤
│  Frontend (React/Angular)                                   │
│  ├── CDN (CloudFront/CloudFlare)                           │
│  ├── Load Balancer (ALB/NGINX)                             │
│  └── Static Assets (S3/GCS)                                │
├─────────────────────────────────────────────────────────────┤
│  API Gateway                                                │
│  ├── Authentication (OAuth2/JWT)                           │
│  ├── Rate Limiting                                         │
│  ├── Request Routing                                       │
│  └── SSL Termination                                       │
├─────────────────────────────────────────────────────────────┤
│  Microservices (Kubernetes)                                │
│  ├── User Service                                          │
│  ├── Product Service                                       │
│  ├── Order Service                                         │
│  ├── Payment Service                                       │
│  └── Notification Service                                  │
├─────────────────────────────────────────────────────────────┤
│  Data Layer                                                 │
│  ├── Databases (PostgreSQL/MongoDB)                        │
│  ├── Cache (Redis/Memcached)                              │
│  ├── Message Queue (RabbitMQ/Kafka)                       │
│  └── Object Storage (S3/GCS)                              │
├─────────────────────────────────────────────────────────────┤
│  Observability                                              │
│  ├── Monitoring (Prometheus/Grafana)                       │
│  ├── Logging (ELK Stack)                                   │
│  ├── Tracing (Jaeger/Zipkin)                              │
│  └── Alerting (PagerDuty/Slack)                           │
└─────────────────────────────────────────────────────────────┘
```

### Container Strategy

```dockerfile
# Multi-stage Dockerfile example
FROM node:16-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:16-alpine AS runtime
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001
WORKDIR /app
COPY --from=builder --chown=nextjs:nodejs /app/node_modules ./node_modules
COPY --chown=nextjs:nodejs . .
USER nextjs
EXPOSE 3000
CMD ["npm", "start"]
```

**Container Best Practices**:
- **Minimal base images** (Alpine Linux)
- **Multi-stage builds** for smaller images
- **Non-root users** for security
- **Health checks** for container orchestration
- **Resource limits** for stability

## 🏢 Monolith vs Microservices

### Monolithic Architecture

```
┌─────────────────────────────────────┐
│           Monolithic App            │
├─────────────────────────────────────┤
│  ┌─────────────────────────────────┐ │
│  │         User Interface          │ │
│  └─────────────────────────────────┘ │
│  ┌─────────────────────────────────┐ │
│  │       Business Logic           │ │
│  │  ├── User Management           │ │
│  │  ├── Product Catalog           │ │
│  │  ├── Order Processing          │ │
│  │  └── Payment Processing        │ │
│  └─────────────────────────────────┘ │
│  ┌─────────────────────────────────┐ │
│  │         Data Access             │ │
│  └─────────────────────────────────┘ │
└─────────────────────────────────────┘
           │
           ▼
    ┌─────────────┐
    │  Database   │
    └─────────────┘
```

**Pros**:
- Simple to develop, test, and deploy
- Easy to scale horizontally by running multiple copies
- Simplified monitoring and debugging
- Better performance due to in-process calls

**Cons**:
- Large codebase becomes difficult to understand
- Technology stack lock-in
- Scaling challenges for individual components
- Deployment of small changes requires full application deployment

### Microservices Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  Frontend Applications                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  Web App    │  │ Mobile App  │  │   Admin     │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      API Gateway                           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     Microservices                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │    User     │  │   Product   │  │    Order    │         │
│  │   Service   │  │   Service   │  │   Service   │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
│         │                 │                 │              │
│         ▼                 ▼                 ▼              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │   User DB   │  │ Product DB  │  │  Order DB   │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

**Pros**:
- Technology diversity and flexibility
- Independent deployment and scaling
- Improved fault isolation
- Better team autonomy and ownership

**Cons**:
- Increased complexity in distributed systems
- Network communication overhead
- Data consistency challenges
- Monitoring and debugging complexity

### Migration Strategy: Strangler Fig Pattern

```yaml
# Gradual migration approach
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: product-service-migration
spec:
  http:
  - match:
    - headers:
        x-migration:
          exact: "v2"
    route:
    - destination:
        host: product-service-v2
        port:
          number: 8080
      weight: 100
  - route:
    - destination:
        host: monolith-app
        port:
          number: 8080
      weight: 90
    - destination:
        host: product-service-v2
        port:
          number: 8080
      weight: 10
```

## 🌍 Environment Strategies

### Environment Separation

```
┌─────────────────────────────────────────────────────────────┐
│                    Environment Pipeline                     │
├─────────────────────────────────────────────────────────────┤
│  Development                                                │
│  ├── Feature branches                                       │
│  ├── Unit tests                                            │
│  ├── Local development                                     │
│  └── Rapid iteration                                       │
│                        │                                    │
│                        ▼                                    │
├─────────────────────────────────────────────────────────────┤
│  Staging/Testing                                            │
│  ├── Integration tests                                      │
│  ├── Performance tests                                     │
│  ├── Security scans                                        │
│  └── User acceptance testing                               │
│                        │                                    │
│                        ▼                                    │
├─────────────────────────────────────────────────────────────┤
│  Production                                                 │
│  ├── Blue-green deployment                                 │
│  ├── Canary releases                                       │
│  ├── Monitoring & alerting                                 │
│  └── Disaster recovery                                     │
└─────────────────────────────────────────────────────────────┘
```

### Environment Configuration

```yaml
# Kubernetes ConfigMap for environment separation
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config-dev
  namespace: development
data:
  DATABASE_URL: "postgresql://dev-db:5432/ecommerce_dev"
  REDIS_URL: "redis://dev-redis:6379"
  LOG_LEVEL: "DEBUG"
  ENABLE_DEBUG: "true"
  ENVIRONMENT: "development"
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config-prod
  namespace: production
data:
  DATABASE_URL: "postgresql://prod-db:5432/ecommerce_prod"
  REDIS_URL: "redis://prod-redis:6379"
  LOG_LEVEL: "INFO"
  ENABLE_DEBUG: "false"
  ENVIRONMENT: "production"
```

### Deployment Strategies

#### 1. Rolling Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 6
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  template:
    spec:
      containers:
      - name: app
        image: myapp:v1.2.3
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
```

#### 2. Blue-Green Deployment
```bash
#!/bin/bash
# Blue-Green deployment script
CURRENT_ENV=$(kubectl get service web-app -o jsonpath='{.spec.selector.version}')
NEW_ENV=$([[ $CURRENT_ENV == "blue" ]] && echo "green" || echo "blue")

# Deploy new version
kubectl set image deployment/web-app-$NEW_ENV app=myapp:$NEW_VERSION

# Wait for rollout
kubectl rollout status deployment/web-app-$NEW_ENV

# Switch traffic
kubectl patch service web-app -p '{"spec":{"selector":{"version":"'$NEW_ENV'"}}}'

echo "Traffic switched to $NEW_ENV environment"
```

#### 3. Canary Deployment
```yaml
# Istio Virtual Service for canary deployment
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: web-app-canary
spec:
  http:
  - match:
    - headers:
        x-canary:
          exact: "true"
    route:
    - destination:
        host: web-app
        subset: v2
  - route:
    - destination:
        host: web-app
        subset: v1
      weight: 95
    - destination:
        host: web-app
        subset: v2
      weight: 5
```

## 🔒 Security and Compliance

### Security by Design

```yaml
# Security-focused deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-app
spec:
  template:
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 2000
      containers:
      - name: app
        image: myapp:latest
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
        resources:
          limits:
            memory: "512Mi"
            cpu: "500m"
          requests:
            memory: "256Mi"
            cpu: "250m"
        volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: cache
          mountPath: /app/cache
      volumes:
      - name: tmp
        emptyDir: {}
      - name: cache
        emptyDir: {}
```

### Network Security
```yaml
# Network Policy example
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: web-app-netpol
spec:
  podSelector:
    matchLabels:
      app: web-app
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: load-balancer
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - protocol: TCP
      port: 5432
```

### Secrets Management
```yaml
# Kubernetes Secret with external secret operator
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: app-secrets
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: app-secrets
    creationPolicy: Owner
  data:
  - secretKey: database-password
    remoteRef:
      key: secret/database
      property: password
  - secretKey: api-key
    remoteRef:
      key: secret/api
      property: key
```

## 📊 Monitoring and Observability Strategy

### The Three Pillars of Observability

#### 1. Metrics (Prometheus + Grafana)
```yaml
# Prometheus ServiceMonitor
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: web-app-metrics
spec:
  selector:
    matchLabels:
      app: web-app
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
```

#### 2. Logs (ELK Stack)
```yaml
# Filebeat configuration
filebeat.inputs:
- type: container
  paths:
    - /var/log/containers/*web-app*.log
  processors:
  - add_kubernetes_metadata:
      host: ${NODE_NAME}
      matchers:
      - logs_path:
          logs_path: "/var/log/containers/"

output.elasticsearch:
  hosts: ["elasticsearch:9200"]
  index: "web-app-logs-%{+yyyy.MM.dd}"
```

#### 3. Traces (Jaeger)
```python
# Application tracing example
from opentelemetry import trace
from opentelemetry.exporter.jaeger.thrift import JaegerExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

trace.set_tracer_provider(TracerProvider())
tracer = trace.get_tracer(__name__)

jaeger_exporter = JaegerExporter(
    agent_host_name="jaeger-agent",
    agent_port=6831,
)

span_processor = BatchSpanProcessor(jaeger_exporter)
trace.get_tracer_provider().add_span_processor(span_processor)

@app.route('/api/products')
def get_products():
    with tracer.start_as_current_span("get_products") as span:
        span.set_attribute("http.method", "GET")
        span.set_attribute("http.url", "/api/products")
        
        # Your application logic here
        products = fetch_products_from_db()
        
        span.set_attribute("products.count", len(products))
        return jsonify(products)
```

### SLA/SLO/SLI Framework

```yaml
# Service Level Objectives
apiVersion: sloth.slok.dev/v1
kind: PrometheusServiceLevel
metadata:
  name: web-app-slo
spec:
  service: "web-app"
  labels:
    team: "platform"
  slos:
  - name: "requests-availability"
    objective: 99.9
    description: "99.9% of requests should be successful"
    sli:
      events:
        error_query: sum(rate(http_requests_total{job="web-app",code=~"5.."}[5m]))
        total_query: sum(rate(http_requests_total{job="web-app"}[5m]))
    alerting:
      name: WebAppHighErrorRate
      labels:
        severity: page
        team: platform
```

## 📝 Best Practices Summary

### Development
- ✅ Use version control for everything (code, infrastructure, documentation)
- ✅ Implement code reviews and pair programming
- ✅ Write comprehensive tests (unit, integration, e2e)
- ✅ Follow coding standards and use automated linting

### Operations
- ✅ Automate everything possible
- ✅ Monitor all the things
- ✅ Plan for failure and disaster recovery
- ✅ Implement proper backup and restore procedures

### Security
- ✅ Apply security by design principles
- ✅ Use least privilege access
- ✅ Implement proper secrets management
- ✅ Regular security audits and updates

### Culture
- ✅ Foster collaboration between Dev and Ops
- ✅ Encourage continuous learning and improvement
- ✅ Blame-free post-mortems
- ✅ Share knowledge and document everything

---

**Next**: Move to `02_Tools_Practice/` to start hands-on labs with specific tools.
