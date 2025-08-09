.PHONY: help dev build test clean logs stop restart health-check

# Default target
.DEFAULT_GOAL := help

# =============================================================================
# HELP & DOCUMENTATION
# =============================================================================

help: ## Show this help message
	@echo "🚀 Social Media App - Development Commands"
	@echo "=========================================="
	@echo ""
	@echo "📋 DEVELOPMENT:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*Development.*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "🐳 DOCKER & SERVICES:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*Docker.*$$|^[a-zA-Z_-]+:.*?## .*service.*$$|^[a-zA-Z_-]+:.*?## .*container.*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "🧪 TESTING:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*Test.*$$|^[a-zA-Z_-]+:.*?## .*load.*$$|^[a-zA-Z_-]+:.*?## .*benchmark.*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "🚀 DEPLOYMENT:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*Deploy.*$$|^[a-zA-Z_-]+:.*?## .*Kubernetes.*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "📊 MONITORING:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*monitor.*$$|^[a-zA-Z_-]+:.*?## .*metrics.*$$|^[a-zA-Z_-]+:.*?## .*observability.*$$|^[a-zA-Z_-]+:.*?## .*Grafana.*$$|^[a-zA-Z_-]+:.*?## .*Prometheus.*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "🛠️  UTILITIES:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*Clean.*$$|^[a-zA-Z_-]+:.*?## .*shell.*$$|^[a-zA-Z_-]+:.*?## .*status.*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# =============================================================================
# DEVELOPMENT COMMANDS
# =============================================================================

dev: ## Development - Start development environment
	@echo "🚀 Starting development environment..."
	@chmod +x scripts/dev-setup.sh
	@./scripts/dev-setup.sh

dev-fresh: ## Development - Fresh start (clean + dev)
	@echo "🔄 Fresh development start..."
	@make clean
	@make dev

# =============================================================================
# DOCKER & SERVICE MANAGEMENT
# =============================================================================

build: ## Docker - Build all services
	@echo "🔨 Building all services..."
	@docker compose build

up: ## Docker - Start all services
	@echo "▶️  Starting all services..."
	@docker compose up -d

down: ## Docker - Stop all services
	@echo "⏹️  Stopping all services..."
	@docker compose down

restart: ## Docker - Restart all services
	@echo "🔄 Restarting all services..."
	@docker compose restart

logs: ## Docker - Show logs for all services
	@echo "📋 Showing logs..."
	@docker compose logs -f

logs-backend: ## Docker - Show backend logs
	@docker compose logs -f backend

logs-frontend: ## Docker - Show frontend logs
	@docker compose logs -f frontend

logs-db: ## Docker - Show database logs
	@docker compose logs -f postgres

logs-redis: ## Docker - Show Redis logs
	@docker compose logs -f redis

# =============================================================================
# HEALTH & STATUS CHECKS
# =============================================================================

health-check: ## Docker - Check health of all services
	@echo "🏥 Checking service health..."
	@docker compose ps
	@echo ""
	@echo "🔍 Service endpoints:"
	@echo "  Frontend:  http://localhost:8080"
	@echo "  Backend:   http://localhost:8000"
	@echo "  MinIO:     http://localhost:9001"
	@echo ""
	@echo "🧪 Quick API test:"
	@curl -s http://localhost:8000/api/v1/health || echo "❌ Backend not responding"

status: ## Docker - Show service status
	@echo "📊 Service Status:"
	@docker compose ps

# =============================================================================
# TESTING COMMANDS
# =============================================================================

test-api: ## Test - API endpoints
	@echo "🧪 Testing API..."
	@chmod +x scripts/test-api.sh
	@./scripts/test-api.sh

test-phase2: ## Test - Phase 2 features (JWT, Database, etc.)
	@echo "🧪 Testing Phase 2 features..."
	@chmod +x scripts/test-phase2.sh
	@./scripts/test-phase2.sh

test-phase3: ## Test - Phase 3 features (Real-time, Caching, Rate Limiting)
	@echo "🧪 Testing Phase 3 features..."
	@chmod +x scripts/test-phase3.sh
	@./scripts/test-phase3.sh

test-all: ## Test - Run all test suites
	@echo "🧪 Running all tests..."
	@make test-api
	@make test-phase2
	@make test-phase3

# =============================================================================
# LOAD TESTING & BENCHMARKS
# =============================================================================

load-test: ## Test - Run comprehensive load tests
	@echo "🚀 Running load tests..."
	@chmod +x scripts/run-load-tests.sh
	@./scripts/run-load-tests.sh

load-test-basic: ## Test - Run basic k6 load test
	@echo "🎯 Running basic load test..."
	@mkdir -p results
	@k6 run --out json=results/k6-basic-results.json scripts/load-tests/k6-basic-load.js

load-test-stress: ## Test - Run stress test to find breaking point
	@echo "💥 Running stress test..."
	@mkdir -p results
	@k6 run --out json=results/k6-stress-results.json scripts/load-tests/k6-stress-test.js

load-test-websocket: ## Test - WebSocket scalability
	@echo "🔌 Running WebSocket load test..."
	@mkdir -p results
	@k6 run --out json=results/k6-websocket-results.json scripts/load-tests/k6-websocket-test.js

load-test-spike: ## Test - Traffic surge simulation
	@echo "⚡ Running spike load test..."
	@mkdir -p results
	@k6 run --out json=results/k6-spike-results.json scripts/load-tests/k6-spike-test.js

load-test-chaos: ## Test - Chaos engineering tests
	@echo "🌪️  Running chaos engineering test..."
	@mkdir -p results
	@k6 run --out json=results/k6-chaos-results.json scripts/load-tests/k6-chaos-test.js

load-test-endurance: ## Test - 1-hour endurance test
	@echo "🏃‍♂️ Running endurance test (1 hour)..."
	@mkdir -p results
	@k6 run --out json=results/k6-endurance-results.json scripts/load-tests/k6-endurance-test.js

load-test-advanced: ## Test - Run Phase 4 advanced load tests
	@echo "🚀 Running advanced load tests..."
	@chmod +x scripts/run-advanced-tests.sh
	@./scripts/run-advanced-tests.sh

benchmark: ## Test - Quick performance benchmark
	@echo "⚡ Running performance benchmark..."
	@echo "Testing 1000 requests with 50 concurrent connections..."
	@wrk -t10 -c50 -d30s http://localhost:8000/api/v1/posts || echo "Install wrk for benchmarking"

# =============================================================================
# DEPLOYMENT COMMANDS
# =============================================================================

deploy-k8s: ## Deploy - Kubernetes deployment
	@echo "🚀 Deploying to Kubernetes..."
	@chmod +x scripts/deploy-k8s.sh
	@./scripts/deploy-k8s.sh

deploy-helm: ## Deploy - Helm deployment
	@echo "🚀 Deploying with Helm..."
	@chmod +x scripts/deploy-helm.sh
	@./scripts/deploy-helm.sh

deploy-observability: ## Deploy - Advanced monitoring stack (Prometheus, Grafana, etc.)
	@echo "📊 Deploying observability stack..."
	@chmod +x scripts/deploy-observability.sh
	@./scripts/deploy-observability.sh

# =============================================================================
# MONITORING & OBSERVABILITY
# =============================================================================

metrics: ## Monitoring - View Prometheus metrics
	@echo "📊 Opening metrics endpoint..."
	@open http://localhost:8000/metrics || xdg-open http://localhost:8000/metrics || echo "Visit http://localhost:8000/metrics"

grafana: ## Monitoring - Open Grafana dashboards
	@echo "📊 Opening Grafana..."
	@open http://localhost:3000 || xdg-open http://localhost:3000 || echo "Visit http://localhost:3000 (admin/admin123)"

prometheus: ## Monitoring - Open Prometheus
	@echo "📈 Opening Prometheus..."
	@open http://localhost:9090 || xdg-open http://localhost:9090 || echo "Visit http://localhost:9090"

jaeger: ## Monitoring - Open Jaeger tracing
	@echo "🔍 Opening Jaeger..."
	@open http://localhost:16686 || xdg-open http://localhost:16686 || echo "Visit http://localhost:16686"

monitor: ## Monitoring - Monitor system during load tests
	@echo "📊 Starting system monitoring..."
	@chmod +x scripts/monitor-system.sh
	@./scripts/monitor-system.sh

observability-down: ## Monitoring - Stop observability stack
	@echo "⏹️  Stopping observability stack..."
	@docker compose -f deploy/observability/docker-compose.observability.yml down

# =============================================================================
# UTILITY COMMANDS
# =============================================================================

clean: ## Clean - Clean up containers and volumes
	@echo "🧹 Cleaning up..."
	@docker compose down -v
	@docker system prune -f

clean-results: ## Clean - Remove test results
	@echo "🧹 Cleaning test results..."
	@rm -rf results/*.json results/*.txt results/monitoring/*.log

clean-all: ## Clean - Complete cleanup (containers, volumes, results)
	@echo "🧹 Complete cleanup..."
	@make clean
	@make clean-results
	@docker image prune -f

cleanup-project: ## Clean - Interactive project cleanup with analysis
	@echo "🧹 Running interactive project cleanup..."
	@chmod +x scripts/cleanup-project.sh
	@./scripts/cleanup-project.sh

shell-backend: ## Utility - Open shell in backend container
	@docker compose exec backend sh

shell-frontend: ## Utility - Open shell in frontend container
	@docker compose exec frontend sh

shell-db: ## Utility - Open PostgreSQL shell
	@docker compose exec postgres psql -U postgres -d social_media

shell-redis: ## Utility - Open Redis CLI
	@docker compose exec redis redis-cli

# =============================================================================
# CI/CD & AUTOMATION
# =============================================================================

ci-test: ## CI/CD - Run CI/CD pipeline tests locally
	@echo "🔄 Running CI/CD tests..."
	@echo "This simulates the GitHub Actions pipeline"
	@make test-phase3
	@make load-test-basic
	@echo "✅ CI/CD tests completed"

pre-commit: ## CI/CD - Run pre-commit checks
	@echo "🔍 Running pre-commit checks..."
	@make health-check
	@make test-api
	@echo "✅ Pre-commit checks passed"

validate: ## CI/CD - Validate project structure
	@echo "🔍 Validating project structure..."
	@chmod +x scripts/validate-project.sh
	@./scripts/validate-project.sh

# =============================================================================
# QUICK ACCESS COMMANDS
# =============================================================================

frontend: ## Quick - Open frontend in browser
	@open http://localhost:8080 || xdg-open http://localhost:8080 || echo "Visit http://localhost:8080"

backend: ## Quick - Open backend API docs
	@open http://localhost:8000 || xdg-open http://localhost:8000 || echo "Visit http://localhost:8000"

minio: ## Quick - Open MinIO console
	@open http://localhost:9001 || xdg-open http://localhost:9001 || echo "Visit http://localhost:9001 (admin/minioadmin)"

all-services: ## Quick - Open all service URLs
	@make frontend
	@make backend
	@make minio
	@make grafana