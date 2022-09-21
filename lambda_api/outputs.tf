output "url" {
  value = aws_api_gateway_stage.stage.invoke_url
}

output "usage_plan_id" {
  value = var.requires_key ? aws_api_gateway_usage_plan.usage_plan[0].id : ""
}
