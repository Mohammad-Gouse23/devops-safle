output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.name
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.main.id
}

output "security_group_id" {
  description = "ID of the ASG security group"
  value       = aws_security_group.asg.id
}

