terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Backend configuration for prod environment
  backend "s3" {
    bucket         = "your-terraform-state-bucket-prod"
    key            = "safle-app/prod/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-locks-prod"
  }
}

# Call the root module
module "safle_app" {
  source = "../../"

  # Environment-specific variables
  project_name = "safle-app"
  environment  = "prod"
  aws_region   = "us-west-2"

  # Networking
  vpc_cidr = "10.1.0.0/16"

  # Database
  db_instance_class = "db.t3.small"
  db_name          = "safledb"
  db_username      = "dbadmin"

  # Auto Scaling
  instance_type        = "t3.medium"
  asg_min_size        = 2
  asg_max_size        = 10
  asg_desired_capacity = 3

  # Production configurations
  domain_name   = "yourdomain.com"
  sns_topic_arn = "arn:aws:sns:us-west-2:123456789012:prod-alerts"
}

# Environment-specific outputs
output "prod_load_balancer_dns" {
  description = "DNS name of the prod load balancer"
  value       = module.safle_app.load_balancer_dns
}

output "prod_ecr_repository_url" {
  description = "ECR repository URL for prod"
  value       = module.safle_app.ecr_repository_url
}

