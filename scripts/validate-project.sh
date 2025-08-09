#!/bin/bash

# Project Structure Validation Script
# This script checks the project structure and identifies any issues

echo "🔍 Validating Project Structure..."
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
ERRORS=0
WARNINGS=0
CHECKS=0

# Function to check if file exists
check_file() {
    local file=$1
    local description=$2
    CHECKS=$((CHECKS + 1))
    
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $description: $file"
    else
        echo -e "${RED}✗${NC} $description: $file (missing)"
        ERRORS=$((ERRORS + 1))
    fi
}

# Function to check if directory exists
check_dir() {
    local dir=$1
    local description=$2
    CHECKS=$((CHECKS + 1))
    
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✓${NC} $description: $dir"
    else
        echo -e "${RED}✗${NC} $description: $dir (missing)"
        ERRORS=$((ERRORS + 1))
    fi
}

# Function to check if file is executable
check_executable() {
    local file=$1
    local description=$2
    CHECKS=$((CHECKS + 1))
    
    if [ -f "$file" ] && [ -x "$file" ]; then
        echo -e "${GREEN}✓${NC} $description: $file"
    elif [ -f "$file" ]; then
        echo -e "${YELLOW}⚠${NC} $description: $file (not executable)"
        WARNINGS=$((WARNINGS + 1))
    else
        echo -e "${RED}✗${NC} $description: $file (missing)"
        ERRORS=$((ERRORS + 1))
    fi
}

echo -e "\n${BLUE}📋 Core Project Files${NC}"
check_file "README.md" "Main documentation"
check_file "Makefile" "Build system"
check_file "docker-compose.yaml" "Docker services"
check_file ".gitignore" "Git ignore"
check_file "PROJECT-STRUCTURE.md" "Project structure docs"

echo -e "\n${BLUE}🔧 Backend Structure${NC}"
check_dir "backend" "Backend directory"
check_file "backend/Dockerfile" "Backend Dockerfile"
check_file "backend/go.mod" "Go module"
check_file "backend/cmd/main.go" "Main application"
check_dir "backend/internal" "Internal packages"

echo -e "\n${BLUE}🎨 Frontend Structure${NC}"
check_dir "frontend" "Frontend directory"
check_file "frontend/Dockerfile" "Frontend Dockerfile"
check_file "frontend/package.json" "Node.js dependencies"
check_file "frontend/index.html" "Main HTML"

echo -e "\n${BLUE}🗄️ Database${NC}"
check_dir "db" "Database directory"
check_file "db/schema.sql" "Database schema"

echo -e "\n${BLUE}🚀 Deployment${NC}"
check_dir "deploy" "Deployment directory"
check_dir "deploy/k8s" "Kubernetes manifests"
check_dir "deploy/helm" "Helm charts"
check_dir "deploy/observability" "Monitoring stack"

echo -e "\n${BLUE}🧪 Scripts${NC}"
check_dir "scripts" "Scripts directory"
check_executable "scripts/dev-setup.sh" "Development setup"
check_executable "scripts/test-api.sh" "API testing"
check_dir "scripts/load-tests" "Load testing scripts"

echo -e "\n${BLUE}📊 Results${NC}"
check_dir "results" "Results directory"

# Check for common issues
echo -e "\n${BLUE}🔍 Common Issues Check${NC}"

# Check for large files that shouldn't be committed
if find . -name "*.log" -size +10M 2>/dev/null | grep -q .; then
    echo -e "${YELLOW}⚠${NC} Large log files found (>10MB)"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}✓${NC} No large log files"
fi
CHECKS=$((CHECKS + 1))

# Check for node_modules in git
if [ -d "frontend/node_modules" ] && ! grep -q "node_modules" .gitignore; then
    echo -e "${YELLOW}⚠${NC} node_modules not in .gitignore"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}✓${NC} node_modules properly ignored"
fi
CHECKS=$((CHECKS + 1))

# Check for .env files
if [ -f ".env" ]; then
    if grep -q ".env" .gitignore; then
        echo -e "${GREEN}✓${NC} .env file properly ignored"
    else
        echo -e "${YELLOW}⚠${NC} .env file not in .gitignore"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo -e "${YELLOW}⚠${NC} No .env file found"
    WARNINGS=$((WARNINGS + 1))
fi
CHECKS=$((CHECKS + 1))

# Summary
echo -e "\n${BLUE}📊 Validation Summary${NC}"
echo "======================"
echo "Total checks: $CHECKS"
echo -e "Passed: ${GREEN}$((CHECKS - ERRORS - WARNINGS))${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"
echo -e "Errors: ${RED}$ERRORS${NC}"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "\n${GREEN}🎉 Project structure is perfect!${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "\n${YELLOW}⚠ Project structure is good with minor warnings${NC}"
    exit 0
else
    echo -e "\n${RED}❌ Project structure has issues that need attention${NC}"
    exit 1
fi