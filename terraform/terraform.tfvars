
# General Configuration
project_name = "safle-app"
environment  = "dev"
aws_region   = "us-west-2"

# Networking Configuration
vpc_cidr = "10.0.0.0/16"

# Database Configuration
db_instance_class = "db.t3.micro"
db_name          = "safledb"
db_username      = "dbadmin"

# Application Load Balancer Configuration
# Leave empty for development, set to your domain for production
domain_name = ""

# Auto Scaling Group Configuration
instance_type        = "t3.small"
asg_min_size        = 1
asg_max_size        = 6
asg_desired_capacity = 2

# CloudWatch Configuration
# Leave empty for basic monitoring, set SNS topic ARN for production alerts
sns_topic_arn = ""

# ============================================================================
# Environment-specific overrides:
# 
# For development:
# - Smaller instances (t3.small, db.t3.micro)
# - Lower ASG capacity (1-3 instances)
# - No domain/SSL
# - Basic monitoring
#
# For production:
# - Larger instances (t3.medium, db.t3.small)
# - Higher ASG capacity (2-10 instances)
# - Domain with SSL certificate
# - Full monitoring with SNS alerts
# ============================================================================
