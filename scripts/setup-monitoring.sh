#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Setting up monitoring stack...${NC}"

# Create monitoring network if it doesn't exist
docker network ls | grep -q monitoring || docker network create monitoring

# Start monitoring services
cd monitoring/
docker-compose up -d

echo -e "${YELLOW}Waiting for services to start...${NC}"
sleep 30

# Check if services are running
docker-compose ps

echo -e "${GREEN}Monitoring stack setup complete!${NC}"
echo -e "${GREEN}Grafana: http://localhost:3000 (admin/admin123)${NC}"
echo -e "${GREEN}Prometheus: http://localhost:9090${NC}"
echo -e "${GREEN}AlertManager: http://localhost:9093${NC}"
