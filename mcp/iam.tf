# Attach GetSecretValue policy to Lambda role
data "aws_iam_policy_document" "dcr_secret" {
  count = var.enabled ? 1 : 0

  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.mcp_oauth_client_secret[0].arn]
  }
}

resource "aws_iam_role_policy" "dcr_secret" {
  count = var.enabled ? 1 : 0

  name   = "${var.name}_dcr_secret"
  role   = local.lambda_role_name
  policy = data.aws_iam_policy_document.dcr_secret[0].json
}
