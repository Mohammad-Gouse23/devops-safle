output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = module.alb.alb_dns_name
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = module.ecr.repository_url
}

output "database_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.rds_instance_endpoint
  sensitive   = true
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "security_group_ids" {
  description = "Security group IDs"
  value = {
    alb = aws_security_group.alb.id
    asg = aws_security_group.asg.id
    rds = aws_security_group.rds.id
  }
}

output "cloudwatch_dashboard_url" {
  description = "URL of the CloudWatch dashboard"
  value       = module.cloudwatch.dashboard_url
}

output "rds_secret_arn" {
  description = "ARN of the secret storing the DB password"
  value       = module.rds.rds_secret_arn
  sensitive   = true
}
