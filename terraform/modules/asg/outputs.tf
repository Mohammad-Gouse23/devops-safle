output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.arn
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.name
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.main.id
}

output "launch_template_latest_version" {
  description = "Latest version of the launch template"
  value       = aws_launch_template.main.latest_version
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.name
}
