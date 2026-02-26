# CloudFront distribution for MCP API - exposes custom domain so OAuth discovery
# at https://<mcp_domain>/.well-known/oauth-authorization-server is reachable by Claude.
data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "all_viewer_except_host" {
  name = "Managed-AllViewerExceptHostHeader"
}

locals {
  api_gateway_domain = var.enabled && length(aws_api_gateway_rest_api.api) > 0 ? "${aws_api_gateway_rest_api.api[0].id}.execute-api.${data.aws_region.current.region}.amazonaws.com" : ""
}

resource "aws_cloudfront_distribution" "mcp" {
  count = var.enabled && var.mcp_domain != null ? 1 : 0

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "MCP API for ${var.name}"
  default_root_object  = ""
  price_class          = "PriceClass_100"

  aliases = [var.mcp_domain.name]

  origin {
    domain_name = local.api_gateway_domain
    origin_id   = "mcp-api-gateway"
    origin_path = "/api"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy  = "https-only"
      origin_ssl_protocols    = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods            = ["GET", "HEAD", "OPTIONS"]
    target_origin_id          = "mcp-api-gateway"
    cache_policy_id           = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id  = data.aws_cloudfront_origin_request_policy.all_viewer_except_host.id
    viewer_protocol_policy    = "redirect-to-https"
    compress                  = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.mcp_domain.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
    cloudfront_default_certificate = false
  }

  tags = local.tags
}

resource "aws_route53_record" "mcp" {
  count = var.enabled && var.mcp_domain != null ? 1 : 0

  zone_id = var.mcp_domain.hosted_zone_id
  name    = var.mcp_domain.name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.mcp[0].domain_name
    zone_id                = aws_cloudfront_distribution.mcp[0].hosted_zone_id
    evaluate_target_health = false
  }
}
