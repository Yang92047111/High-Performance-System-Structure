#!/bin/bash

echo "🚀 Deploying Social Media App to Kubernetes"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if we're connected to a cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Not connected to a Kubernetes cluster. Please configure kubectl."
    exit 1
fi

echo "📦 Building Docker images..."

# Build backend image
echo "Building backend image..."
docker build -t social-media-backend:latest ./backend

# Build frontend image
echo "Building frontend image..."
docker build -t social-media-frontend:latest ./frontend

echo "🔧 Applying Kubernetes manifests..."

# Apply manifests in order
kubectl apply -f deploy/k8s/namespace.yaml
kubectl apply -f deploy/k8s/configmap.yaml
kubectl apply -f deploy/k8s/secrets.yaml
kubectl apply -f deploy/k8s/postgres.yaml
kubectl apply -f deploy/k8s/redis.yaml
kubectl apply -f deploy/k8s/minio.yaml

# Wait for databases to be ready
echo "⏳ Waiting for databases to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/postgres -n social-media
kubectl wait --for=condition=available --timeout=300s deployment/redis -n social-media
kubectl wait --for=condition=available --timeout=300s deployment/minio -n social-media

# Deploy application services
kubectl apply -f deploy/k8s/backend.yaml
kubectl apply -f deploy/k8s/frontend.yaml

# Wait for application to be ready
echo "⏳ Waiting for application to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/backend -n social-media
kubectl wait --for=condition=available --timeout=300s deployment/frontend -n social-media

# Apply ingress
kubectl apply -f deploy/k8s/ingress.yaml

echo "✅ Deployment complete!"
echo ""
echo "📊 Checking deployment status:"
kubectl get pods -n social-media
echo ""
echo "🌐 Access the application:"
echo "   Add '127.0.0.1 social-media.local' to your /etc/hosts file"
echo "   Then visit: http://social-media.local"
echo ""
echo "🔧 Useful commands:"
echo "   kubectl get pods -n social-media"
echo "   kubectl logs -f deployment/backend -n social-media"
echo "   kubectl port-forward svc/backend-service 8000:8000 -n social-media"