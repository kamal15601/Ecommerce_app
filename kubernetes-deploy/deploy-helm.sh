#!/bin/bash

# Kubernetes Helm Deployment Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

# Check dependencies
check_dependencies() {
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi

    if ! command -v helm &> /dev/null; then
        print_error "Helm is not installed. Please install Helm 3.8+ first."
        exit 1
    fi

    # Check if kubectl can connect to cluster
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
        exit 1
    fi
}

# Get deployment environment
get_environment() {
    ENV=${1:-dev}
    
    case $ENV in
        dev|development)
            NAMESPACE="ecommerce-dev"
            VALUES_FILE="helm/ecommerce/values-dev.yaml"
            RELEASE_NAME="ecommerce-dev"
            ;;
        staging)
            NAMESPACE="ecommerce-staging"
            VALUES_FILE="helm/ecommerce/values-staging.yaml"
            RELEASE_NAME="ecommerce-staging"
            ;;
        prod|production)
            NAMESPACE="ecommerce-prod"
            VALUES_FILE="helm/ecommerce/values-prod.yaml"
            RELEASE_NAME="ecommerce-prod"
            ;;
        *)
            print_error "Invalid environment: $ENV"
            print_error "Usage: $0 [dev|staging|prod]"
            exit 1
            ;;
    esac
}

# Deploy application
deploy_application() {
    print_status "🚀 Deploying E-commerce Application to $ENV environment"
    
    # Copy Helm chart from k8s directory
    if [ -d "../k8s/helm/ecommerce" ]; then
        cp -r ../k8s/helm ./
        print_status "📁 Copied Helm chart from k8s directory"
    else
        print_error "Helm chart not found in k8s directory"
        exit 1
    fi
    
    # Create namespace if it doesn't exist
    print_status "📦 Creating namespace: $NAMESPACE"
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    
    # Add required Helm repositories
    print_status "📚 Adding Helm repositories..."
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo update
    
    # Install/upgrade the application
    print_status "🔧 Installing/upgrading Helm release: $RELEASE_NAME"
    
    helm upgrade --install $RELEASE_NAME helm/ecommerce \
        --namespace $NAMESPACE \
        --create-namespace \
        --values helm/ecommerce/values.yaml \
        --values $VALUES_FILE \
        --timeout 10m \
        --wait
    
    # Wait for rollout to complete
    print_status "⏳ Waiting for deployment to complete..."
    kubectl rollout status deployment/$RELEASE_NAME-backend -n $NAMESPACE --timeout=600s
    
    # Check pod status
    print_status "📋 Checking pod status..."
    kubectl get pods -n $NAMESPACE -l app.kubernetes.io/instance=$RELEASE_NAME
    
    # Get service information
    print_status "🌐 Service information:"
    kubectl get services -n $NAMESPACE -l app.kubernetes.io/instance=$RELEASE_NAME
    
    # Get ingress information
    if kubectl get ingress -n $NAMESPACE &> /dev/null; then
        print_status "🔗 Ingress information:"
        kubectl get ingress -n $NAMESPACE
    fi
    
    print_status "✅ Deployment completed successfully!"
    
    # Show access instructions
    show_access_info
}

# Show access information
show_access_info() {
    print_status "🔍 Access Information:"
    
    # Get LoadBalancer IP if available
    LB_IP=$(kubectl get service -n $NAMESPACE -l app.kubernetes.io/component=frontend -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    
    if [ -n "$LB_IP" ]; then
        echo "  External IP: http://$LB_IP"
    fi
    
    # Port-forward instructions
    echo "  Port-forward command:"
    echo "    kubectl port-forward -n $NAMESPACE service/$RELEASE_NAME-backend 8080:80"
    echo "    Then access: http://localhost:8080"
    
    # Logs command
    echo "  View logs:"
    echo "    kubectl logs -n $NAMESPACE -l app.kubernetes.io/name=ecommerce -f"
    
    # Monitoring commands
    echo "  Monitoring:"
    echo "    kubectl top pods -n $NAMESPACE"
    echo "    kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp'"
}

# Cleanup function
cleanup() {
    if [ -d "helm" ]; then
        rm -rf helm
        print_status "🧹 Cleaned up temporary Helm chart"
    fi
}

# Main execution
main() {
    check_dependencies
    get_environment $1
    
    # Set trap for cleanup
    trap cleanup EXIT
    
    deploy_application
}

# Run main function
main $@
