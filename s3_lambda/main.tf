resource "aws_lambda_permission" "allow_bucket" {
  for_each            = var.enabled ? var.events : {}
  statement_id_prefix = "AllowExecutionFromS3Bucket"
  action              = "lambda:InvokeFunction"
  function_name       = each.value.function_arn
  principal           = "s3.amazonaws.com"
  source_arn          = var.bucket_arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  count       = var.enabled && length(var.events) != 0 ? 1 : 0
  bucket      = var.bucket_name
  eventbridge = var.eventbridge

  dynamic "lambda_function" {
    for_each = var.events
    content {
      lambda_function_arn = lambda_function.value.function_arn
      events              = lambda_function.value.events
      filter_prefix       = lambda_function.value.prefix
      filter_suffix       = lambda_function.value.suffix
      id                  = lambda_function.key
    }
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}
