# 🔬 Cloud-Native Microservices Lab

This lab provides hands-on experience building and deploying a microservices application using cloud-native technologies and best practices.

## 🎯 Objectives

By the end of this lab, you will be able to:

1. Design a microservices architecture
2. Containerize individual services with Docker
3. Orchestrate services with Kubernetes
4. Implement service-to-service communication
5. Set up observability with Prometheus and Grafana
6. Apply GitOps principles for deployment
7. Implement a service mesh with Istio

## 🛠️ Prerequisites

- Docker installed locally
- kubectl command-line tool
- A Kubernetes cluster (local via Minikube/kind or cloud-based)
- Helm 3
- Git client
- A code editor (VS Code recommended)

## 📋 Lab Architecture

We'll build a simplified e-commerce application with the following services:

1. **API Gateway**: Routes requests to appropriate services
2. **Product Service**: Manages product catalog and inventory
3. **Cart Service**: Handles shopping cart operations
4. **Order Service**: Processes orders and payments
5. **User Service**: Manages user profiles and authentication

Each service will have:
- Its own codebase and repository
- A dedicated database (MongoDB)
- REST API endpoints
- Containerized deployment
- Kubernetes configuration

## 🧩 Part 1: Setting Up the Development Environment

### Step 1: Create a Project Structure

```bash
mkdir cloud-native-microservices
cd cloud-native-microservices
mkdir -p api-gateway product-service cart-service order-service user-service k8s
```

### Step 2: Set Up a Local Kubernetes Cluster

Using kind (Kubernetes in Docker):

```bash
# Create a kind cluster with 3 nodes
cat <<EOF > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
EOF

kind create cluster --config kind-config.yaml --name microservices
```

Verify your cluster is running:

```bash
kubectl get nodes
```

### Step 3: Set Up a GitOps Repository

```bash
mkdir -p gitops/base gitops/overlays/{dev,staging,prod}
```

## 🧩 Part 2: Creating the Microservices

### Step 1: Product Service

Create a simple Node.js service:

```bash
cd product-service
```

Create package.json:

```json
{
  "name": "product-service",
  "version": "1.0.0",
  "description": "Product microservice",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "mongoose": "^7.0.3",
    "cors": "^2.8.5",
    "dotenv": "^16.0.3"
  },
  "devDependencies": {
    "nodemon": "^2.0.22"
  }
}
```

Create server.js:

```javascript
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json());

// Database connection
mongoose.connect(process.env.MONGO_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true
})
.then(() => console.log('MongoDB connected'))
.catch(err => console.error('MongoDB connection error:', err));

// Product schema
const productSchema = new mongoose.Schema({
  name: { type: String, required: true },
  description: { type: String, required: true },
  price: { type: Number, required: true },
  category: { type: String, required: true },
  inventory: { type: Number, default: 0 }
});

const Product = mongoose.model('Product', productSchema);

// Routes
app.get('/api/products', async (req, res) => {
  try {
    const products = await Product.find();
    res.json(products);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/products/:id', async (req, res) => {
  try {
    const product = await Product.findById(req.params.id);
    if (!product) return res.status(404).json({ error: 'Product not found' });
    res.json(product);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/products', async (req, res) => {
  try {
    const product = new Product(req.body);
    await product.save();
    res.status(201).json(product);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// Start server
app.listen(PORT, () => {
  console.log(`Product service running on port ${PORT}`);
});
```

Create a Dockerfile:

```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./

RUN npm ci --only=production

COPY . .

EXPOSE 3001

CMD ["node", "server.js"]
```

Create a .env file:

```
MONGO_URI=mongodb://mongodb-product:27017/products
PORT=3001
```

### Step 2: Create Similar Services for Cart, Order, and User

Follow a similar pattern for the other services, adjusting the database connections and API endpoints accordingly.

### Step 3: Create an API Gateway

In the api-gateway directory:

```javascript
const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Service URLs
const PRODUCT_SERVICE_URL = process.env.PRODUCT_SERVICE_URL || 'http://product-service:3001';
const CART_SERVICE_URL = process.env.CART_SERVICE_URL || 'http://cart-service:3002';
const ORDER_SERVICE_URL = process.env.ORDER_SERVICE_URL || 'http://order-service:3003';
const USER_SERVICE_URL = process.env.USER_SERVICE_URL || 'http://user-service:3004';

// Proxy middleware configuration
app.use('/api/products', createProxyMiddleware({ 
  target: PRODUCT_SERVICE_URL, 
  changeOrigin: true,
  pathRewrite: {
    '^/api/products': '/api/products', 
  },
}));

app.use('/api/cart', createProxyMiddleware({ 
  target: CART_SERVICE_URL, 
  changeOrigin: true,
  pathRewrite: {
    '^/api/cart': '/api/cart', 
  },
}));

app.use('/api/orders', createProxyMiddleware({ 
  target: ORDER_SERVICE_URL, 
  changeOrigin: true,
  pathRewrite: {
    '^/api/orders': '/api/orders', 
  },
}));

app.use('/api/users', createProxyMiddleware({ 
  target: USER_SERVICE_URL, 
  changeOrigin: true,
  pathRewrite: {
    '^/api/users': '/api/users', 
  },
}));

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// Start server
app.listen(PORT, () => {
  console.log(`API Gateway running on port ${PORT}`);
});
```

## 🧩 Part 3: Kubernetes Deployment

### Step 1: Create Kubernetes Manifests for Each Service

For the Product Service:

```yaml
# k8s/product-service.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: product-service
  labels:
    app: product-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: product-service
  template:
    metadata:
      labels:
        app: product-service
    spec:
      containers:
      - name: product-service
        image: ${REGISTRY}/product-service:latest
        ports:
        - containerPort: 3001
        env:
        - name: MONGO_URI
          value: "mongodb://mongodb-product:27017/products"
        - name: PORT
          value: "3001"
        livenessProbe:
          httpGet:
            path: /health
            port: 3001
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 3001
          initialDelaySeconds: 5
          periodSeconds: 5
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: product-service
spec:
  selector:
    app: product-service
  ports:
  - port: 3001
    targetPort: 3001
  type: ClusterIP
```

Create similar manifests for the other services.

### Step 2: Set Up MongoDB for Each Service

```yaml
# k8s/mongodb.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mongodb-product
spec:
  serviceName: mongodb-product
  replicas: 1
  selector:
    matchLabels:
      app: mongodb-product
  template:
    metadata:
      labels:
        app: mongodb-product
    spec:
      containers:
      - name: mongodb
        image: mongo:5.0
        ports:
        - containerPort: 27017
        volumeMounts:
        - name: mongodb-data
          mountPath: /data/db
  volumeClaimTemplates:
  - metadata:
      name: mongodb-data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 1Gi
---
apiVersion: v1
kind: Service
metadata:
  name: mongodb-product
spec:
  selector:
    app: mongodb-product
  ports:
  - port: 27017
    targetPort: 27017
  clusterIP: None
```

Create similar manifests for the other MongoDB instances.

### Step 3: Set Up API Gateway

```yaml
# k8s/api-gateway.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway
  labels:
    app: api-gateway
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api-gateway
  template:
    metadata:
      labels:
        app: api-gateway
    spec:
      containers:
      - name: api-gateway
        image: ${REGISTRY}/api-gateway:latest
        ports:
        - containerPort: 3000
        env:
        - name: PRODUCT_SERVICE_URL
          value: "http://product-service:3001"
        - name: CART_SERVICE_URL
          value: "http://cart-service:3002"
        - name: ORDER_SERVICE_URL
          value: "http://order-service:3003"
        - name: USER_SERVICE_URL
          value: "http://user-service:3004"
        - name: PORT
          value: "3000"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: api-gateway
spec:
  selector:
    app: api-gateway
  ports:
  - port: 80
    targetPort: 3000
  type: LoadBalancer
```

### Step 4: Create an Ingress for External Access

```yaml
# k8s/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: microservices-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$1
spec:
  rules:
  - host: microservices.local
    http:
      paths:
      - path: /(.*)
        pathType: Prefix
        backend:
          service:
            name: api-gateway
            port:
              number: 80
```

## 🧩 Part 4: GitOps Implementation

### Step 1: Set Up ArgoCD in Your Cluster

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### Step 2: Create Kustomize Configuration

Create base resources:

```yaml
# gitops/base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../k8s/api-gateway.yaml
  - ../../k8s/product-service.yaml
  - ../../k8s/cart-service.yaml
  - ../../k8s/order-service.yaml
  - ../../k8s/user-service.yaml
  - ../../k8s/mongodb.yaml
  - ../../k8s/ingress.yaml
```

Create overlays for different environments:

```yaml
# gitops/overlays/dev/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base

namespace: microservices-dev

patches:
  - patch: |-
      - op: replace
        path: /spec/replicas
        value: 1
    target:
      kind: Deployment
      name: api-gateway
  - patch: |-
      - op: replace
        path: /spec/replicas
        value: 1
    target:
      kind: Deployment
      name: product-service
  # Add similar patches for other services
```

### Step 3: Configure ArgoCD Application

```yaml
# gitops/argocd-application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: microservices
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/yourusername/cloud-native-microservices.git
    targetRevision: HEAD
    path: gitops/overlays/dev
  destination:
    server: https://kubernetes.default.svc
    namespace: microservices-dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

## 🧩 Part 5: Implementing Observability

### Step 1: Set Up Prometheus and Grafana

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace
```

### Step 2: Add Service Monitoring

Add Prometheus annotations to your services:

```yaml
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/path: "/metrics"
    prometheus.io/port: "3001"
```

### Step 3: Create a Grafana Dashboard

Use the Grafana UI to create dashboards for:
- Service health and availability
- API endpoint response times
- Error rates
- Resource utilization

## 🧩 Part 6: Implementing a Service Mesh with Istio

### Step 1: Install Istio

```bash
curl -L https://istio.io/downloadIstio | sh -
cd istio-*
export PATH=$PWD/bin:$PATH
istioctl install --set profile=demo -y
```

### Step 2: Enable Istio Injection

```bash
kubectl label namespace microservices-dev istio-injection=enabled
```

### Step 3: Configure Traffic Management

Create a virtual service for canary deployments:

```yaml
# k8s/product-service-virtual-service.yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: product-service
spec:
  hosts:
  - product-service
  http:
  - route:
    - destination:
        host: product-service
        subset: v1
      weight: 90
    - destination:
        host: product-service
        subset: v2
      weight: 10
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: product-service
spec:
  host: product-service
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
```

### Step 4: Implement Mutual TLS

Enable strict mTLS:

```yaml
# k8s/mtls-policy.yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: microservices-dev
spec:
  mtls:
    mode: STRICT
```

## 🏁 Conclusion

Congratulations! You've successfully built and deployed a cloud-native microservices application with:

- Containerized services
- Kubernetes orchestration
- Service discovery and routing
- Observability with Prometheus and Grafana
- GitOps deployment with ArgoCD
- Service mesh with Istio

## 📚 Next Steps

1. Implement CI pipelines for each service
2. Add feature flags for controlled rollouts
3. Implement distributed tracing with Jaeger
4. Set up chaos engineering with Chaos Mesh
5. Add autoscaling based on metrics

## 🔍 Troubleshooting

### Common Issues

1. **Services can't communicate**: Check network policies and service names
2. **MongoDB connection failing**: Verify StatefulSet and PVC configuration
3. **ArgoCD sync failing**: Check Git repository access and path configuration
4. **Istio sidecar not injecting**: Verify namespace label and pod annotations
5. **Prometheus not collecting metrics**: Check service annotations and scrape configuration

### Useful Commands

```bash
# Check pod status
kubectl get pods -n microservices-dev

# Check logs
kubectl logs -f deployment/product-service -n microservices-dev

# Port forward to a service
kubectl port-forward svc/api-gateway 8080:80 -n microservices-dev

# Check Istio proxy configuration
istioctl proxy-config all <pod-name> -n microservices-dev

# Get ArgoCD status
kubectl get applications -n argocd
```
