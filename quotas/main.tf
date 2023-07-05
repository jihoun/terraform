module "dynamodb" {
  source  = "./dynamodb"
  enabled = var.dynamodb
  tags    = var.tags
}
module "lambda" {
  source  = "./lambda"
  enabled = var.lambda
  tags    = var.tags
}
module "cloudwatch" {
  source  = "./cloudwatch"
  enabled = var.cloudwatch
  tags    = var.tags
}
module "cognito" {
  source  = "./cognito"
  enabled = var.cognito
  tags    = var.tags
}
module "kms" {
  source  = "./kms"
  enabled = var.kms
  tags    = var.tags
}
