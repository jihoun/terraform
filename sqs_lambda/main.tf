data "aws_iam_policy_document" "policy" {
  statement {
    actions   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
    resources = [var.queue_arn]
  }
}

resource "aws_iam_policy" "policy" {
  name_prefix = "sqs_2_lambda_${terraform.workspace}"
  path        = "/lambda/${terraform.workspace}/"
  policy      = data.aws_iam_policy_document.policy.json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "role" {
  policy_arn = aws_iam_policy.policy.arn
  role       = var.function_role
}

resource "aws_lambda_event_source_mapping" "mapping" {
  event_source_arn        = var.queue_arn
  function_name           = var.function_arn
  function_response_types = var.reports_errors ? ["ReportBatchItemFailures"] : null
  depends_on              = [aws_iam_role_policy_attachment.role]
}
