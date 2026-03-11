output "instance_id" {
  value       = aws_instance.ssm_jump.id
  description = "EC2 instance ID for SSM port forwarding (e.g. aws ssm start-session --target <id> ...)"
}
