terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Backend configuration for dev environment
  backend "s3" {
    bucket         = "your-terraform-state-bucket-dev"
    key            = "safle-app/dev/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-locks-dev"
  }
}

# Call the root module
module "safle_app" {
  source = "../../"

  # Environment-specific variables
  project_name = "safle-app"
  environment  = "dev"
  aws_region   = "us-west-2"

  # Networking
  vpc_cidr = "10.0.0.0/16"

  # Database
  db_instance_class = "db.t3.micro"
  db_name          = "safledb"
  db_username      = "dbadmin"

  # Auto Scaling
  instance_type        = "t3.small"
  asg_min_size        = 1
  asg_max_size        = 3
  asg_desired_capacity = 1

  # Optional: domain and SNS
  domain_name   = ""
  sns_topic_arn = ""
}

# Environment-specific outputs
output "dev_load_balancer_dns" {
  description = "DNS name of the dev load balancer"
  value       = module.safle_app.load_balancer_dns
}

output "dev_ecr_repository_url" {
  description = "ECR repository URL for dev"
  value       = module.safle_app.ecr_repository_url
}

