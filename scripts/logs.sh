#!/bin/bash

set -e

ENVIRONMENT=${1:-dev}
SERVICE=${2:-app}

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

case $SERVICE in
    "app")
        echo -e "${YELLOW}Fetching application logs...${NC}"
        aws logs tail /aws/ec2/devops-safle-$ENVIRONMENT --follow
        ;;
    "alb")
        echo -e "${YELLOW}Fetching ALB logs...${NC}"
        aws logs tail /aws/elasticloadbalancing/devops-safle-$ENVIRONMENT --follow
        ;;
    "rds")
        echo -e "${YELLOW}Fetching RDS logs...${NC}"
        aws rds describe-db-log-files --db-instance-identifier devops-safle-$ENVIRONMENT
        ;;
    "monitoring")
        echo -e "${YELLOW}Fetching monitoring logs...${NC}"
        cd monitoring/
        docker-compose logs -f
        ;;
    *)
        echo "Usage: $0 <environment> <service>"
        echo "Services: app, alb, rds, monitoring"
        exit 1
        ;;
esac
