#!/bin/bash

echo "🚀 High-Traffic Load Testing Suite for Social Media System"
echo "=========================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if system is running
check_system() {
    echo -e "${BLUE}🔍 Checking if system is running...${NC}"
    
    if ! curl -s http://localhost:8000/health > /dev/null; then
        echo -e "${RED}❌ System is not running! Please start with 'make dev' first.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ System is running and healthy${NC}"
}

# Install dependencies if needed
install_dependencies() {
    echo -e "${BLUE}📦 Checking load testing tools...${NC}"
    
    # Check for k6
    if ! command -v k6 &> /dev/null; then
        echo -e "${YELLOW}⚠️  k6 not found. Installing...${NC}"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install k6
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            sudo gpg -k
            sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
            echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
            sudo apt-get update
            sudo apt-get install k6
        fi
    fi
    
    # Check for wrk
    if ! command -v wrk &> /dev/null; then
        echo -e "${YELLOW}⚠️  wrk not found. Please install wrk for additional tests.${NC}"
        echo "   macOS: brew install wrk"
        echo "   Ubuntu: sudo apt-get install wrk"
    fi
    
    # Check for artillery
    if ! command -v artillery &> /dev/null; then
        echo -e "${YELLOW}⚠️  artillery not found. Installing via npm...${NC}"
        npm install -g artillery
    fi
}

# Run k6 basic load test
run_k6_basic() {
    echo -e "${BLUE}🎯 Running k6 Basic Load Test...${NC}"
    echo "Target: 500 concurrent users over 26 minutes"
    echo "Expected: <200ms P95 latency, <10% error rate"
    echo ""
    
    k6 run --out json=results/k6-basic-results.json scripts/load-tests/k6-basic-load.js
    
    echo -e "${GREEN}✅ k6 Basic Load Test completed${NC}"
    echo ""
}

# Run k6 stress test
run_k6_stress() {
    echo -e "${BLUE}💥 Running k6 Stress Test...${NC}"
    echo "Target: Up to 1200 concurrent users"
    echo "Purpose: Find system breaking point"
    echo ""
    
    k6 run --out json=results/k6-stress-results.json scripts/load-tests/k6-stress-test.js
    
    echo -e "${GREEN}✅ k6 Stress Test completed${NC}"
    echo ""
}

# Run k6 WebSocket test
run_k6_websocket() {
    echo -e "${BLUE}🔌 Running k6 WebSocket Test...${NC}"
    echo "Target: 500 concurrent WebSocket connections"
    echo "Purpose: Test real-time messaging scalability"
    echo ""
    
    k6 run --out json=results/k6-websocket-results.json scripts/load-tests/k6-websocket-test.js
    
    echo -e "${GREEN}✅ k6 WebSocket Test completed${NC}"
    echo ""
}

# Run wrk tests
run_wrk_tests() {
    if command -v wrk &> /dev/null; then
        echo -e "${BLUE}⚡ Running wrk Load Tests...${NC}"
        
        echo "Basic Load Test (100 connections, 10 threads, 2 minutes):"
        wrk -t10 -c100 -d2m -s scripts/load-tests/wrk-basic.lua http://localhost:8000 > results/wrk-basic-results.txt
        
        echo ""
        echo "Stress Test (500 connections, 20 threads, 3 minutes):"
        wrk -t20 -c500 -d3m -s scripts/load-tests/wrk-stress.lua http://localhost:8000 > results/wrk-stress-results.txt
        
        echo -e "${GREEN}✅ wrk tests completed${NC}"
        echo ""
    else
        echo -e "${YELLOW}⚠️  Skipping wrk tests (not installed)${NC}"
    fi
}

# Run artillery test
run_artillery_test() {
    if command -v artillery &> /dev/null; then
        echo -e "${BLUE}🎪 Running Artillery Load Test...${NC}"
        
        cd scripts/load-tests
        artillery run artillery-config.yml --output ../../results/artillery-results.json
        cd ../..
        
        echo -e "${GREEN}✅ Artillery test completed${NC}"
        echo ""
    else
        echo -e "${YELLOW}⚠️  Skipping Artillery test (not installed)${NC}"
    fi
}

# Generate summary report
generate_report() {
    echo -e "${BLUE}📊 Generating Load Test Summary Report...${NC}"
    
    cat > results/load-test-summary.md << EOF
# Load Test Results Summary

Generated: $(date)

## Test Environment
- Target: http://localhost:8000
- System: Social Media Application
- Database: PostgreSQL with Redis caching
- WebSocket: Real-time messaging enabled

## Tests Executed

### k6 Basic Load Test
- **Objective**: Validate normal operation under load
- **Peak Load**: 500 concurrent users
- **Duration**: 26 minutes
- **Results**: See k6-basic-results.json

### k6 Stress Test  
- **Objective**: Find system breaking point
- **Peak Load**: 1200 concurrent users
- **Duration**: 20 minutes
- **Results**: See k6-stress-results.json

### k6 WebSocket Test
- **Objective**: Test real-time messaging scalability
- **Peak Load**: 500 concurrent WebSocket connections
- **Duration**: 9.5 minutes
- **Results**: See k6-websocket-results.json

### wrk Tests
- **Basic Load**: 100 connections, 2 minutes
- **Stress Test**: 500 connections, 3 minutes
- **Results**: See wrk-*-results.txt

### Artillery Test
- **Peak Load**: 500 requests/second
- **Duration**: Variable phases
- **Results**: See artillery-results.json

## Key Metrics to Analyze

1. **Response Times**
   - P50, P95, P99 latencies
   - Target: P95 < 200ms for normal load

2. **Throughput**
   - Requests per second
   - Target: 16,667 RPS (1M requests/minute)

3. **Error Rates**
   - HTTP 5xx errors
   - Target: < 1% error rate

4. **WebSocket Performance**
   - Connection success rate
   - Message delivery latency

5. **System Resources**
   - Check Docker stats during tests
   - Monitor with: docker stats

## Next Steps

1. Analyze detailed results in JSON files
2. Check system logs: docker compose logs
3. Review Prometheus metrics: http://localhost:8000/metrics
4. Scale system if needed and re-test
5. Consider Kubernetes deployment for higher loads

EOF

    echo -e "${GREEN}✅ Summary report generated: results/load-test-summary.md${NC}"
}

# Main execution
main() {
    # Create results directory
    mkdir -p results
    
    # Check system status
    check_system
    
    # Install dependencies
    install_dependencies
    
    echo -e "${YELLOW}🎯 Starting comprehensive load testing...${NC}"
    echo "This will take approximately 1 hour to complete all tests."
    echo ""
    
    # Ask user which tests to run
    echo "Select tests to run:"
    echo "1) All tests (recommended)"
    echo "2) k6 tests only"
    echo "3) Quick test (basic load only)"
    echo "4) WebSocket test only"
    
    read -p "Enter choice (1-4): " choice
    
    case $choice in
        1)
            echo -e "${GREEN}Running all load tests...${NC}"
            run_k6_basic
            run_k6_stress
            run_k6_websocket
            run_wrk_tests
            run_artillery_test
            ;;
        2)
            echo -e "${GREEN}Running k6 tests only...${NC}"
            run_k6_basic
            run_k6_stress
            run_k6_websocket
            ;;
        3)
            echo -e "${GREEN}Running quick basic load test...${NC}"
            run_k6_basic
            ;;
        4)
            echo -e "${GREEN}Running WebSocket test only...${NC}"
            run_k6_websocket
            ;;
        *)
            echo -e "${RED}Invalid choice. Running basic test.${NC}"
            run_k6_basic
            ;;
    esac
    
    # Generate summary
    generate_report
    
    echo -e "${GREEN}🎉 Load testing completed!${NC}"
    echo ""
    echo -e "${BLUE}📊 Results available in:${NC}"
    echo "   - results/ directory"
    echo "   - results/load-test-summary.md"
    echo ""
    echo -e "${BLUE}🔍 To analyze results:${NC}"
    echo "   - Check JSON files for detailed metrics"
    echo "   - Monitor system: docker stats"
    echo "   - View metrics: http://localhost:8000/metrics"
}

# Run main function
main "$@"