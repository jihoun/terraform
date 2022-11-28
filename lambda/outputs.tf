output "role_name" {
  value = var.enabled ? aws_iam_role.role[0].id : ""
}

output "role_arn" {
  value = var.enabled ? aws_iam_role.role[0].arn : ""
}

output "function_name" {
  value = var.enabled ? aws_lambda_function.fn[0].function_name : ""
}

output "function_arn" {
  value = var.enabled ? aws_lambda_function.fn[0].arn : ""
}
