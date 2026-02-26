# When var.lambda is set, the module creates the Lambda. This breaks the circular
# dependency (Lambda needs env vars from MCP, MCP needs Lambda for API Gateway).
# Deploy order: Cognito -> Lambda (with env from Cognito) -> API Gateway + IAM.
module "lambda" {
  source = "../lambda"
  count  = var.enabled ? 1 : 0

  name   = "${var.name}_api"
  dir    = var.lambda.dir
  tags   = local.tags
  handler = var.lambda.handler
  runtime = var.lambda.runtime
  timeout = var.lambda.timeout
  memory_size = var.lambda.memory_size

  environment_variables = merge(
    local.mcp_environment_variables,
    var.lambda.extra_environment_variables
  )

  subnet_ids         = var.lambda.subnet_ids
  security_group_ids = var.lambda.security_group_ids
}

locals {
  mcp_environment_variables = var.enabled ? {
    MCP_OAUTH_CLIENT_ID            = aws_cognito_user_pool_client.mcp_client[0].id
    MCP_OAUTH_SECRET_NAME           = aws_secretsmanager_secret.mcp_oauth_client_secret[0].name
    MCP_OAUTH_ALLOWED_REDIRECT_URIS = join(",", var.mcp_callback_urls)
    MCP_OAUTH_COGNITO_DOMAIN        = local.cognito_domain_host
    MCP_PUBLIC_BASE_URL             = var.mcp_domain != null ? "https://${var.mcp_domain.name}" : "https://${aws_api_gateway_rest_api.api[0].id}.execute-api.${data.aws_region.current.region}.amazonaws.com/api"
  } : {}
}
