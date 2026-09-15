locals {
  tags = merge(var.tags, { Name = "${var.name}-${terraform.workspace}" })
}

data "aws_region" "current" {}

resource "aws_cognito_user_pool" "user_pool" {
  count                    = var.enabled ? 1 : 0
  name                     = "${var.name}_${terraform.workspace}"
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

  dynamic "schema" {
    for_each = var.schema
    content {
      name                     = schema.value.name
      attribute_data_type      = schema.value.attribute_data_type
      mutable                  = schema.value.mutable
      required                 = schema.value.required
      developer_only_attribute = false # prevents drift

      dynamic "string_attribute_constraints" {
        for_each = schema.value.attribute_data_type == "String" ? [1] : []
        content {
          min_length = schema.value.min_length
          max_length = schema.value.max_length
        }
      }
    }
  }

  dynamic "admin_create_user_config" {
    for_each = var.invite_email != null ? [1] : []
    content {
      invite_message_template {
        email_subject = try(var.invite_email.subject, null)
        email_message = try(var.invite_email.message, null)
        # Cognito requires SMS text whenever this block is set.
        sms_message = "Your username is {username} and temporary password is {####}."
      }
    }
  }

  dynamic "verification_message_template" {
    for_each = var.verification_email != null ? [1] : []
    content {
      default_email_option = "CONFIRM_WITH_CODE"
      email_subject        = try(var.verification_email.subject, null)
      email_message        = try(var.verification_email.message, null)
    }
  }

  dynamic "email_configuration" {
    for_each = var.email_configuration != null ? [var.email_configuration] : []
    content {
      email_sending_account = "DEVELOPER"
      from_email_address    = email_configuration.value.from_email_address
      source_arn            = email_configuration.value.source_arn
    }
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
    provider_name           = "cognito-idp.${data.aws_region.current.region}.amazonaws.com/${aws_cognito_user_pool.user_pool[0].id}"
    server_side_token_check = false
  }
}

resource "aws_iam_role" "cognito_role" {
  count = var.enabled ? 1 : 0
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "authenticated"
          }
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.id_pool[0].id
          }
        }
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
      }
    ]
  })
  path        = "/service-role/${terraform.workspace}/authed/"
  tags        = local.tags
  name_prefix = var.name
}

resource "aws_cognito_identity_pool_roles_attachment" "main" {
  count            = var.enabled ? 1 : 0
  identity_pool_id = aws_cognito_identity_pool.id_pool[0].id

  roles = {
    "authenticated" = aws_iam_role.cognito_role[0].arn
  }
}

resource "aws_iam_policy" "cognito_authed" {
  count       = var.enabled ? 1 : 0
  path        = "/service-role/${terraform.workspace}/authed/"
  name_prefix = var.name
  tags        = local.tags
  policy = jsonencode({
    Statement = [
      {
        Action   = ["cognito-identity:GetCredentialsForIdentity"]
        Effect   = "Allow"
        Resource = ["*"]
      }
    ]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "cognito_role_policy_attachment" {
  count      = var.enabled ? 1 : 0
  role       = aws_iam_role.cognito_role[0].name
  policy_arn = aws_iam_policy.cognito_authed[0].arn
}
