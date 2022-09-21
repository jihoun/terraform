resource "aws_iam_role" "config" {
  name                = "AWSServiceRoleForConfig"
  path                = "/aws-service-role/config.amazonaws.com/"
  tags                = var.tags
  description         = "Managed by terraform"
  assume_role_policy  = <<JSON
  {
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Effect": "Allow",
        "Principal": {
          "Service": "config.amazonaws.com"
        }
      }
    ],
    "Version": "2012-10-17"
  }
  JSON
  managed_policy_arns = ["arn:aws:iam::aws:policy/aws-service-role/AWSConfigServiceRolePolicy"]
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
