#!/bin/bash

echo "📊 Deploying Advanced Observability Stack"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if main system is running
check_main_system() {
    echo -e "${BLUE}🔍 Checking if main system is running...${NC}"
    
    # Check if containers are running
    if ! docker ps --format "{{.Names}}" | grep -q "social-media-backend"; then
        echo -e "${YELLOW}⚠️  Main system containers not found. Starting main system...${NC}"
        docker compose up -d
        
        echo -e "${YELLOW}⏳ Waiting for main system to be ready...${NC}"
        sleep 30
        
        # Wait for backend to be healthy
        for i in {1..30}; do
            if curl -s http://localhost:8000/health > /dev/null; then
                break
            fi
            echo "Waiting for backend to be ready... ($i/30)"
            sleep 5
        done
    fi
    
    if ! curl -s http://localhost:8000/health > /dev/null; then
        echo -e "${RED}❌ Main system is not responding! Please check 'docker compose logs'${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Main system is running${NC}"
}

# Deploy observability stack
deploy_observability() {
    echo -e "${BLUE}🚀 Deploying observability stack...${NC}"
    
    cd deploy/observability
    
    # Ensure the network exists (it should from main docker-compose)
    if ! docker network ls | grep -q "social-media-network"; then
        echo -e "${YELLOW}⚠️  Creating social-media-network...${NC}"
        docker network create social-media-network
    fi
    
    # Start observability services
    docker compose -f docker-compose.observability.yml up -d
    
    echo -e "${YELLOW}⏳ Waiting for services to start...${NC}"
    sleep 45
    
    cd ../..
}

# Configure Grafana dashboards
configure_grafana() {
    echo -e "${BLUE}📊 Configuring Grafana dashboards...${NC}"
    
    # Wait for Grafana to be ready
    echo "Waiting for Grafana to be ready..."
    for i in {1..30}; do
        if curl -s http://localhost:3000/api/health > /dev/null; then
            break
        fi
        sleep 2
    done
    
    # Import dashboards
    echo "Importing dashboards..."
    
    # Social Media Overview Dashboard
    curl -X POST \
        -H "Content-Type: application/json" \
        -d @deploy/observability/grafana/dashboards/social-media-overview.json \
        http://admin:admin123@localhost:3000/api/dashboards/db
    
    # Infrastructure Dashboard
    curl -X POST \
        -H "Content-Type: application/json" \
        -d @deploy/observability/grafana/dashboards/infrastructure.json \
        http://admin:admin123@localhost:3000/api/dashboards/db
    
    echo -e "${GREEN}✅ Grafana dashboards configured${NC}"
}

# Test observability stack
test_observability() {
    echo -e "${BLUE}🧪 Testing observability stack...${NC}"
    
    # Test Prometheus
    if curl -s http://localhost:9090/-/healthy > /dev/null; then
        echo -e "${GREEN}✅ Prometheus is healthy${NC}"
    else
        echo -e "${RED}❌ Prometheus is not responding${NC}"
    fi
    
    # Test Grafana
    if curl -s http://localhost:3000/api/health > /dev/null; then
        echo -e "${GREEN}✅ Grafana is healthy${NC}"
    else
        echo -e "${RED}❌ Grafana is not responding${NC}"
    fi
    
    # Test AlertManager
    if curl -s http://localhost:9093/-/healthy > /dev/null; then
        echo -e "${GREEN}✅ AlertManager is healthy${NC}"
    else
        echo -e "${RED}❌ AlertManager is not responding${NC}"
    fi
    
    # Test Loki
    if curl -s http://localhost:3100/ready > /dev/null; then
        echo -e "${GREEN}✅ Loki is healthy${NC}"
    else
        echo -e "${RED}❌ Loki is not responding${NC}"
    fi
    
    # Test Jaeger
    if curl -s http://localhost:16686/ > /dev/null; then
        echo -e "${GREEN}✅ Jaeger is healthy${NC}"
    else
        echo -e "${RED}❌ Jaeger is not responding${NC}"
    fi
}

# Generate sample data for dashboards
generate_sample_data() {
    echo -e "${BLUE}📈 Generating sample data for dashboards...${NC}"
    
    # Make some API calls to generate metrics
    for i in {1..20}; do
        curl -s http://localhost:8000/api/v1/posts > /dev/null
        curl -s http://localhost:8000/health > /dev/null
        curl -s http://localhost:8000/metrics > /dev/null
        sleep 1
    done
    
    echo -e "${GREEN}✅ Sample data generated${NC}"
}

# Main execution
main() {
    echo -e "${YELLOW}🎯 Starting observability stack deployment...${NC}"
    
    # Check prerequisites
    check_main_system
    
    # Deploy services
    deploy_observability
    
    # Configure Grafana
    configure_grafana
    
    # Test everything
    test_observability
    
    # Generate sample data
    generate_sample_data
    
    echo -e "${GREEN}🎉 Observability stack deployed successfully!${NC}"
    echo ""
    echo -e "${BLUE}📊 Access URLs:${NC}"
    echo "   Grafana:      http://localhost:3000 (admin/admin123)"
    echo "   Prometheus:   http://localhost:9090"
    echo "   AlertManager: http://localhost:9093"
    echo "   Loki:         http://localhost:3100"
    echo "   Jaeger:       http://localhost:16686"
    echo "   cAdvisor:     http://localhost:8081"
    echo "   Node Exporter: http://localhost:9101"
    echo ""
    echo -e "${BLUE}🔧 Useful commands:${NC}"
    echo "   View logs:    docker compose -f deploy/observability/docker-compose.observability.yml logs -f"
    echo "   Stop stack:   docker compose -f deploy/observability/docker-compose.observability.yml down"
    echo "   Restart:      docker compose -f deploy/observability/docker-compose.observability.yml restart"
    echo ""
    echo -e "${YELLOW}💡 Next steps:${NC}"
    echo "   1. Open Grafana and explore the dashboards"
    echo "   2. Run load tests to see metrics in action"
    echo "   3. Configure alert notifications in AlertManager"
    echo "   4. Set up log queries in Loki"
}

# Run main function
main "$@"