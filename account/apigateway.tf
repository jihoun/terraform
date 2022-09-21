resource "aws_iam_role" "api_gateway" {
  name               = "apigw-cloudwatch-${terraform.workspace}"
  description        = "Allows api gateway to push Cloudwatch logs. Managed by terraform."
  tags               = var.tags
  assume_role_policy = <<-JSON
  {
    "Statement": [
      {
        "Action"   : "sts:AssumeRole",
        "Effect"   : "Allow",
        "Principal": {
          "Service": "apigateway.amazonaws.com"
        }
      }
    ],
    "Version": "2012-10-17"
  }
  JSON
}

resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch" {
  role       = aws_iam_role.api_gateway.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_account" "current" {
  cloudwatch_role_arn = aws_iam_role.api_gateway.arn
}
