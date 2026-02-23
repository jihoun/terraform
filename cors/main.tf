resource "aws_api_gateway_method" "options" {
  count         = var.enabled ? 1 : 0
  rest_api_id   = var.rest_api_id
  resource_id   = var.resource_id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options" {
  count       = var.enabled ? 1 : 0
  rest_api_id = var.rest_api_id
  resource_id = var.resource_id
  http_method = "OPTIONS"
  type        = "MOCK"
  content_handling  = "CONVERT_TO_TEXT"
  request_templates = {
    "application/json" = jsonencode({ statusCode = 200 })
  }
  depends_on = [aws_api_gateway_method.options]

}
resource "aws_api_gateway_method_response" "response_200" {
  count       = var.enabled ? 1 : 0
  rest_api_id = var.rest_api_id
  resource_id = var.resource_id
  http_method = "OPTIONS"
  status_code = 200
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = false
    "method.response.header.Access-Control-Allow-Methods" = false
    "method.response.header.Access-Control-Allow-Origin"  = false
  }

  depends_on = [aws_api_gateway_integration.options]
}
resource "aws_api_gateway_integration_response" "response_200" {
  count       = var.enabled ? 1 : 0
  rest_api_id = var.rest_api_id
  resource_id = var.resource_id
  http_method = "OPTIONS"  
  content_handling  = "CONVERT_TO_TEXT"
  status_code = 200
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token${join(",", var.allow_headers!=null ? var.allow_headers : [])}'"
    "method.response.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
  depends_on = [aws_api_gateway_method_response.response_200]
}
