#!/bin/bash

set -e

ENVIRONMENT=${1:-dev}
BACKUP_DATE=$(date +%Y-%m-%d-%H-%M-%S)
S3_BUCKET=${BACKUP_S3_BUCKET:-devops-safle-backups}

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Starting backup for environment: $ENVIRONMENT${NC}"

# Get RDS instance identifier
RDS_INSTANCE=$(aws rds describe-db-instances --query "DBInstances[?contains(Tags[?Key=='Environment'].Value, '$ENVIRONMENT')].DBInstanceIdentifier" --output text)

if [ -n "$RDS_INSTANCE" ]; then
    echo -e "${YELLOW}Creating RDS snapshot...${NC}"
    
    SNAPSHOT_ID="$RDS_INSTANCE-$BACKUP_DATE"
    aws rds create-db-snapshot --db-instance-identifier $RDS_INSTANCE --db-snapshot-identifier $SNAPSHOT_ID
    
    # Wait for snapshot to complete
    aws rds wait db-snapshot-completed --db-snapshot-identifier $SNAPSHOT_ID
    
    echo -e "${GREEN}RDS snapshot created: $SNAPSHOT_ID${NC}"
fi

# Backup Terraform state
echo -e "${YELLOW}Backing up Terraform state...${NC}"
aws s3 cp terraform/environments/$ENVIRONMENT/terraform.tfstate s3://$S3_BUCKET/terraform-state/$ENVIRONMENT/terraform-$BACKUP_DATE.tfstate

# Backup configurations
echo -e "${YELLOW}Backing up configurations...${NC}"
tar -czf config-backup-$BACKUP_DATE.tar.gz terraform/ monitoring/ scripts/
aws s3 cp config-backup-$BACKUP_DATE.tar.gz s3://$S3_BUCKET/config-backups/
rm config-backup-$BACKUP_DATE.tar.gz

echo -e "${GREEN}Backup completed successfully!${NC}"

