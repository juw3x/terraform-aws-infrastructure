output "instance_ids" {
  description = "List of EC2 instance IDs"
  value       = aws_autoscaling_group.web.instances
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.web.name
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.web.id
}
