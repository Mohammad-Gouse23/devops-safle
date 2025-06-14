This Terraform configuration creates a complete AWS infrastructure for the Safle application with the following components:

## Architecture Overview

- **VPC**: Custom VPC with public and private subnets across multiple AZs
- **ALB**: Application Load Balancer for traffic distribution
- **ASG**: Auto Scaling Group with EC2 instances running the application
- **RDS**: MySQL database with encryption and automated backups
- **ECR**: Container registry for Docker images
- **CloudWatch**: Monitoring, logging, and alerting

## Directory Structure

```
terraform/
├── main.tf                 # Root configuration calling modules
├── variables.tf            # Root variables
├── outputs.tf             # Root outputs
├── modules/               # Reusable modules
│   ├── vpc/              # VPC, subnets, NAT gateways
│   ├── alb/              # Application Load Balancer
│   ├── asg/              # Auto Scaling Group
│   ├── rds/              # RDS MySQL database
│   ├── ecr/              # Elastic Container Registry
│   └── cloudwatch/       # Monitoring and logging
└── environments/         # Environment-specific configurations
    ├── dev/              # Development environment
    └── prod/             # Production environment
```

## Usage

### Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform >= 1.0 installed
3. S3 bucket for Terraform state (update backend configuration)
4. DynamoDB table for state locking

### Deployment

#### Development Environment

```bash
cd terraform/environments/dev
terraform init
terraform plan
terraform apply
```

#### Production Environment

```bash
cd terraform/environments/prod
terraform init
terraform plan
terraform apply
```

### Environment Differences

| Component | Development | Production |
|-----------|-------------|------------|
| Instance Size | t3.small | t3.medium |
| ASG Min/Max/Desired | 1/3/1 | 2/10/3 |
| DB Instance | db.t3.micro | db.t3.small |
| DB Backups | 1 day | 7 days |
| VPC CIDR | 10.0.0.0/16 | 10.1.0.0/16 |
| SSL/Domain | Optional | Required |
| Monitoring | Basic | Full with SNS |

## Configuration

### Required Variables

- `project_name`: Name of the project
- `environment`: Environment name (dev/prod)
- `aws_region`: AWS region for deployment

### Optional Variables

- `domain_name`: For SSL certificate (production)
- `sns_topic_arn`: For CloudWatch alarms
- `db_instance_class`: RDS instance size
- `instance_type`: EC2 instance size

## Outputs

After deployment, you'll get:

- **Load Balancer DNS**: URL to access your application
- **ECR Repository URL**: For pushing Docker images  
- **Database Endpoint**: For application configuration
- **VPC/Subnet IDs**: For additional resources

## Security Features

- Database in private subnets only
- Security groups with minimal required access
- Database password stored in AWS Secrets Manager
- Encrypted RDS storage
- ECR image scanning enabled

## Monitoring

- CloudWatch alarms for high/low CPU usage
- Application Load Balancer health monitoring
- Custom dashboard for application metrics
- Log aggregation in CloudWatch Logs

## Cost Optimization

- Development environment uses smaller instances
- Lifecycle policies for ECR images
- Configurable backup retention
- Auto Scaling based on demand

## Cleanup

To destroy the infrastructure:

```bash
# For dev environment
cd terraform/environments/dev
terraform destroy

# For prod environment  
cd terraform/environments/prod
terraform destroy
```

**Warning**: This will delete all resources including databases. Make sure to backup any important data first.

## Customization

To modify the infrastructure:

1. Update variables in `terraform.tfvars`
2. Modify module configurations in respective `/modules` directories
3. Add new modules as needed
4. Update environment-specific configurations

## Support

For issues or questions:
1. Check the Terraform documentation
2. Review AWS service documentation
3. Check CloudWatch logs for application issues

