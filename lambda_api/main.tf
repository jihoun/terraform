locals {
  cache      = var.cache_size != null || var.cache_ttl != null
  cache_ttl  = var.cache_ttl != null ? var.cache_ttl : 300
  cache_size = var.cache_size != null ? var.cache_size : 0.5
  tags       = merge(var.tags, { Name : var.name })
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_api_gateway_rest_api" "api" {
  name               = "${var.name}-${terraform.workspace}"
  tags               = local.tags
  description        = "Deployed by Terraform, for ${var.name} (${terraform.workspace})"
  binary_media_types = var.binary_media_types
  policy = var.vpc_id != null ? jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : "execute-api:Invoke",
        "Resource" : ["arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.id}:*/*"]
      },
      {
        "Effect" : "Deny",
        "Principal" : "*",
        "Action" : "execute-api:Invoke",
        "Resource" : ["arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.id}:*/*"],
        "Condition" : {
          "StringNotEquals" : { "aws:SourceVpc" : "${var.vpc_id}" }
        }
      }
    ]
  }) : null

  endpoint_configuration {
    types            = [var.vpc_id != null ? "PRIVATE" : "EDGE"]
    vpc_endpoint_ids = var.endpoint_id != null ? [var.endpoint_id] : null
  }
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "{proxy+}"
}

module "cors" {
  source      = "../cors"
  enabled     = var.cors
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.proxy.id
}

module "method" {
  source               = "../gw_method_lambda"
  rest_api_id          = aws_api_gateway_rest_api.api.id
  resource_id          = aws_api_gateway_resource.proxy.id
  authorization        = var.cognito != null ? "COGNITO_USER_POOLS" : "NONE"
  authorizer_id        = var.cognito != null ? aws_api_gateway_authorizer.cognito_auth[0].id : null
  api_key_required     = var.requires_key
  cache_key_parameters = var.cache_key_parameters
  function_name        = var.function_name
}

locals {
  stage_description = var.over_deploy ? "Deployed for sha: ${base64sha256(jsonencode({ api : aws_api_gateway_rest_api.api, method : module.method }))} on ${timestamp()}" : "Deployed for sha: ${base64sha256(jsonencode({ api : aws_api_gateway_rest_api.api, method : module.method }))}"
}

resource "aws_api_gateway_deployment" "deploy" {
  rest_api_id       = aws_api_gateway_rest_api.api.id
  stage_description = local.stage_description

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.api.body))
  }

  lifecycle {
    create_before_destroy = true
  }
  depends_on = [module.method]
}

resource "aws_api_gateway_stage" "stage" {
  deployment_id = aws_api_gateway_deployment.deploy.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = var.stage_name
  #tfsec:ignore:aws-api-gateway-enable-tracing
  xray_tracing_enabled  = var.trace
  client_certificate_id = aws_api_gateway_client_certificate.certificate.id
  cache_cluster_enabled = local.cache ? true : null
  cache_cluster_size    = local.cache ? local.cache_size : null
  depends_on            = [aws_cloudwatch_log_group.log]
  tags                  = local.tags
}

resource "aws_wafv2_web_acl_association" "wacl" {
  count        = var.web_acl_arn != null ? 1 : 0
  resource_arn = aws_api_gateway_stage.stage.arn
  web_acl_arn  = var.web_acl_arn
}

locals {
  log_group_name = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.api.id}/${var.stage_name}"
}

module "log_key" {
  source         = "../log_key"
  log_group_name = local.log_group_name
  tags           = local.tags
}

resource "aws_cloudwatch_log_group" "log" {
  name              = local.log_group_name
  retention_in_days = var.log_retention
  tags              = local.tags
  kms_key_id        = module.log_key.key_arn
}

resource "aws_api_gateway_method_settings" "general_settings" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = var.stage_name
  method_path = "*/*"

  settings {
    # Enable CloudWatch logging and metrics
    metrics_enabled    = var.metrics
    data_trace_enabled = var.trace
    logging_level      = var.logging_level

    # Limit the rate of calls to prevent abuse and unwanted charges
    throttling_rate_limit  = 1000
    throttling_burst_limit = 500

    #cache
    cache_data_encrypted = local.cache ? true : null
    cache_ttl_in_seconds = local.cache ? local.cache_ttl : null # 5 minutes
  }

  depends_on = [aws_api_gateway_stage.stage]
}

resource "aws_api_gateway_authorizer" "cognito_auth" {
  count         = var.cognito != null ? 1 : 0
  rest_api_id   = aws_api_gateway_rest_api.api.id
  name          = "cognito-auth-${terraform.workspace}"
  type          = "COGNITO_USER_POOLS"
  provider_arns = var.cognito
}

resource "aws_api_gateway_usage_plan" "usage_plan" {
  count       = var.requires_key ? 1 : 0
  name        = "${var.name}-${terraform.workspace}"
  description = "Usage plan for ${var.name} (${terraform.workspace})"
  tags        = local.tags

  api_stages {
    api_id = aws_api_gateway_rest_api.api.id
    stage  = aws_api_gateway_stage.stage.stage_name
  }
}

resource "aws_api_gateway_client_certificate" "certificate" {
  description = "${var.name}-${terraform.workspace} certificate"
  tags        = local.tags
}

resource "aws_cloudwatch_metric_alarm" "five" {
  count                     = var.alarm != null ? var.alarm.five != null ? 1 : 0 : 0
  alarm_name                = "Api ${var.name} 5XXError > ${var.alarm.five}"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = 1
  threshold                 = var.alarm.five
  datapoints_to_alarm       = 1
  treat_missing_data        = "notBreaching"
  alarm_actions             = var.alarm.sns != null ? [var.alarm.sns] : []
  dimensions                = { "ApiName" = aws_api_gateway_rest_api.api.name }
  metric_name               = "5XXError"
  namespace                 = "AWS/ApiGateway"
  ok_actions                = []
  insufficient_data_actions = []
  period                    = 300
  statistic                 = "Sum"
  tags                      = local.tags
}

resource "aws_cloudwatch_metric_alarm" "four" {
  count                     = var.alarm != null ? var.alarm.four != null ? 1 : 0 : 0
  alarm_name                = "Api ${var.name} 4XXError > ${var.alarm.four}"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = 1
  threshold                 = var.alarm.four
  datapoints_to_alarm       = 1
  treat_missing_data        = "notBreaching"
  alarm_actions             = var.alarm.sns != null ? [var.alarm.sns] : []
  dimensions                = { "ApiName" = aws_api_gateway_rest_api.api.name }
  metric_name               = "4XXError"
  namespace                 = "AWS/ApiGateway"
  ok_actions                = []
  insufficient_data_actions = []
  period                    = 300
  statistic                 = "Sum"
  tags                      = local.tags
}
