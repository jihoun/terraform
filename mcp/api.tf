resource "aws_api_gateway_rest_api" "api" {
  count = var.enabled ? 1 : 0

  name = "${var.name}-${terraform.workspace}"
  tags = local.tags
}

resource "aws_api_gateway_authorizer" "cognito" {
  count = var.enabled ? 1 : 0

  name             = "${var.name}-cognito-${terraform.workspace}"
  rest_api_id      = aws_api_gateway_rest_api.api[0].id
  type             = "COGNITO_USER_POOLS"
  provider_arns    = [var.cognito.user_pool_arn]
  identity_source  = "method.request.header.Authorization"
}

# ############################################################################
# Register (POST /register) - DCR; returns client_id and client_secret
# ############################################################################
resource "aws_api_gateway_resource" "register" {
  count = var.enabled ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.api[0].id
  parent_id   = aws_api_gateway_rest_api.api[0].root_resource_id
  path_part   = "register"
}

module "register" {
  source = "../gw_method_lambda"
  enabled = var.enabled

  rest_api_id   = var.enabled ? aws_api_gateway_rest_api.api[0].id : ""
  resource_id   = var.enabled ? aws_api_gateway_resource.register[0].id : ""
  http_method   = "POST"
  function_name = local.lambda_function_name
}

# ############################################################################
# Health (GET /health)
# ############################################################################
resource "aws_api_gateway_resource" "health" {
  count = var.enabled ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.api[0].id
  parent_id   = aws_api_gateway_rest_api.api[0].root_resource_id
  path_part   = "health"
}

module "health" {
  source = "../gw_method_lambda"
  enabled = var.enabled

  rest_api_id   = var.enabled ? aws_api_gateway_rest_api.api[0].id : ""
  resource_id   = var.enabled ? aws_api_gateway_resource.health[0].id : ""
  http_method   = "GET"
  authorization = "NONE"
  function_name = local.lambda_function_name
}

# ############################################################################
# Authorize (GET /authorize) - OAuth proxy, redirects to Cognito
# ############################################################################
resource "aws_api_gateway_resource" "authorize" {
  count = var.enabled ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.api[0].id
  parent_id   = aws_api_gateway_rest_api.api[0].root_resource_id
  path_part   = "authorize"
}

module "authorize" {
  source = "../gw_method_lambda"
  enabled = var.enabled

  rest_api_id   = var.enabled ? aws_api_gateway_rest_api.api[0].id : ""
  resource_id   = var.enabled ? aws_api_gateway_resource.authorize[0].id : ""
  http_method   = "GET"
  authorization = "NONE"
  function_name = local.lambda_function_name
}

# ############################################################################
# Token (POST /token) - OAuth proxy, forwards to Cognito
# ############################################################################
resource "aws_api_gateway_resource" "token" {
  count = var.enabled ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.api[0].id
  parent_id   = aws_api_gateway_rest_api.api[0].root_resource_id
  path_part   = "token"
}

module "token" {
  source = "../gw_method_lambda"
  enabled = var.enabled

  rest_api_id   = var.enabled ? aws_api_gateway_rest_api.api[0].id : ""
  resource_id   = var.enabled ? aws_api_gateway_resource.token[0].id : ""
  http_method   = "POST"
  authorization = "NONE"
  function_name = local.lambda_function_name
}

# ############################################################################
# OAuth discovery (GET /.well-known/oauth-authorization-server)
# ############################################################################
resource "aws_api_gateway_resource" "well_known" {
  count = var.enabled ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.api[0].id
  parent_id   = aws_api_gateway_rest_api.api[0].root_resource_id
  path_part   = ".well-known"
}

resource "aws_api_gateway_resource" "oauth_authorization_server" {
  count = var.enabled ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.api[0].id
  parent_id   = aws_api_gateway_resource.well_known[0].id
  path_part   = "oauth-authorization-server"
}

module "oauth_authorization_server" {
  source = "../gw_method_lambda"
  enabled = var.enabled

  rest_api_id   = var.enabled ? aws_api_gateway_rest_api.api[0].id : ""
  resource_id   = var.enabled ? aws_api_gateway_resource.oauth_authorization_server[0].id : ""
  http_method   = "GET"
  function_name = local.lambda_function_name
}

# ############################################################################
# MCP (ANY /mcp) - Main MCP protocol, Cognito-protected
# ############################################################################
locals {
  mcp_authorization_scopes = ["openid", "mcp/access"]
}

resource "aws_api_gateway_resource" "mcp" {
  count = var.enabled ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.api[0].id
  parent_id   = aws_api_gateway_rest_api.api[0].root_resource_id
  path_part   = "mcp"
}

module "mcp" {
  source = "../gw_method_lambda"
  enabled = var.enabled

  rest_api_id          = var.enabled ? aws_api_gateway_rest_api.api[0].id : ""
  resource_id          = var.enabled ? aws_api_gateway_resource.mcp[0].id : ""
  http_method          = "ANY"
  authorization        = "COGNITO_USER_POOLS"
  authorizer_id        = var.enabled ? aws_api_gateway_authorizer.cognito[0].id : ""
  authorization_scopes = local.mcp_authorization_scopes
  function_name        = local.lambda_function_name
}

# ############################################################################
# Deployment
# ############################################################################
resource "aws_api_gateway_deployment" "deploy" {
  count       = var.enabled ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.api[0].id

  triggers = {
    redeployment = sha1(jsonencode({
      mcp_authorization_scopes = local.mcp_authorization_scopes
    }))
  }

  lifecycle { create_before_destroy = true }
  depends_on = [
    module.authorize,
    module.register,
    module.health,
    module.oauth_authorization_server,
    module.token,
    module.mcp,
  ]
}

resource "aws_api_gateway_stage" "stage" {
  count         = var.enabled ? 1 : 0
  rest_api_id   = aws_api_gateway_rest_api.api[0].id
  stage_name    = "api"
  deployment_id = aws_api_gateway_deployment.deploy[0].id
}
