
resource "aws_cloudwatch_event_rule" "listener" {
  name_prefix    = substr("${var.lambda.name}_${var.bus_name}", 0, 38)
  description    = "Managed by terraform for ${terraform.workspace}"
  event_bus_name = var.bus_name
  event_pattern  = var.event_pattern
  tags           = var.tags
}

resource "aws_lambda_permission" "allow_event_bridge" {
  action        = "lambda:InvokeFunction"
  function_name = var.lambda.name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.listener.arn
}

resource "aws_cloudwatch_event_target" "listener" {
  rule           = aws_cloudwatch_event_rule.listener.name
  event_bus_name = aws_cloudwatch_event_rule.listener.event_bus_name
  arn            = var.lambda.arn
}
