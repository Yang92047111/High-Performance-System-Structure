#!/bin/bash

# Project Cleanup Script
# Helps maintain a clean and organized project structure

echo "🧹 Social Media App - Project Cleanup"
echo "====================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to ask for confirmation
confirm() {
    read -p "$(echo -e ${YELLOW}$1${NC}) [y/N]: " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

echo -e "\n${BLUE}🔍 Analyzing project for cleanup opportunities...${NC}"

# Check for large log files
LARGE_LOGS=$(find . -name "*.log" -size +10M 2>/dev/null)
if [ ! -z "$LARGE_LOGS" ]; then
    echo -e "\n${YELLOW}📋 Large log files found (>10MB):${NC}"
    echo "$LARGE_LOGS"
    if confirm "Remove large log files?"; then
        find . -name "*.log" -size +10M -delete
        echo -e "${GREEN}✓ Large log files removed${NC}"
    fi
fi

# Check for old test results
OLD_RESULTS=$(find results/ -name "*.json" -mtime +7 2>/dev/null)
if [ ! -z "$OLD_RESULTS" ]; then
    echo -e "\n${YELLOW}📊 Old test results found (>7 days):${NC}"
    echo "$OLD_RESULTS"
    if confirm "Archive old test results?"; then
        mkdir -p results/archive/$(date +%Y-%m-%d)
        find results/ -name "*.json" -mtime +7 -exec mv {} results/archive/$(date +%Y-%m-%d)/ \;
        echo -e "${GREEN}✓ Old test results archived${NC}"
    fi
fi

# Check for temporary files
TEMP_FILES=$(find . -name "*.tmp" -o -name "*.temp" -o -name ".DS_Store" 2>/dev/null)
if [ ! -z "$TEMP_FILES" ]; then
    echo -e "\n${YELLOW}🗑️  Temporary files found:${NC}"
    echo "$TEMP_FILES"
    if confirm "Remove temporary files?"; then
        find . -name "*.tmp" -o -name "*.temp" -o -name ".DS_Store" -delete
        echo -e "${GREEN}✓ Temporary files removed${NC}"
    fi
fi

# Check Docker resources
echo -e "\n${BLUE}🐳 Docker resource usage:${NC}"
docker system df

if confirm "Clean up unused Docker resources?"; then
    docker system prune -f
    echo -e "${GREEN}✓ Docker resources cleaned${NC}"
fi

# Validate project structure
echo -e "\n${BLUE}🔍 Validating project structure...${NC}"
if [ -f "scripts/validate-project.sh" ]; then
    chmod +x scripts/validate-project.sh
    ./scripts/validate-project.sh
else
    echo -e "${RED}❌ Validation script not found${NC}"
fi

# Summary
echo -e "\n${GREEN}🎉 Project cleanup completed!${NC}"
echo -e "\n${BLUE}💡 Maintenance tips:${NC}"
echo "  • Run 'make clean-all' for complete cleanup"
echo "  • Use 'make validate' to check project structure"
echo "  • Monitor disk usage with 'du -sh results/'"
echo "  • Archive old results regularly"

echo -e "\n${BLUE}📊 Current project size:${NC}"
du -sh . 2>/dev/null || echo "Unable to calculate size"