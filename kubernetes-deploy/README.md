# Kubernetes Deployment

This folder contains all files needed to deploy the application to a Kubernetes cluster.

## Files in this folder:

### Helm Charts
- `helm/` - Complete Helm chart for the application
  - `Chart.yaml` - Helm chart metadata
  - `values.yaml` - Default configuration values
  - `values-dev.yaml` - Development environment values
  - `values-staging.yaml` - Staging environment values
  - `values-prod.yaml` - Production environment values
  - `templates/` - Kubernetes manifest templates

### Raw Kubernetes Manifests
- `manifests/` - Raw Kubernetes YAML files
  - `namespace.yaml` - Application namespace
  - `configmap.yaml` - Configuration data
  - `secret.yaml` - Sensitive data
  - `deployment.yaml` - Application deployments
  - `service.yaml` - Service definitions
  - `ingress.yaml` - Ingress configuration
  - `pvc.yaml` - Persistent volume claims

### Scripts
- `deploy-k8s.sh` - Deploy using kubectl
- `deploy-helm.sh` - Deploy using Helm
- `update-config.sh` - Update configuration
- `rollback.sh` - Rollback deployment
- `cleanup-k8s.sh` - Clean up resources

## Services deployed:

1. **Backend** (Flask Application)
   - Deployment with 3 replicas (production)
   - Auto-scaling enabled
   - Health checks configured
   - Resource limits set

2. **Database** (PostgreSQL)
   - StatefulSet for data persistence
   - Persistent volume for data storage
   - Backup and recovery configured

3. **Cache** (Redis)
   - Deployment with persistence
   - Master-slave configuration (production)
   - Memory limits configured

4. **Ingress** (Nginx Ingress Controller)
   - SSL/TLS termination
   - Load balancing
   - Rate limiting

## Deployment Options:

### Using Helm (Recommended):

#### Development:
```bash
./deploy-helm.sh dev
```

#### Staging:
```bash
./deploy-helm.sh staging
```

#### Production:
```bash
./deploy-helm.sh prod
```

### Using Raw Manifests:
```bash
./deploy-k8s.sh
```

### Update Configuration:
```bash
./update-config.sh
```

### Rollback:
```bash
./rollback.sh
```

## Requirements:
- Kubernetes cluster 1.24+
- kubectl configured
- Helm 3.8+ (for Helm deployments)
- Ingress controller (nginx-ingress recommended)
- cert-manager (for SSL certificates)

## Monitoring:
- Prometheus metrics enabled
- Grafana dashboards included
- Alert rules configured
- Log aggregation with ELK stack
