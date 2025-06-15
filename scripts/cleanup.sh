#!/bin/bash

set -e

ENVIRONMENT=${1:-dev}
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Cleaning up resources for environment: $ENVIRONMENT${NC}"

# Confirm destruction
read -p "Are you sure you want to destroy all resources? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo -e "${YELLOW}Cleanup cancelled.${NC}"
    exit 0
fi

# Destroy Terraform resources
cd terraform/environments/$ENVIRONMENT
terraform destroy --auto-approve
cd - > /dev/null

# Clean up Docker images
echo -e "${YELLOW}Cleaning up Docker images...${NC}"
docker image prune -f
docker system prune -f

# Stop monitoring stack
echo -e "${YELLOW}Stopping monitoring stack...${NC}"
cd monitoring/
docker-compose down -v
cd - > /dev/null

echo -e "${GREEN}Cleanup completed!${NC}"
