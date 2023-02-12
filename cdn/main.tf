terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.31.0"
    }
  }
}

module "bucket" {
  enabled    = var.enabled
  source     = "../s3"
  name       = var.name
  dir        = var.dir
  log_bucket = var.log_bucket
  tags       = var.tags
  cors       = var.cors
}

data "aws_s3_bucket" "bucket" {
  count  = var.enabled ? 1 : 0
  bucket = module.bucket.bucket_name
}

data "aws_region" "current" {}

data "aws_cloudfront_cache_policy" "Managed_CachingOptimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_origin_request_policy" "Managed_CORS_S3Origin" {
  name = "Managed-CORS-S3Origin"
}

data "aws_cloudfront_response_headers_policy" "Managed_CORS_With_Preflight" {
  name = "Managed-SimpleCORS"
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  count   = var.enabled ? 1 : 0
  comment = "Used for ${var.name}-${terraform.workspace} cdn"
}

resource "aws_cloudfront_distribution" "cloudfront" {
  count           = var.enabled ? 1 : 0
  enabled         = true
  is_ipv6_enabled = true
  tags            = var.tags
  comment         = "Used for ${var.name} (${terraform.workspace}) cdn"
  aliases         = var.domain_names

  origin {
    connection_attempts = 3
    connection_timeout  = 10
    domain_name         = data.aws_s3_bucket.bucket[0].bucket_regional_domain_name
    origin_id           = data.aws_s3_bucket.bucket[0].id

    origin_shield {
      enabled              = true
      origin_shield_region = data.aws_region.current.name
    }

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity[0].cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    cache_policy_id            = data.aws_cloudfront_cache_policy.Managed_CachingOptimized.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.Managed_CORS_S3Origin.id
    response_headers_policy_id = var.cors ? data.aws_cloudfront_response_headers_policy.Managed_CORS_With_Preflight.id : null
    viewer_protocol_policy     = "redirect-to-https"
    target_origin_id           = data.aws_s3_bucket.bucket[0].bucket
    cached_methods             = ["GET", "HEAD", "OPTIONS"]
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    compress                   = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = var.certificate_arn == null
    acm_certificate_arn            = var.certificate_arn
    minimum_protocol_version       = var.certificate_arn != null ? "TLSv1.2_2021" : "TLSv1"
    ssl_support_method             = var.certificate_arn != null ? "sni-only" : null
  }

  dynamic "logging_config" {
    for_each = var.log_bucket != null ? [var.log_bucket] : []
    content {
      bucket          = "${logging_config.value}.s3.amazonaws.com"
      include_cookies = false
      prefix          = "cloudfront/${var.name}-${terraform.workspace}"
    }
  }

  custom_error_response {
    error_caching_min_ttl = 10
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  count  = var.enabled ? 1 : 0
  bucket = data.aws_s3_bucket.bucket[0].id
  policy = <<-POLICY
    {
      "Version": "2012-10-17",
      "Id": "PolicyForCloudFrontPrivateContent",
      "Statement": [
          {
              "Effect": "Allow",
              "Principal": {
                  "AWS": "${aws_cloudfront_origin_access_identity.origin_access_identity[0].iam_arn}"
              },
              "Action": "s3:GetObject",
              "Resource": "${data.aws_s3_bucket.bucket[0].arn}/*"
          },
          {
            "Sid": "AllowSSLRequestsOnly",
            "Action": "s3:*",
            "Effect": "Deny",
            "Resource": [
              "${data.aws_s3_bucket.bucket[0].arn}",
              "${data.aws_s3_bucket.bucket[0].arn}/*"
            ],
            "Condition": {
              "Bool": {
                "aws:SecureTransport": "false"
              }
            },
            "Principal": "*"
          }
      ]
    }
  POLICY
}

resource "aws_s3_bucket_website_configuration" "website_configuration" {
  count  = var.enabled ? 1 : 0
  bucket = data.aws_s3_bucket.bucket[0].id
  index_document { suffix = "index.html" }
  error_document { key = "index.html" }
}

resource "aws_route53_record" "www" {
  for_each = toset(var.enabled ? var.domain_names : [])
  zone_id  = var.hosted_zone_id
  name     = each.key
  type     = "A"
  # ttl      = 0
  # records = []
  alias {
    evaluate_target_health = false
    name                   = aws_cloudfront_distribution.cloudfront[0].domain_name
    zone_id                = aws_cloudfront_distribution.cloudfront[0].hosted_zone_id
  }
}

module "invalidation_lambda" {
  enabled = var.enabled && var.dir != null
  source  = "../lambda"
  dir     = "${path.module}/cloudfront-lambda"
  name    = "cf-${var.name}-invalidation"
  timeout = 30
  environment_variables = {
    DISTRIBUTION_ID = var.enabled ? aws_cloudfront_distribution.cloudfront[0].id : ""
  }
}


data "aws_iam_policy_document" "policy_doc" {
  count = var.enabled && var.dir != null ? 1 : 0
  statement {
    actions   = ["cloudfront:CreateInvalidation"]
    resources = [aws_cloudfront_distribution.cloudfront[0].arn]
  }
}

resource "aws_iam_policy" "invalidation_policy" {
  count       = var.enabled && var.dir != null ? 1 : 0
  name_prefix = "${var.name}_cf_invalidate_${terraform.workspace}"
  policy      = data.aws_iam_policy_document.policy_doc[0].json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "invalidation_role" {
  count      = var.enabled && var.dir != null ? 1 : 0
  policy_arn = aws_iam_policy.invalidation_policy[0].arn
  role       = module.invalidation_lambda.role_name
}

resource "aws_lambda_invocation" "cloudfront_invalidate" {
  count         = var.enabled && var.dir != null ? 1 : 0
  function_name = module.invalidation_lambda.function_name
  input         = jsonencode({})
  triggers = {
    redeployment = module.bucket.files_hash
  }
}
