data "aws_iam_policy_document" "policy" {
  count = var.enabled ? 1 : 0
  statement {
    actions   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
    resources = [var.queue_arn]
  }
}

resource "aws_iam_policy" "policy" {
  count       = var.enabled ? 1 : 0
  name_prefix = "sqs_2_lambda_${terraform.workspace}"
  path        = "/lambda/${terraform.workspace}/"
  policy      = data.aws_iam_policy_document.policy[0].json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "role" {
  count      = var.enabled ? 1 : 0
  policy_arn = aws_iam_policy.policy[0].arn
  role       = var.function_role
}

resource "aws_lambda_event_source_mapping" "mapping" {
  count                   = var.enabled ? 1 : 0
  event_source_arn        = var.queue_arn
  function_name           = var.function_arn
  function_response_types = var.reports_errors ? ["ReportBatchItemFailures"] : null
  depends_on              = [aws_iam_role_policy_attachment[0].role]
}
