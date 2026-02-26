output "lambda" {
  value = var.enabled && length(module.lambda) > 0 ? {
    function_name = module.lambda[0].function_name
    role_name     = module.lambda[0].role_name
    role_arn      = module.lambda[0].role_arn
  } : null
  description = "Lambda function name and execution role."
}

output "url" {
  value       = var.enabled && var.mcp_domain != null ? "https://${var.mcp_domain.name}/mcp" : ""
  description = "Public MCP endpoint URL (when mcp_domain is set)."
}

output "mcp_oauth" {
  value = var.enabled ? {
    client_id   = aws_cognito_user_pool_client.mcp_client[0].id
    secret_name = aws_secretsmanager_secret.mcp_oauth_client_secret[0].name
  } : null
  description = "MCP OAuth client ID and Secrets Manager secret name (for DCR)."
}
