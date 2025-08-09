#!/bin/bash

echo "🚀 Setting up Social Media App Development Environment"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Create necessary directories
echo "📁 Creating project directories..."
mkdir -p deploy/kind deploy/terraform deploy/helm deploy/observability
mkdir -p gateway scripts/load-tests

# Build and start services
echo "🔨 Building and starting services..."
docker compose up --build -d

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 30

# Check service health
echo "🔍 Checking service health..."
docker compose ps

echo ""
echo "✅ Development environment is ready!"
echo ""
echo "🌐 Access URLs:"
echo "   Frontend:  http://localhost:8080"
echo "   Backend:   http://localhost:8000"
echo "   MinIO UI:  http://localhost:9001 (admin/minioadmin)"
echo ""
echo "🛠️  Useful commands:"
echo "   View logs:     docker compose logs -f [service]"
echo "   Stop all:      docker compose down"
echo "   Restart:       docker compose restart [service]"
echo ""