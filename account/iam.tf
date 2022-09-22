resource "aws_iam_service_linked_role" "config" {
  aws_service_name = "config.amazonaws.com"

  tags        = var.tags
  description = "Managed by terraform"

  # managed_policy_arns = ["arn:aws:iam::aws:policy/aws-service-role/AWSConfigServiceRolePolicy"]
}

resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_numbers                = true
  max_password_age               = 90
  password_reuse_prevention      = 24
  require_uppercase_characters   = true
  require_symbols                = true
  allow_users_to_change_password = true
}
