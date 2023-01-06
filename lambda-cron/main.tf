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
