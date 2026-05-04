output "instance_id" {
  value       = var.enabled ? aws_instance.ssm_jump[0].id : null
  description = "EC2 instance ID for SSM port forwarding (e.g. aws ssm start-session --target <id> ...)"
}
