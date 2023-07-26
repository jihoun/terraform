resource "aws_sns_topic" "topic" {
  count          = var.use_sns ? 1 : 0
  name_prefix    = "quotas_${terraform.workspace}"
  tracing_config = var.trace ? "Active" : "PassThrough"
  tags           = var.tags
}

module "dynamodb" {
  source  = "./dynamodb"
  enabled = var.dynamodb
  tags    = var.tags
  sns     = var.use_sns ? aws_sns_topic.topic[0].arn : null
}

module "lambda" {
  source  = "./lambda"
  enabled = var.lambda
  tags    = var.tags
  sns     = var.use_sns ? aws_sns_topic.topic[0].arn : null
}

module "cloudwatch" {
  source  = "./cloudwatch"
  enabled = var.cloudwatch
  tags    = var.tags
  sns     = var.use_sns ? aws_sns_topic.topic[0].arn : null
}

module "cognito" {
  source  = "./cognito"
  enabled = var.cognito
  tags    = var.tags
  sns     = var.use_sns ? aws_sns_topic.topic[0].arn : null
}

module "kms" {
  source  = "./kms"
  enabled = var.kms
  tags    = var.tags
  sns     = var.use_sns ? aws_sns_topic.topic[0].arn : null
}
