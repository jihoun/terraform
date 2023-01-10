resource "aws_cloudwatch_event_rule" "cron" {
  name                = "${var.name}_${terraform.workspace}"
  description         = "Managed by terraform for ${var.name} (${terraform.workspace})"
  schedule_expression = "cron(${var.cron})"
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule = aws_cloudwatch_event_rule.cron.name
  arn  = var.lambda_arn
}

resource "aws_lambda_permission" "allow_event_bridge" {
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cron.arn
}
