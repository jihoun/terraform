output "url" {
  value = length(aws_api_gateway_stage.stage) == 1 ? aws_api_gateway_stage.stage[0].invoke_url : ""
}

output "usage_plan_id" {
  value = (var.enabled && var.requires_key) ? aws_api_gateway_usage_plan.usage_plan[0].id : ""
}

output "api_id" {
  value = length(aws_api_gateway_rest_api.api) == 1 ? aws_api_gateway_rest_api.api[0].id : ""
}

output "api_root_resource_id" {
  value = length(aws_api_gateway_rest_api.api) == 1 ? aws_api_gateway_rest_api.api[0].root_resource_id : ""
}

output "api" {
  value = var.enabled ? var.requires_key ? {
    url           = aws_api_gateway_stage.stage[0].invoke_url
    usage_plan_id = aws_api_gateway_usage_plan.usage_plan[0].id
    } : {
    url = length(aws_api_gateway_stage.stage) == 1 ? aws_api_gateway_stage.stage[0].invoke_url : ""
  } : {}
  description = "Same as looking at url and usage_plan_id separately but those often goes in pair. And it is a kind of convention to pass those 2 in this format across modules"
}

output "endpoint" {
  value = length(aws_api_gateway_rest_api.api) == 1 ? "${aws_api_gateway_rest_api.api[0].id}.execute-api.${data.aws_region.current.region}.amazonaws.com" : ""
}

output "arn" {
  value = length(aws_api_gateway_rest_api.api) == 1 ? aws_api_gateway_rest_api.api[0].arn : ""
}
