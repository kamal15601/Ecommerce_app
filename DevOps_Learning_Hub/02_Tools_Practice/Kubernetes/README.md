# ☸️ Kubernetes Practice Labs

Comprehensive hands-on labs for mastering Kubernetes container orchestration.

## 📚 Table of Contents

1. [Lab 1: Kubernetes Fundamentals](#lab-1-kubernetes-fundamentals)
2. [Lab 2: Pods and Containers](#lab-2-pods-and-containers)
3. [Lab 3: Services and Networking](#lab-3-services-and-networking)
4. [Lab 4: Deployments and ReplicaSets](#lab-4-deployments-and-replicasets)
5. [Lab 5: ConfigMaps and Secrets](#lab-5-configmaps-and-secrets)
6. [Lab 6: Persistent Volumes](#lab-6-persistent-volumes)
7. [Lab 7: Namespaces and RBAC](#lab-7-namespaces-and-rbac)
8. [Lab 8: Ingress and Load Balancing](#lab-8-ingress-and-load-balancing)
9. [Lab 9: Monitoring and Logging](#lab-9-monitoring-and-logging)
10. [Lab 10: Advanced Patterns](#lab-10-advanced-patterns)

## 🎯 Prerequisites

- Kubernetes cluster (minikube, kind, or cloud provider)
- kubectl CLI tool installed
- Basic Docker knowledge
- Understanding of YAML syntax

## 🚀 Lab 1: Kubernetes Fundamentals

### Objective
Set up Kubernetes environment and understand basic concepts.

### 1.1 Environment Setup

#### Using Minikube (Local Development)
```bash
# Install minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Start cluster
minikube start --memory=4096 --cpus=2 --disk-size=20g

# Enable addons
minikube addons enable ingress
minikube addons enable dashboard
minikube addons enable metrics-server

# Access dashboard
minikube dashboard
```

#### Using KIND (Kubernetes in Docker)
```bash
# Install kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Create cluster
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
- role: worker
- role: worker
EOF
```

### 1.2 Basic Commands
```bash
# Cluster information
kubectl cluster-info
kubectl get nodes
kubectl get nodes -o wide

# Namespace operations
kubectl get namespaces
kubectl create namespace dev
kubectl config set-context --current --namespace=dev

# Resource discovery
kubectl api-resources
kubectl explain pod
kubectl explain pod.spec.containers
```

### 1.3 First Pod Creation
```yaml
# pod-basic.yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-first-pod
  labels:
    app: demo
    environment: development
spec:
  containers:
  - name: nginx
    image: nginx:1.20-alpine
    ports:
    - containerPort: 80
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "500m"
```

```bash
# Deploy and manage pod
kubectl apply -f pod-basic.yaml
kubectl get pods
kubectl describe pod my-first-pod
kubectl logs my-first-pod
kubectl exec -it my-first-pod -- sh

# Port forwarding
kubectl port-forward my-first-pod 8080:80

# Test in another terminal
curl http://localhost:8080

# Cleanup
kubectl delete pod my-first-pod
```

---

## 🧊 Lab 2: Pods and Containers

### Objective
Master pod creation, multi-container pods, and lifecycle management.

### 2.1 Multi-Container Pod
```yaml
# multi-container-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-container-pod
spec:
  containers:
  # Main application container
  - name: web-app
    image: nginx:alpine
    ports:
    - containerPort: 80
    volumeMounts:
    - name: shared-data
      mountPath: /usr/share/nginx/html
    
  # Sidecar container for log processing
  - name: log-processor
    image: busybox
    command: ['sh', '-c']
    args:
    - |
      while true; do
        echo "$(date): Processing logs..." >> /shared/logs/app.log
        sleep 30
      done
    volumeMounts:
    - name: shared-data
      mountPath: /shared
    
  # Init container for setup
  initContainers:
  - name: setup
    image: busybox
    command: ['sh', '-c']
    args:
    - |
      echo "<h1>Welcome to Multi-Container Pod</h1>" > /shared/index.html
      mkdir -p /shared/logs
    volumeMounts:
    - name: shared-data
      mountPath: /shared
  
  volumes:
  - name: shared-data
    emptyDir: {}
```

### 2.2 Pod with Resource Management
```yaml
# resource-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: resource-demo
spec:
  containers:
  - name: stress-test
    image: progrium/stress
    command: ["stress"]
    args: ["--vm", "1", "--vm-bytes", "150M", "--vm-hang", "1"]
    resources:
      requests:
        memory: "100Mi"
        cpu: "100m"
      limits:
        memory: "200Mi"
        cpu: "500m"
  - name: monitoring
    image: alpine
    command: ['sh', '-c']
    args:
    - |
      while true; do
        echo "Memory usage: $(cat /proc/meminfo | grep MemAvailable)"
        sleep 10
      done
```

### 2.3 Pod Lifecycle Hooks
```yaml
# lifecycle-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: lifecycle-demo
spec:
  containers:
  - name: lifecycle-demo
    image: nginx:alpine
    lifecycle:
      postStart:
        exec:
          command:
          - /bin/sh
          - -c
          - echo "Container started at $(date)" > /tmp/started.log
      preStop:
        exec:
          command:
          - /bin/sh
          - -c
          - echo "Container stopping at $(date)" >> /tmp/stopped.log; sleep 10
    readinessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 10
    livenessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 30
      periodSeconds: 30
```

---

## 🌐 Lab 3: Services and Networking

### Objective
Understand service discovery, load balancing, and network policies.

### 3.1 Service Types
```yaml
# ClusterIP Service (default)
apiVersion: v1
kind: Service
metadata:
  name: web-service-clusterip
spec:
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 8080
  type: ClusterIP
---
# NodePort Service
apiVersion: v1
kind: Service
metadata:
  name: web-service-nodeport
spec:
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30080
  type: NodePort
---
# LoadBalancer Service
apiVersion: v1
kind: Service
metadata:
  name: web-service-lb
spec:
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 8080
  type: LoadBalancer
```

### 3.2 Headless Service for Service Discovery
```yaml
# headless-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: database-headless
spec:
  clusterIP: None  # Makes it headless
  selector:
    app: database
  ports:
  - port: 5432
    targetPort: 5432
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: database-headless
  replicas: 3
  selector:
    matchLabels:
      app: database
  template:
    metadata:
      labels:
        app: database
    spec:
      containers:
      - name: postgres
        image: postgres:13
        env:
        - name: POSTGRES_DB
          value: mydb
        - name: POSTGRES_USER
          value: admin
        - name: POSTGRES_PASSWORD
          value: password123
        ports:
        - containerPort: 5432
```

### 3.3 Network Policies
```yaml
# network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: web-netpol
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    - namespaceSelector:
        matchLabels:
          name: monitoring
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
  - to: []  # Allow all external traffic
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
```

---

## 🚀 Lab 4: Deployments and ReplicaSets

### Objective
Master application deployment, scaling, and rolling updates.

### 4.1 Basic Deployment
```yaml
# deployment-basic.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deployment
  labels:
    app: web
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: web
        image: nginx:1.20-alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 30
```

### 4.2 Deployment Strategies
```yaml
# rolling-update-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-rolling-update
spec:
  replicas: 6
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 2
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: app
        image: myapp:v1.0
        ports:
        - containerPort: 8080
---
# recreate-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-recreate
spec:
  replicas: 3
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: myapp-recreate
  template:
    metadata:
      labels:
        app: myapp-recreate
    spec:
      containers:
      - name: app
        image: myapp:v1.0
        ports:
        - containerPort: 8080
```

### 4.3 Deployment Management
```bash
# Deployment operations
kubectl apply -f deployment-basic.yaml

# Scale deployment
kubectl scale deployment web-deployment --replicas=5

# Update image (rolling update)
kubectl set image deployment/web-deployment web=nginx:1.21-alpine

# Check rollout status
kubectl rollout status deployment/web-deployment

# View rollout history
kubectl rollout history deployment/web-deployment

# Rollback to previous version
kubectl rollout undo deployment/web-deployment

# Rollback to specific revision
kubectl rollout undo deployment/web-deployment --to-revision=2

# Pause/Resume rollout
kubectl rollout pause deployment/web-deployment
kubectl rollout resume deployment/web-deployment
```

### 4.4 Horizontal Pod Autoscaler
```yaml
# hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-deployment
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
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
      - type: Pods
        value: 4
        periodSeconds: 15
      selectPolicy: Max
```

---

## 🔧 Lab 5: ConfigMaps and Secrets

### Objective
Manage application configuration and sensitive data.

### 5.1 ConfigMaps
```yaml
# configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  # Key-value pairs
  database_host: "postgres.example.com"
  database_port: "5432"
  log_level: "INFO"
  
  # File-like keys
  app.properties: |
    server.port=8080
    server.servlet.context-path=/api
    spring.datasource.url=jdbc:postgresql://postgres:5432/mydb
    
  nginx.conf: |
    server {
        listen 80;
        location / {
            proxy_pass http://backend:8080;
            proxy_set_header Host $host;
        }
    }
---
# Using ConfigMap in Pod
apiVersion: v1
kind: Pod
metadata:
  name: app-with-config
spec:
  containers:
  - name: app
    image: myapp:latest
    env:
    # Environment variables from ConfigMap
    - name: DATABASE_HOST
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: database_host
    - name: DATABASE_PORT
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: database_port
    envFrom:
    # Load all keys as environment variables
    - configMapRef:
        name: app-config
    volumeMounts:
    # Mount as files
    - name: config-volume
      mountPath: /etc/config
    - name: nginx-config
      mountPath: /etc/nginx/nginx.conf
      subPath: nginx.conf
  volumes:
  - name: config-volume
    configMap:
      name: app-config
  - name: nginx-config
    configMap:
      name: app-config
```

### 5.2 Secrets
```yaml
# secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  # Base64 encoded values
  username: YWRtaW4=  # admin
  password: cGFzc3dvcmQxMjM=  # password123
  api-key: YWJjZGVmZ2hpams=  # abcdefghijk
---
# TLS Secret
apiVersion: v1
kind: Secret
metadata:
  name: tls-secret
type: kubernetes.io/tls
data:
  tls.crt: LS0tLS1CRUdJTi...  # Base64 encoded certificate
  tls.key: LS0tLS1CRUdJTi...  # Base64 encoded private key
---
# Docker registry secret
apiVersion: v1
kind: Secret
metadata:
  name: regcred
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: eyJhdXRocyI6...  # Base64 encoded docker config
```

### 5.3 Creating Secrets via kubectl
```bash
# Generic secret from literals
kubectl create secret generic db-secret \
  --from-literal=username=admin \
  --from-literal=password=secretpassword

# Secret from files
echo -n 'admin' > username.txt
echo -n 'secretpassword' > password.txt
kubectl create secret generic db-secret \
  --from-file=username.txt \
  --from-file=password.txt

# TLS secret from certificate files
kubectl create secret tls tls-secret \
  --cert=path/to/tls.cert \
  --key=path/to/tls.key

# Docker registry secret
kubectl create secret docker-registry regcred \
  --docker-server=registry.example.com \
  --docker-username=myuser \
  --docker-password=mypassword \
  --docker-email=myemail@example.com
```

### 5.4 Using Secrets in Pods
```yaml
# pod-with-secrets.yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-pod
spec:
  containers:
  - name: app
    image: myapp:latest
    env:
    # Environment variables from secrets
    - name: DB_USERNAME
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: username
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: password
    volumeMounts:
    # Mount secrets as files
    - name: secret-volume
      mountPath: /etc/secrets
      readOnly: true
  volumes:
  - name: secret-volume
    secret:
      secretName: app-secrets
      defaultMode: 0400  # Read-only for owner only
  imagePullSecrets:
  - name: regcred  # Use for pulling private images
```

---

## 💾 Lab 6: Persistent Volumes

### Objective
Manage persistent storage for stateful applications.

### 6.1 Persistent Volume and Claims
```yaml
# persistent-volume.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /mnt/disks/vol1
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - worker-node-1
---
# persistent-volume-claim.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: local-storage
```

### 6.2 StatefulSet with Persistent Storage
```yaml
# postgres-statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres-headless
  replicas: 3
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:13
        env:
        - name: POSTGRES_DB
          value: mydb
        - name: POSTGRES_USER
          value: admin
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        ports:
        - containerPort: 5432
          name: postgres
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
        readinessProbe:
          exec:
            command:
            - /bin/sh
            - -c
            - pg_isready -U admin -d mydb
          initialDelaySeconds: 15
          periodSeconds: 5
        livenessProbe:
          exec:
            command:
            - /bin/sh
            - -c
            - pg_isready -U admin -d mydb
          initialDelaySeconds: 45
          periodSeconds: 10
  volumeClaimTemplates:
  - metadata:
      name: postgres-storage
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 10Gi
      storageClassName: local-storage
```

### 6.3 Storage Classes
```yaml
# storage-class.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp3
  fsType: ext4
  encrypted: "true"
allowVolumeExpansion: true
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
---
# GCP Storage Class
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gcp-ssd
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-ssd
  zones: us-central1-a,us-central1-b
reclaimPolicy: Delete
allowVolumeExpansion: true
```

---

## 🔐 Lab 7: Namespaces and RBAC

### Objective
Implement multi-tenancy and security with namespaces and RBAC.

### 7.1 Namespace Management
```yaml
# namespaces.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: development
  labels:
    environment: dev
    team: backend
---
apiVersion: v1
kind: Namespace
metadata:
  name: staging
  labels:
    environment: staging
    team: backend
---
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    environment: prod
    team: backend
```

### 7.2 Resource Quotas
```yaml
# resource-quota.yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: dev-quota
  namespace: development
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
    persistentvolumeclaims: "10"
    pods: "10"
    services: "5"
    secrets: "10"
    configmaps: "10"
---
# Limit ranges
apiVersion: v1
kind: LimitRange
metadata:
  name: dev-limits
  namespace: development
spec:
  limits:
  - default:
      cpu: "500m"
      memory: "512Mi"
    defaultRequest:
      cpu: "100m"
      memory: "128Mi"
    type: Container
  - max:
      cpu: "2"
      memory: "2Gi"
    min:
      cpu: "50m"
      memory: "64Mi"
    type: Container
```

### 7.3 RBAC Configuration
```yaml
# service-account.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-service-account
  namespace: development
---
# role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: development
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "watch", "list"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
# role-binding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: development
subjects:
- kind: ServiceAccount
  name: app-service-account
  namespace: development
- kind: User
  name: jane
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
---
# cluster-role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: node-reader
rules:
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get", "watch", "list"]
---
# cluster-role-binding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: read-nodes
subjects:
- kind: ServiceAccount
  name: app-service-account
  namespace: development
roleRef:
  kind: ClusterRole
  name: node-reader
  apiGroup: rbac.authorization.k8s.io
```

---

## 🌐 Lab 8: Ingress and Load Balancing

### Objective
Expose applications to external traffic with Ingress controllers.

### 8.1 NGINX Ingress Controller Setup
```bash
# Install NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# Wait for controller to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

### 8.2 Basic Ingress
```yaml
# basic-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
  - host: api.example.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 8080
```

### 8.3 TLS/SSL Ingress
```yaml
# tls-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: secure-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - secure.example.com
    secretName: secure-tls
  rules:
  - host: secure.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: secure-service
            port:
              number: 443
```

### 8.4 Advanced Ingress Features
```yaml
# advanced-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: advanced-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    # Rate limiting
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/rate-limit-window: "1m"
    # Authentication
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: basic-auth
    # CORS
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-origin: "https://frontend.example.com"
    # Load balancing
    nginx.ingress.kubernetes.io/upstream-hash-by: "$request_uri"
    # Custom headers
    nginx.ingress.kubernetes.io/configuration-snippet: |
      add_header X-Frame-Options SAMEORIGIN;
      add_header X-Content-Type-Options nosniff;
spec:
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /api/v1
        pathType: Prefix
        backend:
          service:
            name: api-v1-service
            port:
              number: 8080
      - path: /api/v2
        pathType: Prefix
        backend:
          service:
            name: api-v2-service
            port:
              number: 8080
      - path: /static
        pathType: Prefix
        backend:
          service:
            name: static-service
            port:
              number: 80
```

---

## 📊 Lab 9: Monitoring and Logging

### Objective
Implement comprehensive monitoring and logging for Kubernetes.

### 9.1 Prometheus Stack
```yaml
# prometheus-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: monitoring
---
# prometheus-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: monitoring
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
      evaluation_interval: 15s
    
    rule_files:
      - "*.rules"
    
    alerting:
      alertmanagers:
        - static_configs:
            - targets:
              - alertmanager:9093
    
    scrape_configs:
      - job_name: 'prometheus'
        static_configs:
          - targets: ['localhost:9090']
      
      - job_name: 'kubernetes-apiservers'
        kubernetes_sd_configs:
        - role: endpoints
        scheme: https
        tls_config:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
        relabel_configs:
        - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
          action: keep
          regex: default;kubernetes;https
      
      - job_name: 'kubernetes-nodes'
        kubernetes_sd_configs:
        - role: node
        scheme: https
        tls_config:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
        relabel_configs:
        - action: labelmap
          regex: __meta_kubernetes_node_label_(.+)
        - target_label: __address__
          replacement: kubernetes.default.svc:443
        - source_labels: [__meta_kubernetes_node_name]
          regex: (.+)
          target_label: __metrics_path__
          replacement: /api/v1/nodes/${1}/proxy/metrics
      
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
```

### 9.2 Grafana Setup
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
        image: grafana/grafana:9.5.0
        ports:
        - containerPort: 3000
        env:
        - name: GF_SECURITY_ADMIN_PASSWORD
          valueFrom:
            secretKeyRef:
              name: grafana-secret
              key: admin-password
        - name: GF_INSTALL_PLUGINS
          value: "grafana-kubernetes-app"
        volumeMounts:
        - name: grafana-storage
          mountPath: /var/lib/grafana
        - name: grafana-config
          mountPath: /etc/grafana/grafana.ini
          subPath: grafana.ini
      volumes:
      - name: grafana-storage
        persistentVolumeClaim:
          claimName: grafana-pvc
      - name: grafana-config
        configMap:
          name: grafana-config
```

### 9.3 ELK Stack for Logging
```yaml
# elasticsearch.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: elasticsearch
  namespace: logging
spec:
  serviceName: elasticsearch
  replicas: 3
  selector:
    matchLabels:
      app: elasticsearch
  template:
    metadata:
      labels:
        app: elasticsearch
    spec:
      containers:
      - name: elasticsearch
        image: docker.elastic.co/elasticsearch/elasticsearch:8.8.0
        env:
        - name: discovery.type
          value: single-node
        - name: ES_JAVA_OPTS
          value: "-Xms1g -Xmx1g"
        - name: xpack.security.enabled
          value: "false"
        ports:
        - containerPort: 9200
        - containerPort: 9300
        volumeMounts:
        - name: elasticsearch-data
          mountPath: /usr/share/elasticsearch/data
  volumeClaimTemplates:
  - metadata:
      name: elasticsearch-data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 20Gi
---
# kibana.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kibana
  namespace: logging
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kibana
  template:
    metadata:
      labels:
        app: kibana
    spec:
      containers:
      - name: kibana
        image: docker.elastic.co/kibana/kibana:8.8.0
        env:
        - name: ELASTICSEARCH_HOSTS
          value: http://elasticsearch:9200
        ports:
        - containerPort: 5601
---
# fluentd-daemonset.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
  namespace: logging
spec:
  selector:
    matchLabels:
      name: fluentd
  template:
    metadata:
      labels:
        name: fluentd
    spec:
      tolerations:
      - key: node-role.kubernetes.io/master
        effect: NoSchedule
      containers:
      - name: fluentd
        image: fluent/fluentd-kubernetes-daemonset:v1-debian-elasticsearch
        env:
        - name: FLUENT_ELASTICSEARCH_HOST
          value: "elasticsearch"
        - name: FLUENT_ELASTICSEARCH_PORT
          value: "9200"
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
```

---

## 🚀 Lab 10: Advanced Patterns

### Objective
Implement advanced Kubernetes patterns and best practices.

### 10.1 Custom Resource Definitions (CRDs)
```yaml
# crd-definition.yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: webapps.example.com
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
                minimum: 1
                maximum: 10
              image:
                type: string
              port:
                type: integer
                minimum: 1
                maximum: 65535
            required:
            - replicas
            - image
            - port
          status:
            type: object
            properties:
              availableReplicas:
                type: integer
              conditions:
                type: array
                items:
                  type: object
                  properties:
                    type:
                      type: string
                    status:
                      type: string
                    reason:
                      type: string
                    message:
                      type: string
  scope: Namespaced
  names:
    plural: webapps
    singular: webapp
    kind: WebApp
    shortNames:
    - wa
---
# custom-resource.yaml
apiVersion: example.com/v1
kind: WebApp
metadata:
  name: my-webapp
spec:
  replicas: 3
  image: nginx:alpine
  port: 80
```

### 10.2 Operators Pattern
```yaml
# operator-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-operator
  namespace: webapp-system
spec:
  replicas: 1
  selector:
    matchLabels:
      name: webapp-operator
  template:
    metadata:
      labels:
        name: webapp-operator
    spec:
      serviceAccountName: webapp-operator
      containers:
      - name: operator
        image: webapp-operator:latest
        command:
        - webapp-operator
        env:
        - name: WATCH_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: OPERATOR_NAME
          value: "webapp-operator"
```

### 10.3 Job and CronJob Patterns
```yaml
# batch-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: data-migration
spec:
  parallelism: 3
  completions: 6
  backoffLimit: 3
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: migration
        image: migration-tool:latest
        command: ["python", "migrate.py"]
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: url
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
# cronjob.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup-job
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          containers:
          - name: backup
            image: backup-tool:latest
            command: ["backup.sh"]
            volumeMounts:
            - name: backup-storage
              mountPath: /backups
          volumes:
          - name: backup-storage
            persistentVolumeClaim:
              claimName: backup-pvc
```

### 10.4 Pod Disruption Budget
```yaml
# pod-disruption-budget.yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: web-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: web
---
# Alternative with percentage
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: api-pdb
spec:
  maxUnavailable: 25%
  selector:
    matchLabels:
      app: api
```

---

## 🎯 Practice Exercises

### Exercise 1: Multi-Tier Application
Deploy a complete 3-tier application:
- Frontend (React app)
- Backend (REST API)
- Database (PostgreSQL)
- Include all networking, storage, and configuration

### Exercise 2: Blue-Green Deployment
Implement blue-green deployment strategy:
- Deploy two identical environments
- Switch traffic between them
- Automate rollback mechanism

### Exercise 3: Monitoring Setup
Set up complete monitoring stack:
- Prometheus for metrics collection
- Grafana for visualization
- AlertManager for notifications
- Custom dashboards for your application

### Exercise 4: Security Hardening
Implement security best practices:
- Network policies
- RBAC configuration
- Pod security standards
- Secret management

---

## 📚 Additional Resources

### Official Documentation
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubectl Reference](https://kubernetes.io/docs/reference/kubectl/)
- [API Reference](https://kubernetes.io/docs/reference/kubernetes-api/)

### Learning Resources
- [Kubernetes the Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way)
- [KubeCon Presentations](https://www.youtube.com/c/cloudnativefdn)
- [Kubernetes Patterns](https://k8spatterns.io/)

### Tools and Utilities
- [k9s](https://k9scli.io/) - Terminal UI for Kubernetes
- [Lens](https://k8slens.dev/) - Kubernetes IDE
- [Helm](https://helm.sh/) - Package manager for Kubernetes
- [Kustomize](https://kustomize.io/) - Configuration management

---

**Next**: Move to `../Helm/` for Kubernetes package management labs.
