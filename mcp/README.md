# MCP Terraform Module

Deploys a secured Model Context Protocol (MCP) API gateway with Cognito OAuth. The module creates the API Gateway, Cognito resource server + OAuth client, and optionally CloudFront for a custom domain.

**Lambda:** The module creates the Lambda from the `lambda` block configuration.

## Key Inputs

- **`lambda`** – Lambda configuration (dir, handler, runtime, etc.). The module creates the Lambda and wires it to the API Gateway.
- **`cognito`** – Object with `user_pool_id`, `user_pool_arn`, optional `domain` (Cognito hosted domain host), optional `domain_prefix` (when domain is null, prefix for created domain).

## Lambda Environment Variables

When using the `lambda` block, the module injects MCP OAuth env vars and merges `extra_environment_variables` for app-specific vars. The module automatically attaches a policy granting `secretsmanager:GetSecretValue` on the OAuth client secret.

---

## Endpoints the Lambda Must Serve

All requests are routed to a single Lambda. The Lambda must implement handlers for these paths and methods:

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| **GET** | `/health` | None | Health check. Returns `{ status: "ok", service, version, timestamp }`. |
| **POST** | `/register` | None | [Dynamic Client Registration (DCR)](https://oauth.net/2/dynamic-client-registration/). Returns `client_id` and `client_secret` when `redirect_uris` are in the allowlist. Returns 503 if DCR is not configured. |
| **GET** | `/authorize` | None | OAuth proxy. Redirects to Cognito `/oauth2/authorize`. Returns 503 if OAuth is not configured. |
| **POST** | `/token` | None | OAuth proxy. Forwards token request to Cognito `/oauth2/token`. Returns 503 if OAuth is not configured. |
| **GET** | `/.well-known/oauth-authorization-server` | None | [RFC 8414](https://datatracker.ietf.org/doc/html/rfc8414) OAuth 2.0 Authorization Server Metadata. Returns `issuer`, `authorization_endpoint`, `token_endpoint`, `registration_endpoint`, `scopes_supported`. Returns 503 if discovery is not configured. |
| **ANY** | `/mcp` | Cognito (Bearer) | Main MCP protocol endpoint. Requires `openid` and `mcp/access` scopes. Handles MCP JSON-RPC over HTTP (POST) and SSE (GET for session continuity). |

## Path Summary

```
GET  /health
POST /register
GET  /authorize
POST /token
GET  /.well-known/oauth-authorization-server
ANY  /mcp
```

## Usage Example

```hcl
module "mcp" {
  source = "../mcp"

  name   = "medical-data-mcp"
  cognito = {
    user_pool_id  = module.admin_users.user_pool_id
    user_pool_arn = module.admin_users.user_pool_arn
    # domain = module.admin_users.cognito_domain  # optional: omit to let module create aws_cognito_user_pool_domain
  }

  lambda = {
    dir         = "${path.module}/../../dist/apps/ai/mcp-service"
    handler     = "main.apiHandler"
    subnet_ids  = local.network.subnet_ids
    security_group_ids = local.network.security_group_ids
    extra_environment_variables = {
      SESSION_TABLE_NAME = aws_dynamodb_table.sessions.name
      EVENTS_TABLE_NAME  = aws_dynamodb_table.events.name
    }
  }

  mcp_callback_urls = ["https://claude.ai/api/mcp/auth_callback", "https://claude.com/api/mcp/auth_callback"]

  mcp_domain = {
    name            = "mcp.example.com"
    hosted_zone_id  = data.aws_route53_zone.zone.zone_id
    certificate_arn = data.aws_acm_certificate.star.arn
  }

  tags = local.tags
}
```

## Dependencies

- `../lambda` – Lambda creation
- `../gw_method_lambda` – API Gateway method + Lambda integration
- Cognito User Pool (optionally with existing domain; otherwise module creates one)
