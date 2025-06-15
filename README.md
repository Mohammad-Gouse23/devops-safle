# DevOps Assignment - Safle

A comprehensive DevOps solution demonstrating containerized application deployment with automated CI/CD, infrastructure as code, and production-ready monitoring on AWS.

## Overview

This repository implements a complete DevOps pipeline for a Node.js application, showcasing industry best practices for scalable, secure, and maintainable cloud infrastructure.

## Architecture

```
┌─────────────────────────────────────────┐
│                AWS VPC                  │
│  ┌─────────────────┐ ┌─────────────────┐│
│  │  Public Subnet  │ │ Private Subnet  ││
│  │  • ALB          │ │ • EC2 (ASG)     ││
│  │  • NAT Gateway  │ │ • RDS           ││
│  └─────────────────┘ └─────────────────┘│
└─────────────────────────────────────────┘
         │
    ┌────▼────┐
    │   ECR   │
    │ IAM/ACM │
    │   SNS   │
    └─────────┘
```

## Technology Stack

**Infrastructure & Orchestration**
- Terraform - Infrastructure as Code
- AWS (EC2, RDS, VPC, ALB, ECR, IAM)
- Docker & Docker Compose

**CI/CD & Automation**
- Jenkins - Pipeline automation
- AWS ECR - Container registry

**Monitoring & Observability**
- Amazon CloudWatch
- Prometheus & Grafana
- AWS SNS for alerting

**Security**
- AWS Secrets Manager/SSM Parameter Store
- SSL/TLS via AWS Certificate Manager
- VPC with public/private subnet isolation

## Repository Structure

```
├── app/                 # Node.js application with Jest tests
├── terraform/           # AWS infrastructure definitions
├── monitoring/          # Prometheus & Grafana configurations
├── scripts/            # Deployment and utility scripts
├── docker-compose.yml  # Local development environment
├── Jenkinsfile         # CI/CD pipeline definition
└── README.md
```

## Quick Start

### Prerequisites
- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- Docker & Docker Compose
- Jenkins with AWS plugins

### Local Development
```bash
git clone https://github.com/Mohammad-Gouse23/devops-safle.git
cd devops-safle
cd scripts
./docker.sh
./terraform.sh
cd ..

# Start local environment
sudo docker-compose up -d

# Run tests
cd app && npm test
```

### Infrastructure Deployment
```bash
cd terraform
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply
```

## CI/CD Pipeline

The Jenkins pipeline (`Jenkinsfile`) implements:

1. **Test Stage** - Execute Jest unit tests
2. **Build Stage** - Create optimized Docker image
3. **Security Scan** - Vulnerability assessment
4. **Push Stage** - Deploy to AWS ECR
5. **Deploy Stage** - Infrastructure update and application deployment
6. **Rollback** - Automated rollback on deployment failure

**Triggers**: Automated on push to `main` branch

## Key Features

### High Availability
- Auto Scaling Groups with multi-AZ deployment
- Application Load Balancer with health checks
- Self-healing infrastructure with automated recovery

### Security
- Network isolation with VPC and security groups
- Encrypted data at rest and in transit
- Least privilege IAM roles
- Secure secret management
- Container security best practices

### Monitoring & Alerting
- Real-time metrics collection and visualization
- Automated alerting via CloudWatch and SNS
- Custom dashboards for application and infrastructure metrics
- Log aggregation and analysis

## Environment Configuration

Key configurations are managed through:
- `terraform/terraform.tfvars` - Infrastructure parameters
- AWS Systems Manager Parameter Store - Runtime secrets
- Environment-specific Docker Compose overrides

## Monitoring Dashboards

Access monitoring interfaces:
- **Grafana**: `https://<alb-dns>/grafana`
- **CloudWatch**: AWS Console
- **Application**: `https://<alb-dns>/health`

## Design Decisions

- **Multi-tier architecture** for security and scalability
- **Infrastructure as Code** for reproducible deployments
- **Blue-green deployment strategy** for zero-downtime updates
- **Comprehensive monitoring** for proactive issue resolution

## Testing

```bash
# Unit tests
npm test

# Integration tests
npm run test:integration

# Infrastructure tests
cd terraform && terraform plan
```

## Production Considerations

This implementation includes production-ready features:
- SSL/TLS termination
- Database connection pooling
- Horizontal auto-scaling
- Disaster recovery capabilities
- Security compliance (encryption, access controls)
