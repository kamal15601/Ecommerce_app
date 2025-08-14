# ArgoCD - GitOps Continuous Delivery

## Overview
ArgoCD is a declarative, GitOps continuous delivery tool for Kubernetes. It follows the GitOps pattern of using Git repositories as the source of truth for defining the desired application state.

## Learning Objectives
- Master GitOps principles and patterns
- Deploy and configure ArgoCD
- Implement application deployment workflows
- Manage multiple environments with ArgoCD
- Integrate ArgoCD with CI/CD pipelines
- Implement security best practices
- Scale ArgoCD for enterprise environments

## Prerequisites
- Kubernetes cluster (local or cloud)
- kubectl installed and configured
- Basic Git knowledge
- Understanding of Kubernetes manifests
- Helm knowledge (recommended)

---

## Lab 1: ArgoCD Installation and Setup

### Objective
Install ArgoCD on Kubernetes and perform initial configuration.

### Steps

1. **Install ArgoCD**
```bash
# Create namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods to be ready
kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd
```

2. **Access ArgoCD UI**
```bash
# Port forward to access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

3. **Install ArgoCD CLI**
```bash
# Linux
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd

# macOS
brew install argocd

# Windows
choco install argocd-cli
```

4. **Login with CLI**
```bash
# Login
argocd login localhost:8080

# Change password
argocd account update-password
```

### Exercise
- Install ArgoCD on your Kubernetes cluster
- Access the UI and explore the interface
- Login with CLI and change the admin password

---

## Lab 2: Creating Your First Application

### Objective
Deploy a simple application using ArgoCD with Git repository.

### Steps

1. **Prepare Git Repository**
```yaml
# k8s-manifests/guestbook/guestbook-ui-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: guestbook-ui
spec:
  replicas: 1
  revisionHistoryLimit: 3
  selector:
    matchLabels:
      app: guestbook-ui
  template:
    metadata:
      labels:
        app: guestbook-ui
    spec:
      containers:
      - image: gcr.io/heptio-images/ks-guestbook-demo:0.2
        name: guestbook-ui
        ports:
        - containerPort: 80

---
apiVersion: v1
kind: Service
metadata:
  name: guestbook-ui
spec:
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: guestbook-ui
  type: LoadBalancer
```

2. **Create Application via CLI**
```bash
argocd app create guestbook \
  --repo https://github.com/yourusername/argocd-example-apps.git \
  --path guestbook \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default
```

3. **Create Application via YAML**
```yaml
# application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: guestbook
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/yourusername/argocd-example-apps.git
    targetRevision: HEAD
    path: guestbook
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

4. **Deploy Application**
```bash
kubectl apply -f application.yaml

# Or via CLI
argocd app sync guestbook
```

### Exercise
- Create a Git repository with Kubernetes manifests
- Deploy an application using ArgoCD
- Make changes to the repository and observe sync behavior

---

## Lab 3: GitOps Workflow Implementation

### Objective
Implement a complete GitOps workflow with multiple environments.

### Steps

1. **Repository Structure**
```
gitops-repo/
├── apps/
│   ├── dev/
│   │   ├── app1/
│   │   └── app2/
│   ├── staging/
│   │   ├── app1/
│   │   └── app2/
│   └── production/
│       ├── app1/
│       └── app2/
├── infrastructure/
│   ├── base/
│   └── overlays/
│       ├── dev/
│       ├── staging/
│       └── production/
└── argocd/
    ├── applications/
    └── projects/
```

2. **Environment-Specific Configuration**
```yaml
# apps/dev/app1/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- ../../../base/app1

patchesStrategicMerge:
- deployment-patch.yaml

images:
- name: myapp
  newTag: dev-latest

replicas:
- name: myapp-deployment
  count: 1
```

3. **Application Sets for Multiple Environments**
```yaml
# applicationset.yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: multi-env-apps
  namespace: argocd
spec:
  generators:
  - clusters:
      selector:
        matchLabels:
          environment: development
  - clusters:
      selector:
        matchLabels:
          environment: staging
  - clusters:
      selector:
        matchLabels:
          environment: production
  template:
    metadata:
      name: '{{name}}-myapp'
    spec:
      project: default
      source:
        repoURL: https://github.com/yourorg/gitops-repo.git
        targetRevision: HEAD
        path: 'apps/{{metadata.labels.environment}}/myapp'
      destination:
        server: '{{server}}'
        namespace: myapp
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
        - CreateNamespace=true
```

4. **Projects for Tenant Isolation**
```yaml
# argocd-project.yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: team-alpha
  namespace: argocd
spec:
  description: Team Alpha's applications
  sourceRepos:
  - 'https://github.com/yourorg/team-alpha-*'
  destinations:
  - namespace: 'team-alpha-*'
    server: https://kubernetes.default.svc
  clusterResourceWhitelist:
  - group: ''
    kind: Namespace
  namespaceResourceWhitelist:
  - group: apps
    kind: Deployment
  - group: ''
    kind: Service
  - group: ''
    kind: ConfigMap
  - group: ''
    kind: Secret
  roles:
  - name: team-alpha-admin
    policies:
    - p, proj:team-alpha:team-alpha-admin, applications, *, team-alpha/*, allow
    groups:
    - team-alpha-admins
```

### Exercise
- Set up multi-environment repository structure
- Implement ApplicationSets for environment management
- Create projects for team isolation

---

## Lab 4: Advanced Sync Policies and Hooks

### Objective
Configure advanced synchronization policies and deployment hooks.

### Steps

1. **Sync Policies Configuration**
```yaml
# application-with-sync-policy.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: advanced-sync-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/yourorg/app-repo.git
    targetRevision: HEAD
    path: manifests
  destination:
    server: https://kubernetes.default.svc
    namespace: myapp
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
    - CreateNamespace=true
    - PrunePropagationPolicy=foreground
    - PruneLast=true
    - RespectIgnoreDifferences=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
  ignoreDifferences:
  - group: apps
    kind: Deployment
    jsonPointers:
    - /spec/replicas
```

2. **Pre-Sync Hooks**
```yaml
# pre-sync-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: database-migration
  annotations:
    argocd.argoproj.io/hook: PreSync
    argocd.argoproj.io/hook-weight: "1"
    argocd.argoproj.io/sync-wave: "1"
spec:
  template:
    spec:
      containers:
      - name: migrate
        image: myapp:latest
        command: ["python", "manage.py", "migrate"]
      restartPolicy: OnFailure
  backoffLimit: 3
```

3. **Post-Sync Hooks**
```yaml
# post-sync-test.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: smoke-tests
  annotations:
    argocd.argoproj.io/hook: PostSync
    argocd.argoproj.io/hook-weight: "2"
    argocd.argoproj.io/sync-wave: "2"
    argocd.argoproj.io/hook-delete-policy: HookSucceeded
spec:
  template:
    spec:
      containers:
      - name: test
        image: myapp:latest
        command: ["pytest", "tests/smoke/"]
      restartPolicy: OnFailure
  backoffLimit: 1
```

4. **Sync Waves**
```yaml
# database.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: database
  annotations:
    argocd.argoproj.io/sync-wave: "1"
spec:
  # ... database deployment spec

---
# application.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: application
  annotations:
    argocd.argoproj.io/sync-wave: "2"
spec:
  # ... application deployment spec

---
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    argocd.argoproj.io/sync-wave: "3"
spec:
  # ... ingress spec
```

### Exercise
- Implement database migration hooks
- Create smoke tests as post-sync hooks
- Use sync waves for ordered deployment

---

## Lab 5: Helm Chart Management

### Objective
Deploy and manage Helm charts with ArgoCD.

### Steps

1. **Helm Application Configuration**
```yaml
# helm-application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: helm-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://charts.helm.sh/stable
    chart: nginx-ingress
    targetRevision: 1.41.3
    helm:
      parameters:
      - name: controller.service.type
        value: LoadBalancer
      - name: controller.service.externalIPs[0]
        value: 192.168.1.100
      valueFiles:
      - values-production.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: ingress-nginx
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

2. **Custom Helm Chart**
```yaml
# Chart.yaml
apiVersion: v2
name: myapp
description: A Helm chart for MyApp
type: application
version: 0.1.0
appVersion: "1.0"

dependencies:
- name: postgresql
  version: 11.6.12
  repository: https://charts.bitnami.com/bitnami
  condition: postgresql.enabled
- name: redis
  version: 16.13.2
  repository: https://charts.bitnami.com/bitnami
  condition: redis.enabled
```

3. **Values Files for Environments**
```yaml
# values-dev.yaml
replicaCount: 1
image:
  tag: dev-latest
ingress:
  enabled: false
postgresql:
  enabled: true
  auth:
    database: myapp_dev
redis:
  enabled: true

# values-prod.yaml
replicaCount: 3
image:
  tag: v1.2.3
ingress:
  enabled: true
  hosts:
  - host: myapp.production.com
    paths:
    - path: /
postgresql:
  enabled: false
redis:
  enabled: true
  architecture: replication
```

4. **ApplicationSet for Helm Charts**
```yaml
# helm-applicationset.yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: helm-apps
  namespace: argocd
spec:
  generators:
  - git:
      repoURL: https://github.com/yourorg/helm-charts.git
      revision: HEAD
      directories:
      - path: charts/*
  template:
    metadata:
      name: '{{path.basename}}'
    spec:
      project: default
      source:
        repoURL: https://github.com/yourorg/helm-charts.git
        targetRevision: HEAD
        path: '{{path}}'
        helm:
          valueFiles:
          - values.yaml
          - values-{{metadata.labels.environment}}.yaml
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{path.basename}}'
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
```

### Exercise
- Deploy applications using Helm charts
- Create custom Helm charts with dependencies
- Implement environment-specific value files

---

## Lab 6: Multi-Cluster Management

### Objective
Configure ArgoCD to manage multiple Kubernetes clusters.

### Steps

1. **Add External Clusters**
```bash
# List current clusters
argocd cluster list

# Add cluster
argocd cluster add staging-cluster --name staging

# Add cluster with custom config
argocd cluster add production-cluster \
  --name production \
  --server-addr https://prod-k8s-api.company.com \
  --insecure
```

2. **Cluster Configuration**
```yaml
# cluster-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: staging-cluster-secret
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: cluster
type: Opaque
stringData:
  name: staging
  server: https://staging-k8s-api.company.com
  config: |
    {
      "bearerToken": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
      "tlsClientConfig": {
        "insecure": false,
        "caData": "LS0tLS1CRUdJTi..."
      }
    }
```

3. **Cluster-Specific Applications**
```yaml
# multi-cluster-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app-staging
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/yourorg/app-config.git
    targetRevision: staging
    path: k8s-manifests
  destination:
    server: https://staging-k8s-api.company.com
    namespace: myapp
  syncPolicy:
    automated:
      prune: true
      selfHeal: true

---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app-production
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/yourorg/app-config.git
    targetRevision: main
    path: k8s-manifests
  destination:
    server: https://production-k8s-api.company.com
    namespace: myapp
  syncPolicy:
    automated: null  # Manual sync for production
```

4. **ApplicationSet with Cluster Generator**
```yaml
# cluster-applicationset.yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: cluster-apps
  namespace: argocd
spec:
  generators:
  - clusters:
      selector:
        matchLabels:
          environment: staging
  - clusters:
      selector:
        matchLabels:
          environment: production
  template:
    metadata:
      name: '{{name}}-monitoring'
    spec:
      project: default
      source:
        repoURL: https://github.com/yourorg/monitoring-config.git
        targetRevision: HEAD
        path: '{{metadata.labels.environment}}'
      destination:
        server: '{{server}}'
        namespace: monitoring
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
```

### Exercise
- Add multiple clusters to ArgoCD
- Deploy applications across different clusters
- Implement cluster-specific configurations

---

## Lab 7: Security and RBAC

### Objective
Implement security best practices and role-based access control.

### Steps

1. **RBAC Configuration**
```yaml
# argocd-rbac-cm.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-rbac-cm
  namespace: argocd
data:
  policy.default: role:readonly
  policy.csv: |
    # Admin policy
    p, role:admin, applications, *, */*, allow
    p, role:admin, clusters, *, *, allow
    p, role:admin, repositories, *, *, allow
    
    # Developer policy
    p, role:developer, applications, get, */*, allow
    p, role:developer, applications, sync, */*, allow
    p, role:developer, applications, action/*, */*, allow
    p, role:developer, logs, get, */*, allow
    
    # Team specific policies
    p, role:team-alpha, applications, *, team-alpha/*, allow
    p, role:team-beta, applications, *, team-beta/*, allow
    
    # Group mappings
    g, company-admins, role:admin
    g, team-alpha-devs, role:team-alpha
    g, team-beta-devs, role:team-beta
```

2. **OIDC Integration**
```yaml
# argocd-cm.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  namespace: argocd
data:
  url: https://argocd.company.com
  
  # OIDC configuration
  oidc.config: |
    name: Company SSO
    issuer: https://company.okta.com
    clientId: argocd-client-id
    clientSecret: $oidc.company.clientSecret
    requestedScopes: ["openid", "profile", "email", "groups"]
    requestedIDTokenClaims: {"groups": {"essential": true}}
  
  # Dex configuration (alternative)
  dex.config: |
    connectors:
    - type: ldap
      name: Company LDAP
      id: ldap
      config:
        host: ldap.company.com:636
        insecureNoSSL: false
        bindDN: cn=argocd,ou=services,dc=company,dc=com
        bindPW: $dex.ldap.bindPW
        usernamePrompt: Email Address
        userSearch:
          baseDN: ou=users,dc=company,dc=com
          filter: "(objectClass=person)"
          username: mail
          idAttr: DN
          emailAttr: mail
          nameAttr: cn
        groupSearch:
          baseDN: ou=groups,dc=company,dc=com
          filter: "(objectClass=groupOfNames)"
          userAttr: DN
          groupAttr: member
          nameAttr: cn
```

3. **Application-Level RBAC**
```yaml
# team-project.yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: team-alpha
  namespace: argocd
spec:
  description: Team Alpha Project
  sourceRepos:
  - 'https://github.com/company/team-alpha-*'
  destinations:
  - namespace: 'team-alpha-*'
    server: https://kubernetes.default.svc
  clusterResourceWhitelist:
  - group: ''
    kind: Namespace
  namespaceResourceBlacklist:
  - group: ''
    kind: ResourceQuota
  - group: ''
    kind: LimitRange
  roles:
  - name: team-alpha-admin
    policies:
    - p, proj:team-alpha:team-alpha-admin, applications, *, team-alpha/*, allow
    - p, proj:team-alpha:team-alpha-admin, repositories, *, team-alpha/*, allow
    groups:
    - company:team-alpha-admins
  - name: team-alpha-dev
    policies:
    - p, proj:team-alpha:team-alpha-dev, applications, get, team-alpha/*, allow
    - p, proj:team-alpha:team-alpha-dev, applications, sync, team-alpha/*, allow
    groups:
    - company:team-alpha-developers
```

4. **Secrets Management**
```yaml
# sealed-secret-example.yaml
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: database-credentials
  namespace: myapp
spec:
  encryptedData:
    username: AgBy3i4OJSWK+PiTySYZZA9rO43cGDEQAx...
    password: AiAGewhDWH6afdfds7U+Yj2FD4+gXiJGNwU...
  template:
    metadata:
      name: database-credentials
      namespace: myapp
    type: Opaque
```

### Exercise
- Configure RBAC for different user roles
- Integrate with your organization's SSO
- Implement secrets management with sealed secrets

---

## Lab 8: Monitoring and Observability

### Objective
Implement comprehensive monitoring and observability for ArgoCD.

### Steps

1. **Prometheus Monitoring Setup**
```yaml
# argocd-metrics.yaml
apiVersion: v1
kind: Service
metadata:
  name: argocd-metrics
  namespace: argocd
  labels:
    app.kubernetes.io/component: metrics
    app.kubernetes.io/name: argocd-metrics
    app.kubernetes.io/part-of: argocd
spec:
  ports:
  - name: metrics
    port: 8082
    protocol: TCP
    targetPort: 8082
  selector:
    app.kubernetes.io/name: argocd-application-controller

---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: argocd-metrics
  namespace: argocd
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: argocd-metrics
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
```

2. **Grafana Dashboard Configuration**
```json
{
  "dashboard": {
    "title": "ArgoCD Overview",
    "panels": [
      {
        "title": "Application Health",
        "type": "stat",
        "targets": [
          {
            "expr": "argocd_app_health_status",
            "legendFormat": "{{name}} - {{health_status}}"
          }
        ]
      },
      {
        "title": "Sync Status",
        "type": "stat",
        "targets": [
          {
            "expr": "argocd_app_sync_total",
            "legendFormat": "{{name}} - {{phase}}"
          }
        ]
      },
      {
        "title": "Repository Errors",
        "type": "graph",
        "targets": [
          {
            "expr": "argocd_git_request_duration_seconds",
            "legendFormat": "{{repo}} - {{request_type}}"
          }
        ]
      }
    ]
  }
}
```

3. **Alerting Rules**
```yaml
# argocd-alerts.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: argocd-alerts
  namespace: argocd
spec:
  groups:
  - name: argocd
    rules:
    - alert: ArgoCDAppUnhealthy
      expr: argocd_app_health_status{health_status!="Healthy"} == 1
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "ArgoCD application {{ $labels.name }} is unhealthy"
        description: "Application {{ $labels.name }} has been in {{ $labels.health_status }} state for more than 5 minutes"
    
    - alert: ArgoCDAppOutOfSync
      expr: argocd_app_sync_status{sync_status!="Synced"} == 1
      for: 10m
      labels:
        severity: warning
      annotations:
        summary: "ArgoCD application {{ $labels.name }} is out of sync"
        description: "Application {{ $labels.name }} has been {{ $labels.sync_status }} for more than 10 minutes"
    
    - alert: ArgoCDSyncFailure
      expr: increase(argocd_app_sync_total{phase="Failed"}[5m]) > 0
      labels:
        severity: critical
      annotations:
        summary: "ArgoCD sync failure for {{ $labels.name }}"
        description: "Application {{ $labels.name }} sync has failed"
```

4. **Logging Configuration**
```yaml
# argocd-cm.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cmd-params-cm
  namespace: argocd
data:
  # Enable structured logging
  application.instanceLabelKey: argocd.argoproj.io/instance
  server.insecure: "false"
  server.log.level: "info"
  server.log.format: "json"
  
  # Enable metrics
  controller.metrics.enabled: "true"
  server.metrics.enabled: "true"
  reposerver.metrics.enabled: "true"
```

### Exercise
- Set up Prometheus monitoring for ArgoCD
- Create custom Grafana dashboards
- Configure alerting for application health and sync status

---

## Lab 9: ArgoCD Image Updater

### Objective
Implement automated image updates using ArgoCD Image Updater.

### Steps

1. **Install ArgoCD Image Updater**
```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj-labs/argocd-image-updater/stable/manifests/install.yaml
```

2. **Configure Image Updater**
```yaml
# argocd-image-updater-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-image-updater-config
  namespace: argocd
data:
  registries.conf: |
    registries:
    - name: Docker Hub
      prefix: docker.io
      api_url: https://registry-1.docker.io
      credentials: pullsecret:argocd/dockerhub-secret
    - name: ECR
      prefix: 123456789.dkr.ecr.us-west-2.amazonaws.com
      api_url: https://123456789.dkr.ecr.us-west-2.amazonaws.com
      credentials: ext:/scripts/ecr-login.sh
  git.yaml: |
    git:
      user: argocd-image-updater
      email: argocd-image-updater@company.com
      signingKey: /app/config/gpg/private.key
```

3. **Application with Image Update Annotations**
```yaml
# auto-update-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: auto-update-app
  namespace: argocd
  annotations:
    argocd-image-updater.argoproj.io/image-list: myapp=myregistry/myapp
    argocd-image-updater.argoproj.io/myapp.update-strategy: latest
    argocd-image-updater.argoproj.io/myapp.allow-tags: regexp:^v[0-9]+\.[0-9]+\.[0-9]+$
    argocd-image-updater.argoproj.io/write-back-method: git
    argocd-image-updater.argoproj.io/git-branch: image-updates
spec:
  project: default
  source:
    repoURL: https://github.com/yourorg/app-manifests.git
    targetRevision: HEAD
    path: overlays/production
  destination:
    server: https://kubernetes.default.svc
    namespace: myapp
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

4. **Kustomize Integration**
```yaml
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- ../../base

images:
- name: myapp
  newTag: v1.2.3  # This will be updated by image updater

patchesStrategicMerge:
- deployment-patch.yaml
```

### Exercise
- Set up ArgoCD Image Updater
- Configure automatic image updates for your applications
- Implement tag filtering and update strategies

---

## Lab 10: Advanced ArgoCD Patterns

### Objective
Implement advanced ArgoCD patterns for enterprise environments.

### Steps

1. **App of Apps Pattern**
```yaml
# app-of-apps.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app-of-apps
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/yourorg/argocd-apps.git
    targetRevision: HEAD
    path: applications
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true

# applications/team-alpha-apps.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: team-alpha-frontend
  namespace: argocd
spec:
  project: team-alpha
  source:
    repoURL: https://github.com/yourorg/frontend-app.git
    targetRevision: HEAD
    path: k8s
  destination:
    server: https://kubernetes.default.svc
    namespace: team-alpha-frontend

---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: team-alpha-backend
  namespace: argocd
spec:
  project: team-alpha
  source:
    repoURL: https://github.com/yourorg/backend-app.git
    targetRevision: HEAD
    path: k8s
  destination:
    server: https://kubernetes.default.svc
    namespace: team-alpha-backend
```

2. **Blue-Green Deployment with ArgoCD**
```yaml
# blue-green-rollout.yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: myapp-rollout
spec:
  replicas: 5
  strategy:
    blueGreen:
      activeService: myapp-active
      previewService: myapp-preview
      autoPromotionEnabled: false
      scaleDownDelaySeconds: 30
      prePromotionAnalysis:
        templates:
        - templateName: success-rate
        args:
        - name: service-name
          value: myapp-preview
      postPromotionAnalysis:
        templates:
        - templateName: success-rate
        args:
        - name: service-name
          value: myapp-active
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: myapp:latest
        ports:
        - containerPort: 8080
```

3. **Progressive Delivery with Argo Rollouts**
```yaml
# canary-rollout.yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: myapp-canary
spec:
  replicas: 10
  strategy:
    canary:
      canaryService: myapp-canary
      stableService: myapp-stable
      trafficRouting:
        istio:
          virtualService:
            name: myapp-vs
      steps:
      - setWeight: 20
      - pause: {duration: 5m}
      - setWeight: 40
      - pause: {duration: 10m}
      - setWeight: 60
      - pause: {duration: 10m}
      - setWeight: 80
      - pause: {duration: 10m}
      analysis:
        templates:
        - templateName: success-rate
        startingStep: 2
        args:
        - name: service-name
          value: myapp-canary
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: myapp:latest
```

4. **Cross-Cluster Application Promotion**
```bash
#!/bin/bash
# promote-to-production.sh

APP_NAME=$1
DEV_CLUSTER="dev-cluster"
STAGING_CLUSTER="staging-cluster"
PROD_CLUSTER="prod-cluster"

# Get current image from staging
CURRENT_IMAGE=$(argocd app get $APP_NAME-staging --cluster $STAGING_CLUSTER -o json | jq -r '.status.summary.images[0]')

# Update production manifests
git clone https://github.com/yourorg/gitops-repo.git
cd gitops-repo

# Update production kustomization
sed -i "s|newTag:.*|newTag: ${CURRENT_IMAGE##*:}|" apps/production/$APP_NAME/kustomization.yaml

# Commit and push
git add .
git commit -m "Promote $APP_NAME to production: $CURRENT_IMAGE"
git push origin main

# Trigger sync
argocd app sync $APP_NAME-production --cluster $PROD_CLUSTER
```

### Exercise
- Implement app of apps pattern for managing multiple applications
- Set up blue-green deployments with Argo Rollouts
- Create automated promotion pipelines between environments

---

## Best Practices

### 1. Repository Structure
- Separate application code from configuration
- Use environment-specific branches or directories
- Implement proper Git workflow (GitFlow/GitHub Flow)
- Use signed commits for security

### 2. Application Management
- Use ApplicationSets for multiple environments
- Implement proper project separation
- Use sync waves for ordered deployments
- Implement health checks and hooks

### 3. Security
- Enable RBAC and SSO integration
- Use sealed secrets or external secret management
- Implement image scanning and admission controllers
- Regular security audits and updates

### 4. Monitoring and Alerting
- Monitor application health and sync status
- Set up alerting for failures and drift
- Implement comprehensive logging
- Use distributed tracing for complex applications

---

## Common Use Cases

1. **Multi-Environment Deployments**
   - Development → Staging → Production
   - Feature branch deployments
   - Hotfix deployments

2. **Multi-Tenant Applications**
   - Team isolation with projects
   - Namespace-based tenant separation
   - Resource quotas and limits

3. **Progressive Delivery**
   - Canary deployments
   - Blue-green deployments
   - A/B testing

4. **Disaster Recovery**
   - Cross-region deployments
   - Backup and restore procedures
   - Failover automation

---

## Troubleshooting Guide

### Common Issues

1. **Sync Failures**
   - Check application logs
   - Verify RBAC permissions
   - Validate Kubernetes manifests
   - Check resource quotas

2. **Repository Access Issues**
   - Verify SSH keys or tokens
   - Check network connectivity
   - Validate repository URL
   - Check webhook configurations

3. **Health Check Failures**
   - Review application logs
   - Check readiness/liveness probes
   - Verify service endpoints
   - Check resource limits

4. **Performance Issues**
   - Monitor resource usage
   - Implement caching strategies
   - Optimize sync frequencies
   - Use application sharding

---

## Advanced Topics

- ArgoCD Notifications and webhooks
- Custom health checks and resource actions
- ArgoCD Extensions and plugins
- Multi-cluster federation
- Cost optimization strategies
- Compliance and governance

---

## Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Argo Rollouts](https://argoproj.github.io/argo-rollouts/)
- [ArgoCD Image Updater](https://argocd-image-updater.readthedocs.io/)
- [GitOps Patterns](https://www.gitops.tech/)
- [CNCF ArgoCD](https://www.cncf.io/projects/argo/)
