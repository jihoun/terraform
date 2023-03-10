output "url" {
  value = aws_api_gateway_stage.stage.invoke_url
}

output "usage_plan_id" {
  value = var.requires_key ? aws_api_gateway_usage_plan.usage_plan[0].id : ""
}

output "api_id" {
  value = aws_api_gateway_rest_api.api.id
}

output "api_root_resource_id" {
  value = aws_api_gateway_rest_api.api.root_resource_id
}

output "api" {
  object = var.requires_key ? {
    url           = module.aws_api_gateway_stage.stage.invoke_url
    usage_plan_id = aws_api_gateway_usage_plan.usage_plan[0].id
    } : {
    url = module.aws_api_gateway_stage.stage.invoke_url
  }
  description = "Same as looking at url and usage_plan_id separately but those often goes in pair. And it is a kind of convention to pass those 2 in this format across modules"
}
