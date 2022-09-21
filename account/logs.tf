
module "log_bucket" {
  source = "../s3"
  name   = "logs"
}

resource "aws_s3_bucket_policy" "log_bucket_policy" {
  bucket = module.log_bucket.bucket_name
  policy = <<-POLICY
  {
    "Statement": [
      {
        "Action": "s3:PutObject",
        "Effect": "Allow",
        "Principal": {
          "Service": "logging.s3.amazonaws.com"
        },
        "Resource": "${module.log_bucket.bucket_arn}/*"
      },
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "cloudtrail.amazonaws.com"
        },
        "Action": "s3:GetBucketAcl",
        "Resource": "${module.log_bucket.bucket_arn}",
        "Condition": {
          "StringEquals": {
            "AWS:SourceArn": "arn:aws:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/management-events"
          }
        }
      },
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "cloudtrail.amazonaws.com"
        },
        "Action": "s3:PutObject",
        "Resource": "${module.log_bucket.bucket_arn}/cloudtrail/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
        "Condition": {
          "StringEquals": {
            "AWS:SourceArn": "arn:aws:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/management-events",
            "s3:x-amz-acl": "bucket-owner-full-control"
          }
        }
      },
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "config.amazonaws.com"
        },
        "Action": "s3:GetBucketAcl",
        "Resource": "${module.log_bucket.bucket_arn}",
        "Condition": { 
          "StringEquals": {
            "AWS:SourceAccount": "${data.aws_caller_identity.current.account_id}"
          }
        }
      },
      {
        "Sid": "AWSConfigBucketExistenceCheck",
        "Effect": "Allow",
        "Principal": {
          "Service": "config.amazonaws.com"
        },
        "Action": "s3:ListBucket",
        "Resource": "${module.log_bucket.bucket_arn}",
        "Condition": { 
          "StringEquals": {
            "AWS:SourceAccount": "${data.aws_caller_identity.current.account_id}"
          }
        }
      },
      {
        "Sid": "AWSConfigBucketDelivery",
        "Effect": "Allow",
        "Principal": {
          "Service": "config.amazonaws.com"
        },
        "Action": "s3:PutObject",
        "Resource": "${module.log_bucket.bucket_arn}/config/AWSLogs/${data.aws_caller_identity.current.account_id}/Config/*",
        "Condition": { 
          "StringEquals": { 
            "s3:x-amz-acl": "bucket-owner-full-control",
            "AWS:SourceAccount": "${data.aws_caller_identity.current.account_id}"
          }
        }
      }
    ],
    "Version": "2012-10-17"
  }
  POLICY
}
