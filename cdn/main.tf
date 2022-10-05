terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.31.0"
    }
  }
}

module "bucket" {
  source     = "../s3"
  name       = var.name
  dir        = var.dir
  log_bucket = var.log_bucket
  tags       = var.tags
}

data "aws_s3_bucket" "bucket" {
  bucket = module.bucket.bucket_name
}

data "aws_region" "current" {}

data "aws_cloudfront_cache_policy" "Managed_CachingOptimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_origin_request_policy" "Managed_CORS_S3Origin" {
  name = "Managed-CORS-S3Origin"
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "Used for ${var.name}-${terraform.workspace} cdn"
}


resource "aws_cloudfront_distribution" "cloudfront" {
  enabled         = true
  is_ipv6_enabled = true
  tags            = var.tags
  comment         = "Used for ${var.name} (${terraform.workspace}) cdn"
  aliases         = var.domain_names

  origin {
    connection_attempts = 3
    connection_timeout  = 10
    domain_name         = data.aws_s3_bucket.bucket.bucket_regional_domain_name
    origin_id           = data.aws_s3_bucket.bucket.id

    origin_shield {
      enabled              = true
      origin_shield_region = data.aws_region.current.name
    }

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    cache_policy_id          = data.aws_cloudfront_cache_policy.Managed_CachingOptimized.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.Managed_CORS_S3Origin.id
    viewer_protocol_policy   = "redirect-to-https"
    target_origin_id         = data.aws_s3_bucket.bucket.bucket
    cached_methods           = ["GET", "HEAD"]
    allowed_methods          = ["GET", "HEAD", "OPTIONS"]
    compress                 = true
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
  bucket = data.aws_s3_bucket.bucket.id
  policy = <<-POLICY
    {
      "Version": "2012-10-17",
      "Id": "PolicyForCloudFrontPrivateContent",
      "Statement": [
          {
              "Effect": "Allow",
              "Principal": {
                  "AWS": "${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"
              },
              "Action": "s3:GetObject",
              "Resource": "${data.aws_s3_bucket.bucket.arn}/*"
          },
          {
            "Sid": "AllowSSLRequestsOnly",
            "Action": "s3:*",
            "Effect": "Deny",
            "Resource": [
              "${data.aws_s3_bucket.bucket.arn}",
              "${data.aws_s3_bucket.bucket.arn}/*"
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
  bucket = data.aws_s3_bucket.bucket.id
  index_document { suffix = "index.html" }
  error_document { key = "index.html" }
}

resource "aws_route53_record" "www" {
  for_each = toset(var.domain_names)
  zone_id  = var.hosted_zone_id
  name     = each.key
  type     = "A"
  # ttl      = 0
  # records = []
  alias {
    evaluate_target_health = false
    name                   = aws_cloudfront_distribution.cloudfront.domain_name
    zone_id                = aws_cloudfront_distribution.cloudfront.hosted_zone_id
  }
}
