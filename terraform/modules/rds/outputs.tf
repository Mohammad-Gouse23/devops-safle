output "db_instance_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "db_instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.main.id
}

output "db_instance_arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.main.arn
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.main.db_name
}

output "db_username" {
  description = "Database username"
  value       = aws_db_instance.main.username
}

output "db_port" {
  description = "Database port"
  value       = aws_db_instance.main.port
}

output "db_subnet_group_name" {
  description = "Database subnet group name"
  value       = aws_db_subnet_group.main.name
}

output "secret_arn" {
  description = "ARN of the secret containing the database password"
  value       = aws_secretsmanager_secret.db_password.arn
}
