# Helm Hands-On Labs 🎯

## Overview
Helm is the package manager for Kubernetes that helps you manage Kubernetes applications. This section provides comprehensive hands-on labs to master Helm from basics to advanced scenarios.

## Prerequisites
- Kubernetes cluster (local or cloud)
- kubectl configured
- Helm 3.x installed

## Labs Structure

### Lab 1: Helm Installation and Setup
```bash
# Install Helm (Linux/macOS)
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install Helm (Windows)
choco install kubernetes-helm

# Verify installation
helm version

# Add popular repositories
helm repo add stable https://charts.helm.sh/stable
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
```

### Lab 2: Creating Your First Chart
```bash
# Create a new chart
helm create my-webapp

# Examine chart structure
tree my-webapp/
```

**Chart Structure:**
```
my-webapp/
├── Chart.yaml          # Chart metadata
├── values.yaml         # Default values
├── templates/          # Template files
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   └── _helpers.tpl
└── charts/            # Dependencies
```

**Custom values.yaml:**
```yaml
replicaCount: 3

image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: "1.21"

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: nginx
  hosts:
    - host: my-webapp.local
      paths:
        - path: /
          pathType: Prefix

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
```

### Lab 3: Installing and Managing Releases
```bash
# Install a release
helm install my-release ./my-webapp

# List releases
helm list

# Get release information
helm get all my-release

# Upgrade release
helm upgrade my-release ./my-webapp --set replicaCount=5

# Rollback release
helm rollback my-release 1

# Uninstall release
helm uninstall my-release
```

### Lab 4: Working with Repositories
```bash
# Search for charts
helm search repo nginx

# Install from repository
helm install nginx-ingress ingress-nginx/ingress-nginx

# Show chart information
helm show chart bitnami/mysql
helm show values bitnami/mysql

# Pull chart locally
helm pull bitnami/mysql --untar
```

### Lab 5: Advanced Templating
**templates/configmap.yaml:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "my-webapp.fullname" . }}-config
  labels:
    {{- include "my-webapp.labels" . | nindent 4 }}
data:
  database_url: {{ .Values.database.url | quote }}
  redis_url: {{ .Values.redis.url | quote }}
  {{- if .Values.features.enableCache }}
  cache_enabled: "true"
  {{- end }}
  {{- range $key, $value := .Values.environment }}
  {{ $key }}: {{ $value | quote }}
  {{- end }}
```

**Using conditionals and loops:**
```yaml
{{- if .Values.persistence.enabled }}
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ include "my-webapp.fullname" . }}-pvc
spec:
  accessModes:
    {{- range .Values.persistence.accessModes }}
    - {{ . | quote }}
    {{- end }}
  resources:
    requests:
      storage: {{ .Values.persistence.size | quote }}
{{- end }}
```

### Lab 6: Dependencies and Subcharts
**Chart.yaml with dependencies:**
```yaml
apiVersion: v2
name: my-webapp
description: A Helm chart for my web application
version: 0.1.0
appVersion: "1.0"

dependencies:
  - name: mysql
    version: 9.4.0
    repository: https://charts.bitnami.com/bitnami
    condition: mysql.enabled
  - name: redis
    version: 17.3.0
    repository: https://charts.bitnami.com/bitnami
    condition: redis.enabled
```

```bash
# Update dependencies
helm dependency update

# Install with dependencies
helm install my-app ./my-webapp \
  --set mysql.enabled=true \
  --set redis.enabled=true
```

### Lab 7: Helm Hooks and Tests
**templates/tests/test-connection.yaml:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: "{{ include "my-webapp.fullname" . }}-test"
  labels:
    {{- include "my-webapp.labels" . | nindent 4 }}
  annotations:
    "helm.sh/hook": test
spec:
  restartPolicy: Never
  containers:
    - name: wget
      image: busybox
      command: ['wget']
      args: ['{{ include "my-webapp.fullname" . }}:{{ .Values.service.port }}']
```

**Pre/Post hooks:**
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: "{{ include "my-webapp.fullname" . }}-migration"
  annotations:
    "helm.sh/hook": pre-upgrade,pre-install
    "helm.sh/hook-weight": "-5"
    "helm.sh/hook-delete-policy": before-hook-creation
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: migration
          image: migrate/migrate
          command: ["migrate", "-path", "/migrations", "-database", "postgres://...", "up"]
```

### Lab 8: Packaging and Distribution
```bash
# Package chart
helm package my-webapp

# Create repository index
helm repo index . --url https://my-charts.example.com

# Lint chart
helm lint my-webapp

# Verify chart
helm verify my-webapp-0.1.0.tgz

# Push to repository (using chartmuseum)
curl --data-binary "@my-webapp-0.1.0.tgz" http://localhost:8080/api/charts
```

### Lab 9: Helm Secrets and Security
```bash
# Install helm-secrets plugin
helm plugin install https://github.com/jkroepke/helm-secrets

# Create encrypted values
echo "database_password: supersecret" | helm secrets enc /dev/stdin > secrets.yaml

# Install with secrets
helm secrets install my-app ./my-webapp -f secrets.yaml
```

**Using Kubernetes secrets:**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "my-webapp.fullname" . }}-secret
type: Opaque
data:
  database-password: {{ .Values.database.password | b64enc }}
  api-key: {{ .Values.api.key | b64enc }}
```

### Lab 10: Multi-Environment Deployments
**environments/dev-values.yaml:**
```yaml
replicaCount: 1
image:
  tag: "dev"
resources:
  limits:
    cpu: 200m
    memory: 256Mi
database:
  url: "postgresql://dev-db:5432/myapp"
```

**environments/prod-values.yaml:**
```yaml
replicaCount: 5
image:
  tag: "1.0.0"
resources:
  limits:
    cpu: 1000m
    memory: 1Gi
database:
  url: "postgresql://prod-db:5432/myapp"
autoscaling:
  enabled: true
```

```bash
# Deploy to different environments
helm install myapp-dev ./my-webapp -f environments/dev-values.yaml
helm install myapp-prod ./my-webapp -f environments/prod-values.yaml
```

### Lab 11: Helm with GitOps
**ArgoCD Application:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-webapp
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/myorg/helm-charts
    targetRevision: HEAD
    path: charts/my-webapp
    helm:
      valueFiles:
        - values-prod.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### Lab 12: Monitoring and Observability
**ServiceMonitor for Prometheus:**
```yaml
{{- if .Values.monitoring.enabled }}
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: {{ include "my-webapp.fullname" . }}
  labels:
    {{- include "my-webapp.labels" . | nindent 4 }}
spec:
  selector:
    matchLabels:
      {{- include "my-webapp.selectorLabels" . | nindent 6 }}
  endpoints:
  - port: http
    path: /metrics
{{- end }}
```

## Best Practices

### 1. Chart Structure
- Use semantic versioning
- Keep templates simple and readable
- Use helper templates for common labels
- Validate input values

### 2. Values Organization
```yaml
# Good: Organized and clear
database:
  host: localhost
  port: 5432
  credentials:
    username: myuser
    password: mypass

# Bad: Flat and unclear
databaseHost: localhost
databasePort: 5432
databaseUsername: myuser
databasePassword: mypass
```

### 3. Template Best Practices
```yaml
# Use proper indentation
{{- include "my-webapp.labels" . | nindent 4 }}

# Quote string values
image: {{ .Values.image.repository }}:{{ .Values.image.tag | quote }}

# Provide defaults
replicas: {{ .Values.replicaCount | default 1 }}

# Use range for arrays
{{- range .Values.env }}
- name: {{ .name }}
  value: {{ .value | quote }}
{{- end }}
```

### 4. Security Considerations
- Never commit secrets to Git
- Use Kubernetes secrets for sensitive data
- Validate and sanitize inputs
- Use least privilege RBAC

## Troubleshooting

### Common Issues
```bash
# Debug rendering
helm template my-release ./my-webapp

# Dry run install
helm install my-release ./my-webapp --dry-run

# Check release history
helm history my-release

# Get detailed status
helm status my-release

# Debug failed release
kubectl describe pod -l app.kubernetes.io/name=my-webapp
kubectl logs -l app.kubernetes.io/name=my-webapp
```

### Validation Commands
```bash
# Lint chart
helm lint ./my-webapp

# Template with debug
helm template --debug ./my-webapp

# Verify chart integrity
helm verify my-webapp-0.1.0.tgz
```

## Real-World Scenarios

### Scenario 1: Blue-Green Deployment
```bash
# Deploy blue version
helm install myapp-blue ./my-webapp --set version=blue

# Deploy green version
helm install myapp-green ./my-webapp --set version=green

# Switch traffic (update ingress)
helm upgrade myapp-blue ./my-webapp --set traffic.target=green
```

### Scenario 2: Canary Deployment
```yaml
# Canary values
canary:
  enabled: true
  weight: 10
  stable:
    replicaCount: 5
  canary:
    replicaCount: 1
    image:
      tag: "v2.0.0"
```

### Scenario 3: Multi-Cluster Deployment
```bash
# Deploy to multiple clusters
for cluster in dev staging prod; do
  kubectl config use-context $cluster
  helm upgrade --install myapp ./my-webapp -f values-$cluster.yaml
done
```

## Advanced Topics

### Custom Resource Definitions (CRDs)
```yaml
# crds/mycrd.yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: myresources.example.com
spec:
  group: example.com
  versions:
  - name: v1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              replicas:
                type: integer
```

### Library Charts
```yaml
# Chart.yaml for library chart
apiVersion: v2
name: common
type: library
version: 0.1.0
```

### Helm Operators
```yaml
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: my-webapp
  namespace: kube-system
spec:
  chart: my-webapp
  repo: https://charts.example.com
  targetNamespace: default
  valuesContent: |-
    replicaCount: 3
    image:
      tag: "1.0.0"
```

## Resources and References

### Official Documentation
- [Helm Documentation](https://helm.sh/docs/)
- [Chart Development Guide](https://helm.sh/docs/chart_template_guide/)
- [Best Practices](https://helm.sh/docs/chart_best_practices/)

### Community Charts
- [Artifact Hub](https://artifacthub.io/)
- [Bitnami Charts](https://github.com/bitnami/charts)
- [Helm Stable Charts](https://github.com/helm/charts)

### Tools and Plugins
- [helm-secrets](https://github.com/jkroepke/helm-secrets)
- [helm-diff](https://github.com/databus23/helm-diff)
- [helmfile](https://github.com/roboll/helmfile)

This comprehensive guide covers Helm from basics to advanced scenarios, providing hands-on experience with real-world use cases and best practices for production deployments.
