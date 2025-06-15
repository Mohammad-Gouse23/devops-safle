# DevOps Assignment - Safle

## Project Overview
This repository contains a complete DevOps solution for deploying a containerized Node.js application with automated CI/CD, infrastructure as code, monitoring, and security best practices.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        Internet                              │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                 Application Load Balancer                   │
│                    (HTTPS/SSL)                             │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                     VPC                                     │
│  ┌─────────────────────────────────────────────────────────┐│
│  │              Public Subnets                             ││
│  │  ┌─────────────┐    ┌─────────────┐                     ││
│  │  │ NAT Gateway │    │ NAT Gateway │                     ││
│  │  │     AZ-a    │    │     AZ-b    │                     ││
│  │  └─────────────┘    └─────────────┘                     ││
│  └─────────────────────────────────────────────────────────┘│
│  ┌─────────────────────────────────────────────────────────┐│
│  │              Private Subnets                            ││
│  │  ┌─────────────┐    ┌─────────────┐                     ││
│  │  │EC2 Instance │    │EC2 Instance │                     ││
│  │  │  (Node.js)  │    │  (Node.js)  │                     ││
│  │  │     AZ-a    │    │     AZ-b    │                     ││
│  │  └─────────────┘    └─────────────┘                     ││
│  │          │                   │                          ││
│  │  ┌───────▼───────────────────▼───────┐                  ││
│  │  │         RDS PostgreSQL            │                  ││
│  │  │      (Multi-AZ Deployment)        │                  ││
│  │  └───────────────────────────────────┘                  ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘

External Services:
- ECR (Container Registry)
- CloudWatch (Monitoring)
- Systems Manager (Secrets)
- ACM (SSL Certificates)
```

## Repository Structure

```
.
├── app/                          # Node.js application
│   ├── src/
│   │   ├── app.js
│   │   ├── routes/
│   │   └── models/
│   ├── tests/
│   ├── package.json
│   └── Dockerfile
├── terraform/                    # Infrastructure as Code
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── modules/
│   │   ├── vpc/
│   │   ├── alb/
│   │   ├── asg/
│   │   ├── rds/
│   │   └── ecr/
│   └── environments/
│       ├── dev/
│       └── prod/
├── .github/workflows/            # CI/CD Pipeline
│   └── deploy.yml
├── monitoring/                   # Monitoring configuration
│   ├── grafana/
│   └── prometheus/
├── scripts/                      # Deployment scripts
├── docker-compose.yml            # Local development
└── README.md                     # This file
```

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- Docker
- Node.js >= 16
- Git

## Quick Start

### 1. Clone and Setup
```bash
git clone https://github.com/Mohammad-Gouse23/devops-safle.git
cd devops-safle
npm install
```

### 2. Local Development
```bash
# Start local environment
docker-compose up -d

# Run tests
npm test

# Access application
curl http://localhost:3000/health
```

### 3. Deploy Infrastructure
```bash
cd terraform/environments/dev
terraform init
terraform plan
terraform apply
```

### 4. Deploy Application
Push to main branch to trigger CI/CD pipeline or run manually:

# Deploy to EC2
./scripts/deploy.sh

## Implementation Details

### Node.js Application (app/)
- RESTful API with health check and CRUD endpoints
- Environment-based configuration
- Comprehensive unit tests with Jest
- Structured logging with Winston
- Error handling middleware

### Containerization
- Multi-stage Dockerfile for optimized image size
- Non-root user for security
- Health checks included
- Docker Compose for local development with PostgreSQL

### Infrastructure as Code (terraform/)
- Modular Terraform configuration
- VPC with public/private subnets across multiple AZs
- Auto Scaling Group with Launch Template
- Application Load Balancer with SSL termination
- RDS PostgreSQL with encryption and backups
- ECR repository for container images
- IAM roles with least privilege access
- Security Groups with minimal required access

### CI/CD Pipeline (.github/workflows/)
- Automated testing on pull requests
- Build and push Docker images to ECR
- Infrastructure updates with Terraform
- Rolling deployment to EC2 instances
- Rollback capabilities
- Slack/Email notifications

### Security Implementation
- HTTPS enforced with AWS ACM certificates
- Secrets managed via AWS Systems Manager
- Container runs as non-root user
- RDS encryption at rest and in transit
- Security Groups with restricted access
- IAM roles following least privilege principle

### Monitoring and Alerting
- CloudWatch metrics and logs
- Custom application metrics
- Grafana dashboards for visualization
- CloudWatch Alarms with SNS notifications
- Log aggregation and structured logging

## Environment Configuration

### Development Environment
- Single AZ deployment
- Smaller instance types
- Development database
- Debug logging enabled

### Production Environment
- Multi-AZ deployment
- Production-grade instance types
- High availability RDS
- Production logging levels
- Enhanced monitoring

## CI/CD Pipeline Details

### Pipeline Stages
1. **Test Stage**: Run unit tests and linting
2. **Security Scan**: Container vulnerability scanning
3. **Build Stage**: Build and tag Docker image
4. **Push Stage**: Push to ECR repository
5. **Infrastructure Stage**: Apply Terraform changes
6. **Deploy Stage**: Rolling deployment to EC2 instances
7. **Health Check**: Verify deployment success
8. **Notify**: Send deployment status notifications

### Deployment Strategy
- Blue-Green deployment capability
- Rolling updates with health checks
- Automatic rollback on failure
- Zero-downtime deployments


## Security Best Practices Implemented

### Infrastructure Security
- VPC with private subnets for application servers
- Security Groups with minimal required access
- WAF rules for common web attacks
- Encryption at rest and in transit
- Regular security patching via Systems Manager

### Application Security
- Input validation and sanitization
- Rate limiting
- CORS configuration
- Security headers
- Dependency vulnerability scanning

### Secrets Management
- AWS Systems Manager Parameter Store for configuration
- AWS Secrets Manager for sensitive data
- No hardcoded secrets in code or containers
- Rotation policies for database credentials

## Performance Optimization

### Application Level
- Connection pooling for database
- Caching strategies
- Compression middleware
- Async/await patterns for non-blocking operations

### Infrastructure Level
- Auto Scaling based on CloudWatch metrics
- Application Load Balancer for traffic distribution
- CloudFront CDN for static assets (optional)
- RDS Read Replicas for read-heavy workloads


### Backup Strategy
- Automated RDS backups with point-in-time recovery
- Infrastructure state backup (Terraform state)
- Container image versioning and retention
- Cross-region backup replication

### Recovery Procedures
- RDS automated failover in Multi-AZ setup
- Auto Scaling Group automatic instance replacement
- Infrastructure recreation from Terraform code
- Application deployment from ECR images

## Cost Optimization

### Strategies Implemented
- Right-sized EC2 instances based on usage
- Spot instances for non-critical workloads
- S3 lifecycle policies for log retention
- CloudWatch log retention policies
- Auto Scaling to match demand

