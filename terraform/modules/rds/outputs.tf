output "rds_instance_id" {
  description = "The ID of the RDS instance"
  value       = aws_db_instance.main.id
}

output "rds_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = aws_db_instance.main.arn
}

output "rds_instance_endpoint" {
  description = "The endpoint of the RDS instance"
  value       = aws_db_instance.main.endpoint
}

output "rds_instance_address" {
  description = "The address of the RDS instance"
  value       = aws_db_instance.main.address
}

output "rds_secret_arn" {
  description = "The ARN of the secret storing the DB password"
  value       = aws_secretsmanager_secret.db_password.arn
}

output "rds_db_subnet_group" {
  description = "The name of the RDS DB subnet group"
  value       = aws_db_subnet_group.main.name
}

output "db_endpoint" {
  description = "The endpoint of the RDS instance"
  value       = aws_db_instance.main.endpoint
}
