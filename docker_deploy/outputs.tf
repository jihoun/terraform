
output "role_id" {
  value = aws_iam_role.task.id
}

output "url" {
  value = var.domain_name != null ? "https://${var.domain_name}" : "http://${aws_alb.lb.dns_name}"
}
