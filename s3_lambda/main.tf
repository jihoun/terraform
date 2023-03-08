resource "aws_lambda_permission" "allow_bucket" {
  statement_id_prefix = "AllowExecutionFromS3Bucket"
  action              = "lambda:InvokeFunction"
  function_name       = var.function_arn
  principal           = "s3.amazonaws.com"
  source_arn          = var.bucket_arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = var.bucket_name

  lambda_function {
    lambda_function_arn = var.function_arn
    events              = var.events
    filter_prefix       = var.prefix
    filter_suffix       = var.suffix
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}
