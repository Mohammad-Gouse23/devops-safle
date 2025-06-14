# Production Environment Configuration
project_name = "safle-app"
environment  = "prod"
aws_region   = "us-west-2"

# Networking
vpc_cidr = "10.1.0.0/16"

# Database Configuration
db_instance_class = "db.t3.small"
db_name          = "safledb"
db_username      = "dbadmin"

# Auto Scaling Configuration
instance_type        = "t3.medium"
asg_min_size        = 2
asg_max_size        = 10
asg_desired_capacity = 3

# Production configurations
domain_name   = "yourdomain.com"
sns_topic_arn = "arn:aws:sns:us-west-2:123456789012:prod-alerts"
