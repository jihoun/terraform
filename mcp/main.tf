data "aws_region" "current" {}

locals {
  tags = merge(var.tags, { Name = var.name })

  lambda_function_name = var.enabled && length(module.lambda) > 0 ? module.lambda[0].function_name : ""
  lambda_role_name     = var.enabled && length(module.lambda) > 0 ? module.lambda[0].role_name : ""

  # Cognito domain: from input or derived from created aws_cognito_user_pool_domain
  cognito_domain_host = var.enabled && (try(var.cognito.domain, null) != null && var.cognito.domain != "") ? var.cognito.domain : (
    var.enabled && length(aws_cognito_user_pool_domain.mcp) > 0 ? "${aws_cognito_user_pool_domain.mcp[0].domain}.auth.${data.aws_region.current.region}.amazoncognito.com" : ""
  )
}
