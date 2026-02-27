variable "name" {
  type        = string
  default     = "mcp"
  description = "Base name for resources (e.g. API name prefix)."
}

variable "enabled" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}

# -----------------------------------------------------------------------------
# Lambda
# -----------------------------------------------------------------------------
variable "encrypt_logs" {
  type    = bool
  default = false
}

variable "lambda" {
  type = object({
    dir                        = string
    handler                    = optional(string, "main.handler")
    runtime                    = optional(string, "nodejs22.x")
    timeout                    = optional(number, 30)
    memory_size                = optional(number, 128)
    subnet_ids                 = optional(list(string))
    security_group_ids         = optional(list(string))
    extra_environment_variables = optional(map(string), {})
  })
  description = "Lambda configuration. The module creates the Lambda and wires it to the API Gateway."
}

variable "cognito" {
  type = object({
    user_pool_id   = string
    user_pool_arn  = string
    domain         = optional(string)
    domain_prefix  = optional(string)
  })
  description = "Cognito User Pool configuration. user_pool_id: pool where the module creates MCP resource server and OAuth client. user_pool_arn: for API Gateway authorizer. domain: hosted domain host (e.g. xxx.auth.<region>.amazoncognito.com); when null, the module creates aws_cognito_user_pool_domain. Pass domain when the pool already has a domain (one domain per pool). domain_prefix: prefix when creating domain (default: name-mcp-workspace)."
}

# -----------------------------------------------------------------------------
# OAuth (DCR / MCP client)
# -----------------------------------------------------------------------------

variable "mcp_callback_urls" {
  type        = list(string)
  default     = ["https://claude.ai/api/mcp/auth_callback", "https://claude.com/api/mcp/auth_callback"]
  description = "Allowed callback URLs for the MCP OAuth app client (e.g. Claude, ChatGPT redirect URIs). Also used as DCR allowlist for redirect_uris."
}

# -----------------------------------------------------------------------------
# Optional: Custom domain (CloudFront)
# -----------------------------------------------------------------------------

variable "mcp_domain" {
  type = object({
    name            = string
    hosted_zone_id  = string
    certificate_arn = string
  })
  default     = null
  description = "Optional custom domain for MCP. When set, creates CloudFront + Route53. OAuth discovery at /.well-known/oauth-authorization-server requires a stable public URL."
}
