
module "terraform_bucket" {
  enabled    = var.enabled
  source     = "../s3"
  name       = "terraform"
  log_bucket = var.log_bucket
  tags       = var.tags
}

resource "aws_dynamodb_table" "terraform" {
  count        = var.enabled ? 1 : 0
  name         = "terraform-${terraform.workspace}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  tags         = var.tags

  server_side_encryption {
    enabled = true
  }

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }
}

resource "aws_iam_policy" "terraform" {
  count       = var.enabled ? 1 : 0
  name_prefix = "terraform-${terraform.workspace}"
  tags        = var.tags
  policy      = <<-POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": "s3:ListBucket",
        "Resource": "arn:aws:s3:::${module.terraform_bucket.bucket_name}"
      },
      {
        "Effect": "Allow",
        "Action": ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
        "Resource": "arn:aws:s3:::${module.terraform_bucket.bucket_name}/*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ],
        "Resource": "${aws_dynamodb_table.terraform[0].arn}"
      }
    ]
  }
  POLICY
}

resource "aws_iam_user" "user" {
  count = var.enabled ? 1 : 0
  name  = "terraform-backend"
  path  = "/technical/"
  tags  = var.tags
}

#tfsec:ignore:aws-iam-enforce-group-mfa
resource "aws_iam_group" "group" {
  count = var.enabled ? 1 : 0
  name  = "terraform-backend"
  path  = "/technical/"
}

resource "aws_iam_group_membership" "group" {
  count = var.enabled ? 1 : 0
  name  = "terraform-backend"
  users = [aws_iam_user.user[0].name]
  group = aws_iam_group.group[0].name
}

resource "aws_iam_group_policy_attachment" "group-policy" {
  count      = var.enabled ? 1 : 0
  group      = aws_iam_group.group[0].name
  policy_arn = aws_iam_policy.terraform[0].arn
}
