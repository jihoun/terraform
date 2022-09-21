output "role_name" {
  value = aws_iam_role.role.id
}

output "role_arn" {
  value = aws_iam_role.role.arn
}

output "function_name" {
  value = aws_lambda_function.fn.function_name
}

output "function_arn" {
  value = aws_lambda_function.fn.arn
}
