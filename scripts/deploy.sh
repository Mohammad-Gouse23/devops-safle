
#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT=${1:-dev}
AWS_REGION=${AWS_REGION:-us-west-2}
ECR_REPOSITORY=${ECR_REPOSITORY:-devops-safle}
IMAGE_TAG=${2:-latest}

echo -e "${GREEN}Starting deployment for environment: $ENVIRONMENT${NC}"

# Check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"
    
    # Check if required tools are installed
    command -v aws >/dev/null 2>&1 || { echo -e "${RED}AWS CLI is required but not installed.${NC}" >&2; exit 1; }
    command -v terraform >/dev/null 2>&1 || { echo -e "${RED}Terraform is required but not installed.${NC}" >&2; exit 1; }
    command -v docker >/dev/null 2>&1 || { echo -e "${RED}Docker is required but not installed.${NC}" >&2; exit 1; }
    
    # Check AWS credentials
    aws sts get-caller-identity >/dev/null 2>&1 || { echo -e "${RED}AWS credentials not configured.${NC}" >&2; exit 1; }
    
    echo -e "${GREEN}Prerequisites check passed!${NC}"
}

# Build and push Docker image
build_and_push_image() {
    echo -e "${YELLOW}Building and pushing Docker image...${NC}"
    
    # Get ECR login token
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.$AWS_REGION.amazonaws.com
    
    # Build image
    docker build -t $ECR_REPOSITORY:$IMAGE_TAG ./app/
    
    # Tag image for ECR
    ECR_URI=$(aws sts get-caller-identity --query Account --output text).dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$IMAGE_TAG
    docker tag $ECR_REPOSITORY:$IMAGE_TAG $ECR_URI
    
    # Push to ECR
    docker push $ECR_URI
    
    echo -e "${GREEN}Image pushed successfully: $ECR_URI${NC}"
}

# Deploy infrastructure
deploy_infrastructure() {
    echo -e "${YELLOW}Deploying infrastructure with Terraform...${NC}"
    
    cd terraform/environments/$ENVIRONMENT
    
    # Initialize Terraform
    terraform init
    
    # Plan deployment
    terraform plan -var="image_tag=$IMAGE_TAG" -out=tfplan
    
    # Apply changes
    terraform apply tfplan
    
    cd - > /dev/null
    
    echo -e "${GREEN}Infrastructure deployed successfully!${NC}"
}

# Deploy application
deploy_application() {
    echo -e "${YELLOW}Deploying application...${NC}"
    
    # Get Auto Scaling Group name
    ASG_NAME=$(aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[?contains(Tags[?Key=='Environment'].Value, '$ENVIRONMENT')].AutoScalingGroupName" --output text)
    
    if [ -z "$ASG_NAME" ]; then
        echo -e "${RED}Auto Scaling Group not found for environment: $ENVIRONMENT${NC}"
        exit 1
    fi
    
    # Trigger instance refresh
    aws autoscaling start-instance-refresh --auto-scaling-group-name $ASG_NAME --preferences '{"InstanceWarmup": 300, "MinHealthyPercentage": 50}'
    
    echo -e "${GREEN}Application deployment initiated!${NC}"
}

# Health check
health_check() {
    echo -e "${YELLOW}Performing health check...${NC}"
    
    # Get Load Balancer DNS
    ALB_DNS=$(aws elbv2 describe-load-balancers --query "LoadBalancers[?contains(Tags[?Key=='Environment'].Value, '$ENVIRONMENT')].DNSName" --output text)
    
    if [ -z "$ALB_DNS" ]; then
        echo -e "${RED}Load Balancer not found for environment: $ENVIRONMENT${NC}"
        exit 1
    fi
    
    # Wait for deployment to complete
    echo "Waiting for deployment to complete..."
    sleep 60
    
    # Health check
    HEALTH_URL="http://$ALB_DNS/health"
    MAX_ATTEMPTS=10
    ATTEMPT=1
    
    while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
        echo "Health check attempt $ATTEMPT/$MAX_ATTEMPTS..."
        
        if curl -f -s $HEALTH_URL > /dev/null; then
            echo -e "${GREEN}Health check passed!${NC}"
            echo -e "${GREEN}Application is available at: http://$ALB_DNS${NC}"
            return 0
        fi
        
        sleep 30
        ATTEMPT=$((ATTEMPT + 1))
    done
    
    echo -e "${RED}Health check failed after $MAX_ATTEMPTS attempts${NC}"
    exit 1
}

# Rollback function
rollback() {
    echo -e "${YELLOW}Rolling back deployment...${NC}"
    
    # Get previous image tag (this would need to be stored somewhere)
    PREVIOUS_TAG=$(aws ssm get-parameter --name "/devops-safle/$ENVIRONMENT/previous-image-tag" --query "Parameter.Value" --output text 2>/dev/null || echo "previous")
    
    # Redeploy with previous tag
    deploy_application $PREVIOUS_TAG
    
    echo -e "${GREEN}Rollback completed!${NC}"
}

# Main execution
main() {
    case "${3:-deploy}" in
        "deploy")
            check_prerequisites
            build_and_push_image
            deploy_infrastructure
            deploy_application
            health_check
            ;;
        "rollback")
            rollback
            ;;
        "health-check")
            health_check
            ;;
        *)
            echo "Usage: $0 <environment> <image_tag> <action>"
            echo "Actions: deploy, rollback, health-check"
            exit 1
            ;;
    esac
}

# Trap to handle script interruption
trap 'echo -e "${RED}Deployment interrupted!${NC}"; exit 1' INT TERM

main "$@"

