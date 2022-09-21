resource "aws_kms_key" "cloudtrail" {
  tags                               = var.tags
  description                        = "Managed by terraform for ${terraform.workspace}. For cloudtrail encryption."
  key_usage                          = "ENCRYPT_DECRYPT"
  customer_master_key_spec           = "SYMMETRIC_DEFAULT"
  bypass_policy_lockout_safety_check = false
  is_enabled                         = true
  enable_key_rotation                = true
  multi_region                       = false
  policy                             = <<-JSON
  {
    "Id": "Key policy created by CloudTrail",
    "Statement": [
      {
        "Action": "kms:*",
        "Effect": "Allow",
        "Principal": {
          "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        "Resource": "*",
        "Sid": "Enable IAM User Permissions"
      },
      {
        "Action": "kms:GenerateDataKey*",
        "Condition": {
            "StringEquals": {
              "AWS:SourceArn": "arn:aws:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/management-events"
            },
            "StringLike": {
              "kms:EncryptionContext:aws:cloudtrail:arn": "arn:aws:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/*"
            }
        },
        "Effect": "Allow",
        "Principal": {
          "Service": "cloudtrail.amazonaws.com"
        },
        "Resource": "*",
        "Sid": "Allow CloudTrail to encrypt logs"
      },
      {
        "Action": "kms:DescribeKey",
        "Effect": "Allow",
        "Principal": {
          "Service": "cloudtrail.amazonaws.com"
        },
        "Resource": "*",
        "Sid": "Allow CloudTrail to describe key"
      },
      {
        "Action": ["kms:Decrypt", "kms:ReEncryptFrom"],
        "Condition": {
          "StringEquals": {
            "kms:CallerAccount": "${data.aws_caller_identity.current.account_id}"
          },
          "StringLike": {
            "kms:EncryptionContext:aws:cloudtrail:arn": "arn:aws:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/*"
          }
        },
        "Effect": "Allow",
        "Principal": {
          "AWS": "*"
        },
        "Resource": "*",
        "Sid": "Allow principals in the account to decrypt log files"
      },
      {
        "Action": "kms:CreateAlias",
        "Condition": {
          "StringEquals": {
            "kms:CallerAccount": "${data.aws_caller_identity.current.account_id}",
            "kms:ViaService": "ec2.${data.aws_region.current.name}.amazonaws.com"
          }
        },
        "Effect": "Allow",
        "Principal": {  "AWS": "*" },
        "Resource": "*",
        "Sid": "Allow alias creation during setup"
      },
      {
        "Action": ["kms:Decrypt", "kms:ReEncryptFrom"],
        "Condition": {
          "StringEquals": {
            "kms:CallerAccount": "${data.aws_caller_identity.current.account_id}"
          },
          "StringLike": {
            "kms:EncryptionContext:aws:cloudtrail:arn": "arn:aws:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/*"
          }
        },
        "Effect": "Allow",
        "Principal": {  "AWS": "*" },
        "Resource": "*",
        "Sid": "Enable cross account log decryption"
      }
    ],
    "Version": "2012-10-17"
  }
  JSON
  depends_on = [
    aws_s3_bucket_policy.log_bucket_policy
  ]
}

resource "aws_kms_alias" "cloudtrail" {
  name          = "alias/cloudtrail-${terraform.workspace}"
  target_key_id = aws_kms_key.cloudtrail.key_id
}

module "ct_logs_key" {
  source         = "../log_key"
  tags           = var.tags
  log_group_name = "cloudtrail-${terraform.workspace}"
}

resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "cloudtrail-${terraform.workspace}"
  retention_in_days = 365
  tags              = var.tags
  kms_key_id        = module.ct_logs_key.key_arn
}

resource "aws_iam_role" "cloudtrail" {
  name_prefix        = "cloudtrail-${terraform.workspace}"
  tags               = var.tags
  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "cloudtrail.amazonaws.com"
        },
        "Effect": "Allow"
      }
    ]
  }
  EOF
}

resource "aws_iam_policy" "cloudtrail_cloudwatch" {
  name_prefix = "cloudtrail-cloudwatch-${terraform.workspace}"
  path        = "/${terraform.workspace}/"
  policy      = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
        {
        "Effect": "Allow",
        "Action": [
            "logs:CreateLogStream"
        ],
        "Resource": [
            "${aws_cloudwatch_log_group.cloudtrail.arn}:log-stream:${data.aws_caller_identity.current.account_id}_CloudTrail_${data.aws_region.current.name}*"
        ]
        },
        {
        "Effect": "Allow",
        "Action": [
            "logs:PutLogEvents"
        ],
        "Resource": [
            "${aws_cloudwatch_log_group.cloudtrail.arn}:log-stream:${data.aws_caller_identity.current.account_id}_CloudTrail_${data.aws_region.current.name}*"
        ]
        }
    ]
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "cloudtrail_cloudwatch" {
  policy_arn = aws_iam_policy.cloudtrail_cloudwatch.arn
  role       = aws_iam_role.cloudtrail.id
}

resource "aws_cloudtrail" "trail" {
  name                          = "management-events"
  s3_bucket_name                = module.log_bucket.bucket_name
  s3_key_prefix                 = "cloudtrail"
  include_global_service_events = true
  is_multi_region_trail         = true
  is_organization_trail         = false
  enable_log_file_validation    = true
  kms_key_id                    = aws_kms_key.cloudtrail.arn
  tags                          = var.tags
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail.arn

  advanced_event_selector {
    name = "Management events selector"

    field_selector {
      equals = [
        "Management",
      ]
      field = "eventCategory"
    }
    field_selector {
      field = "eventSource"
      not_equals = [
        "kms.amazonaws.com",
        "rdsdata.amazonaws.com",
      ]
    }
  }
}
