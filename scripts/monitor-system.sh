#!/bin/bash

echo "📊 System Monitoring During Load Tests"
echo "======================================"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Create monitoring results directory
mkdir -p results/monitoring

# Function to monitor Docker stats
monitor_docker() {
    echo -e "${BLUE}🐳 Monitoring Docker container resources...${NC}"
    
    # Monitor for 10 minutes with 5-second intervals
    for i in {1..120}; do
        echo "$(date): Docker Stats Sample $i" >> results/monitoring/docker-stats.log
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" >> results/monitoring/docker-stats.log
        echo "" >> results/monitoring/docker-stats.log
        sleep 5
    done
}

# Function to monitor system resources
monitor_system() {
    echo -e "${BLUE}💻 Monitoring system resources...${NC}"
    
    for i in {1..120}; do
        echo "$(date): System Stats Sample $i" >> results/monitoring/system-stats.log
        
        # CPU usage
        echo "CPU Usage:" >> results/monitoring/system-stats.log
        top -l 1 -n 0 | grep "CPU usage" >> results/monitoring/system-stats.log 2>/dev/null || \
        grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print "CPU Usage: " usage "%"}' >> results/monitoring/system-stats.log 2>/dev/null
        
        # Memory usage
        echo "Memory Usage:" >> results/monitoring/system-stats.log
        if [[ "$OSTYPE" == "darwin"* ]]; then
            vm_stat | head -5 >> results/monitoring/system-stats.log
        else
            free -h >> results/monitoring/system-stats.log
        fi
        
        # Disk I/O
        echo "Disk Usage:" >> results/monitoring/system-stats.log
        df -h | head -5 >> results/monitoring/system-stats.log
        
        echo "----------------------------------------" >> results/monitoring/system-stats.log
        sleep 5
    done
}

# Function to monitor application metrics
monitor_app_metrics() {
    echo -e "${BLUE}📈 Monitoring application metrics...${NC}"
    
    for i in {1..120}; do
        echo "$(date): App Metrics Sample $i" >> results/monitoring/app-metrics.log
        
        # Get Prometheus metrics
        curl -s http://localhost:8000/metrics | grep -E "(http_requests_total|http_request_duration|users_registered_total|posts_created_total|messages_created_total|websocket_connections_active)" >> results/monitoring/app-metrics.log
        
        echo "----------------------------------------" >> results/monitoring/app-metrics.log
        sleep 5
    done
}

# Function to monitor database connections
monitor_database() {
    echo -e "${BLUE}🗄️ Monitoring database performance...${NC}"
    
    for i in {1..120}; do
        echo "$(date): Database Stats Sample $i" >> results/monitoring/db-stats.log
        
        # PostgreSQL stats
        docker exec social-media-postgres psql -U postgres -d social_media -c "
        SELECT 
            datname,
            numbackends as active_connections,
            xact_commit as transactions_committed,
            xact_rollback as transactions_rolled_back,
            blks_read as blocks_read,
            blks_hit as blocks_hit,
            tup_returned as tuples_returned,
            tup_fetched as tuples_fetched,
            tup_inserted as tuples_inserted,
            tup_updated as tuples_updated,
            tup_deleted as tuples_deleted
        FROM pg_stat_database 
        WHERE datname = 'social_media';
        " >> results/monitoring/db-stats.log 2>/dev/null
        
        echo "----------------------------------------" >> results/monitoring/db-stats.log
        sleep 5
    done
}

# Function to monitor Redis performance
monitor_redis() {
    echo -e "${BLUE}⚡ Monitoring Redis performance...${NC}"
    
    for i in {1..120}; do
        echo "$(date): Redis Stats Sample $i" >> results/monitoring/redis-stats.log
        
        # Redis info
        docker exec social-media-redis redis-cli INFO stats | grep -E "(total_commands_processed|total_connections_received|keyspace_hits|keyspace_misses|used_memory_human|connected_clients)" >> results/monitoring/redis-stats.log
        
        echo "----------------------------------------" >> results/monitoring/redis-stats.log
        sleep 5
    done
}

# Function to create real-time dashboard
create_dashboard() {
    echo -e "${BLUE}📊 Creating real-time monitoring dashboard...${NC}"
    
    cat > results/monitoring/dashboard.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Load Test Monitoring Dashboard</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; }
        .metric-card { background: white; padding: 20px; margin: 10px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .metric-title { font-size: 18px; font-weight: bold; color: #333; margin-bottom: 10px; }
        .metric-value { font-size: 24px; color: #007bff; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
        .status-good { color: #28a745; }
        .status-warning { color: #ffc107; }
        .status-error { color: #dc3545; }
        .refresh-btn { background: #007bff; color: white; padding: 10px 20px; border: none; border-radius: 4px; cursor: pointer; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Social Media System - Load Test Monitoring</h1>
        <button class="refresh-btn" onclick="location.reload()">🔄 Refresh</button>
        
        <div class="grid">
            <div class="metric-card">
                <div class="metric-title">🌐 System Status</div>
                <div class="metric-value status-good" id="system-status">Monitoring Active</div>
            </div>
            
            <div class="metric-card">
                <div class="metric-title">📊 Current Time</div>
                <div class="metric-value" id="current-time"></div>
            </div>
            
            <div class="metric-card">
                <div class="metric-title">🐳 Docker Containers</div>
                <div class="metric-value">5 Running</div>
            </div>
            
            <div class="metric-card">
                <div class="metric-title">📈 Monitoring Duration</div>
                <div class="metric-value">10 minutes</div>
            </div>
        </div>
        
        <div class="metric-card">
            <div class="metric-title">📋 Monitoring Commands</div>
            <p><strong>View Docker Stats:</strong> <code>tail -f results/monitoring/docker-stats.log</code></p>
            <p><strong>View System Stats:</strong> <code>tail -f results/monitoring/system-stats.log</code></p>
            <p><strong>View App Metrics:</strong> <code>tail -f results/monitoring/app-metrics.log</code></p>
            <p><strong>View Database Stats:</strong> <code>tail -f results/monitoring/db-stats.log</code></p>
            <p><strong>View Redis Stats:</strong> <code>tail -f results/monitoring/redis-stats.log</code></p>
        </div>
        
        <div class="metric-card">
            <div class="metric-title">🔗 Quick Links</div>
            <p><a href="http://localhost:8000/metrics" target="_blank">📊 Prometheus Metrics</a></p>
            <p><a href="http://localhost:8080" target="_blank">🌐 Frontend Application</a></p>
            <p><a href="http://localhost:9001" target="_blank">📦 MinIO Console</a></p>
        </div>
    </div>
    
    <script>
        function updateTime() {
            document.getElementById('current-time').textContent = new Date().toLocaleString();
        }
        updateTime();
        setInterval(updateTime, 1000);
    </script>
</body>
</html>
EOF

    echo -e "${GREEN}✅ Dashboard created: results/monitoring/dashboard.html${NC}"
    echo "Open in browser: file://$(pwd)/results/monitoring/dashboard.html"
}

# Main monitoring function
main() {
    echo -e "${YELLOW}Starting system monitoring for load tests...${NC}"
    echo "Monitoring will run for 10 minutes (120 samples at 5-second intervals)"
    echo ""
    
    # Create dashboard
    create_dashboard
    
    # Start monitoring in background
    monitor_docker &
    DOCKER_PID=$!
    
    monitor_system &
    SYSTEM_PID=$!
    
    monitor_app_metrics &
    METRICS_PID=$!
    
    monitor_database &
    DB_PID=$!
    
    monitor_redis &
    REDIS_PID=$!
    
    echo -e "${GREEN}✅ Monitoring started with PIDs:${NC}"
    echo "   Docker: $DOCKER_PID"
    echo "   System: $SYSTEM_PID"
    echo "   Metrics: $METRICS_PID"
    echo "   Database: $DB_PID"
    echo "   Redis: $REDIS_PID"
    echo ""
    echo -e "${BLUE}📊 View real-time dashboard:${NC}"
    echo "   file://$(pwd)/results/monitoring/dashboard.html"
    echo ""
    echo -e "${YELLOW}⏳ Monitoring for 10 minutes...${NC}"
    
    # Wait for monitoring to complete
    wait $DOCKER_PID $SYSTEM_PID $METRICS_PID $DB_PID $REDIS_PID
    
    echo -e "${GREEN}✅ Monitoring completed!${NC}"
    echo ""
    echo -e "${BLUE}📊 Results saved to:${NC}"
    echo "   - results/monitoring/docker-stats.log"
    echo "   - results/monitoring/system-stats.log"
    echo "   - results/monitoring/app-metrics.log"
    echo "   - results/monitoring/db-stats.log"
    echo "   - results/monitoring/redis-stats.log"
    echo "   - results/monitoring/dashboard.html"
}

# Handle Ctrl+C gracefully
trap 'echo -e "\n${YELLOW}⚠️  Monitoring interrupted by user${NC}"; exit 0' INT

# Run main function
main "$@"