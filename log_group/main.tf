
module "log_key" {
  count          = var.enabled && var.encrypted ? 1 : 0
  source         = "../log_key"
  log_group_name = var.log_group_name
  tags           = var.tags
}

resource "aws_cloudwatch_log_group" "lg" {
  count             = var.enabled ? 1 : 0
  name              = var.log_group_name
  retention_in_days = var.log_retention
  tags              = var.tags
  kms_key_id        = var.encrypted ? module.log_key[0].key_arn : null
}
