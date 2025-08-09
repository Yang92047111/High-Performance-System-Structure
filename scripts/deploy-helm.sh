#!/bin/bash

echo "🚀 Deploying Social Media App with Helm"

# Check if helm is available
if ! command -v helm &> /dev/null; then
    echo "❌ Helm is not installed. Please install Helm first."
    exit 1
fi

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install kubectl first."
    exit 1
fi

echo "📦 Building Docker images..."

# Build backend image
echo "Building backend image..."
docker build -t social-media-backend:latest ./backend

# Build frontend image
echo "Building frontend image..."
docker build -t social-media-frontend:latest ./frontend

echo "🔧 Installing/Upgrading Helm chart..."

# Create namespace if it doesn't exist
kubectl create namespace social-media --dry-run=client -o yaml | kubectl apply -f -

# Install or upgrade the Helm release
helm upgrade --install social-media ./deploy/helm/social-media \
  --namespace social-media \
  --wait \
  --timeout=10m

echo "✅ Helm deployment complete!"
echo ""
echo "📊 Checking deployment status:"
kubectl get pods -n social-media
echo ""
echo "🌐 Access the application:"
echo "   Add '127.0.0.1 social-media.local' to your /etc/hosts file"
echo "   Then visit: http://social-media.local"
echo ""
echo "🔧 Useful Helm commands:"
echo "   helm status social-media -n social-media"
echo "   helm history social-media -n social-media"
echo "   helm rollback social-media [REVISION] -n social-media"
echo "   helm uninstall social-media -n social-media"