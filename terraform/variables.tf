# terraform/variables.tf

# General Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "safle-app"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

# Networking Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

# Database Configuration
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Name of the database to create"
  type        = string
  default     = "safledb"
  
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9]*$", var.db_name))
    error_message = "Database name must start with a letter and contain only alphanumeric characters."
  }
}

variable "db_username" {
  description = "Username for the database"
  type        = string
  default     = "dbadmin"
  
  validation {
    condition     = length(var.db_username) >= 1 && length(var.db_username) <= 16
    error_message = "Database username must be between 1 and 16 characters."
  }
}

# Application Load Balancer Configuration
variable "domain_name" {
  description = "Domain name for the application (optional)"
  type        = string
  default     = ""
}

# Auto Scaling Group Configuration
variable "instance_type" {
  description = "EC2 instance type for ASG"
  type        = string
  default     = "t3.small"
}

variable "asg_min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 1
  
  validation {
    condition     = var.asg_min_size >= 0
    error_message = "ASG minimum size must be non-negative."
  }
}

variable "asg_max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 6
  
  validation {
    condition     = var.asg_max_size >= var.asg_min_size
    error_message = "ASG maximum size must be greater than or equal to minimum size."
  }
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
  default     = 2
  
  validation {
    condition = (
      var.asg_desired_capacity >= var.asg_min_size &&
      var.asg_desired_capacity <= var.asg_max_size
    )
    error_message = "ASG desired capacity must be between minimum and maximum size."
  }
}

# CloudWatch Configuration
variable "sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms (optional)"
  type        = string
  default     = ""
}
