data "aws_iam_policy_document" "policy" {
  statement {
    actions = [
      "dynamodb:GetRecords",
      "dynamodb:GetShardIterator",
      "dynamodb:DescribeStream",
      "dynamodb:ListStreams"
    ]
    resources = [var.stream_arn]
  }
}

resource "aws_iam_policy" "policy" {
  count       = var.enabled ? 1 : 0
  path        = "/lambda/${terraform.workspace}/"
  name_prefix = "${var.function_name}_stream_"
  policy      = data.aws_iam_policy_document.policy.json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "role_policy" {
  count      = var.enabled ? 1 : 0
  role       = var.function_role_name
  policy_arn = aws_iam_policy.policy[0].arn
}

resource "aws_lambda_event_source_mapping" "stream_2_lambda" {
  count                              = var.enabled ? 1 : 0
  event_source_arn                   = var.stream_arn
  function_name                      = var.function_name
  depends_on                         = [aws_iam_role_policy_attachment.role_policy]
  maximum_batching_window_in_seconds = 3   #minimizes number of lambda calls
  batch_size                         = 100 # default dynamodb
  function_response_types            = var.reports_errors ? ["ReportBatchItemFailures"] : null
  starting_position                  = "LATEST"
  bisect_batch_on_function_error     = true
}
