resource "aws_cloudwatch_event_rule" "cron" {
  count               = var.enabled ? 1 : 0
  name                = "${var.name}_${terraform.workspace}"
  description         = "Managed by terraform for ${var.name} (${terraform.workspace})"
  schedule_expression = var.cron != null ? "cron(${var.cron})" : "rate(${var.rate})"
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "lambda" {
  count = var.enabled ? 1 : 0
  rule  = aws_cloudwatch_event_rule.cron[0].name
  arn   = var.lambda_arn
}

resource "aws_lambda_permission" "allow_event_bridge" {
  count         = var.enabled ? 1 : 0
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cron[0].arn
}
