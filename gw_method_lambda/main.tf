resource "aws_api_gateway_method" "method" {
  rest_api_id      = var.rest_api_id
  resource_id      = var.resource_id
  http_method      = var.http_method
  authorization    = var.authorization
  authorizer_id    = var.authorizer_id
  api_key_required = var.api_key_required
  request_parameters = merge(
    { "method.request.path.proxy" = true },
    {
      for o in var.cache_key_parameters :
      o => false
    }
  )

}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_api_gateway_integration" "method" {
  rest_api_id             = var.rest_api_id
  resource_id             = var.resource_id
  http_method             = var.http_method
  type                    = "AWS_PROXY"
  cache_key_parameters    = concat(["method.request.path.proxy"], var.cache_key_parameters)
  passthrough_behavior    = "WHEN_NO_MATCH"
  integration_http_method = "POST"
  content_handling        = "CONVERT_TO_TEXT"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:${var.function_name}/invocations"
  depends_on              = [aws_api_gateway_method.method]
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "${var.rest_api_id}-${var.resource_id}-${var.http_method}"
  action        = "lambda:InvokeFunction"
  function_name = var.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.rest_api_id}/*/*/*"
}
