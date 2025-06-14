# Development Environment Configuration
project_name = "safle-app"
environment  = "dev"
aws_region   = "us-west-2"

# Networking
vpc_cidr = "10.0.0.0/16"

# Database Configuration
db_instance_class = "db.t3.micro"
db_name          = "safledb"
db_username      = "dbadmin"

# Auto Scaling Configuration
instance_type        = "t3.small"
asg_min_size        = 1
asg_max_size        = 3
asg_desired_capacity = 1

# Optional configurations
domain_name   = ""
sns_topic_arn = ""
