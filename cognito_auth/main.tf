locals {
  tags = merge(var.tags, { Name = "${var.name}-${terraform.workspace}" })
}

data "aws_region" "current" {}

resource "aws_cognito_user_pool" "user_pool" {
  count                    = var.enabled ? 1 : 0
  name                     = "admin_${terraform.workspace}"
  deletion_protection      = "ACTIVE"
  tags                     = local.tags
  auto_verified_attributes = ["email"]
  mfa_configuration        = "OPTIONAL"

  software_token_mfa_configuration {
    enabled = true
  }

  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }
}

resource "aws_cognito_user_pool_client" "client" {
  count                         = var.enabled ? 1 : 0
  user_pool_id                  = aws_cognito_user_pool.user_pool[0].id
  name                          = "${var.name}_${terraform.workspace}"
  explicit_auth_flows           = ["ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_SRP_AUTH"]
  refresh_token_validity        = 7
  prevent_user_existence_errors = "ENABLED"
  token_validity_units { refresh_token = "days" }
}

resource "aws_cognito_identity_pool" "id_pool" {
  count              = var.enabled ? 1 : 0
  identity_pool_name = aws_cognito_user_pool.user_pool[0].name
  tags               = local.tags

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.client[0].id
    provider_name           = "cognito-idp.${data.aws_region.current.name}.amazonaws.com/${aws_cognito_user_pool.user_pool[0].id}"
    server_side_token_check = false
  }
}

