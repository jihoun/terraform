# Cognito domain: when cognito.domain is not provided, create hosted domain for OAuth.
# Note: User pool can only have one domain. Ensure the pool does not already have a domain.
resource "aws_cognito_user_pool_domain" "mcp" {
  count        = var.enabled && try(var.cognito.domain, null) == null ? 1 : 0
  domain       = try(var.cognito.domain_prefix, null) != null ? var.cognito.domain_prefix : lower("${var.name}-mcp-${terraform.workspace}")
  user_pool_id = var.cognito.user_pool_id
}

# MCP OAuth: resource server defines the mcp/access scope used by the API Gateway authorizer.
resource "aws_cognito_resource_server" "mcp" {
  count        = var.enabled ? 1 : 0
  identifier   = "mcp"
  name         = "mcp-${terraform.workspace}"
  user_pool_id = var.cognito.user_pool_id

  scope {
    scope_name        = "access"
    scope_description = "Access MCP API"
  }
}

# MCP OAuth confidential client (authorization code flow). Used by Claude, DCR, etc.
resource "aws_cognito_user_pool_client" "mcp_client" {
  count  = var.enabled ? 1 : 0
  depends_on = [aws_cognito_resource_server.mcp]

  user_pool_id                         = var.cognito.user_pool_id
  name                                 = "mcp_${terraform.workspace}"
  generate_secret                      = true
  callback_urls                        = var.mcp_callback_urls
  allowed_oauth_flows                   = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["openid", "email", "profile", "mcp/access"]
  supported_identity_providers         = ["COGNITO"]
  refresh_token_validity               = 7
  access_token_validity                = 1
  id_token_validity                    = 1
  prevent_user_existence_errors        = "ENABLED"

  token_validity_units {
    refresh_token = "days"
    access_token  = "hours"
    id_token      = "hours"
  }
}

resource "aws_secretsmanager_secret" "mcp_oauth_client_secret" {
  count       = var.enabled ? 1 : 0
  name_prefix = "${var.name}_mcp_oauth_client_secret_"
  description = "MCP OAuth app client secret (Cognito); value populated from Cognito client."
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "mcp_oauth_client_secret" {
  count         = var.enabled ? 1 : 0
  secret_id     = aws_secretsmanager_secret.mcp_oauth_client_secret[0].id
  secret_string = aws_cognito_user_pool_client.mcp_client[0].client_secret
}
