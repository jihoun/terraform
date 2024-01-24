data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_kms_key" "key" {
  count                    = var.enabled ? 1 : 0
  description              = "Key to encrypt cloudwatch log group ${var.log_group_name}. Managed by terraform."
  is_enabled               = true
  multi_region             = false
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  tags                     = var.tags
  enable_key_rotation      = true
  policy                   = <<-JSON
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "Enable IAM User Permissions",
        "Effect": "Allow",
        "Principal": {
          "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        "Action": "kms:*",
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "logs.${data.aws_region.current.name}.amazonaws.com"
        },
        "Action": [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ],
        "Resource": "*",
        "Condition": {
          "ArnEquals": {
            "kms:EncryptionContext:aws:logs:arn": "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${var.log_group_name}"
          }
        }
      }
    ]
  }
  JSON
}

resource "aws_kms_alias" "alias" {
  count         = var.enabled ? 1 : 0
  name          = "alias/logs_${var.log_group_name}"
  target_key_id = aws_kms_key.key[0].key_id
}
