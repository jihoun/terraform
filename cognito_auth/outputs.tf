output "Amplify_Auth" {
  value = {
    Auth = {
      Cognito = var.enabled ? {
        mandatorySignIn  = true
        region           = data.aws_region.current.region
        userPoolId       = aws_cognito_user_pool.user_pool[0].id
        identityPoolId   = aws_cognito_identity_pool.id_pool[0].id
        userPoolClientId = aws_cognito_user_pool_client.client[0].id
      } : {}
    }
  }
}

output "user_pool_arn" {
  value = var.enabled ? aws_cognito_user_pool.user_pool[0].arn : ""
}

output "cognito_role_arn" {
  value = var.enabled ? aws_iam_role.cognito_role[0].arn : ""
}
