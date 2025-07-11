terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.31.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2.0"
    }
  }
}

locals {
  name = "${var.name}_${terraform.workspace}"
}
resource "aws_lambda_function" "fn" {
  count            = var.enabled ? 1 : 0
  role             = aws_iam_role.role[0].arn
  function_name    = local.name
  handler          = var.handler
  runtime          = var.runtime
  tags             = var.tags
  publish          = true
  timeout          = var.timeout
  source_code_hash = data.archive_file.archive[0].output_base64sha256
  filename         = data.archive_file.archive[0].output_path
  memory_size      = var.memory_size
  description      = "Managed by terraform for ${terraform.workspace} environment."
  layers           = var.layers
  tracing_config {
    #tfsec:ignore:aws-lambda-enable-tracing
    mode = var.trace ? "Active" : "PassThrough"
  }

  environment {
    variables = merge({ NO_COLOR = true }, var.environment_variables)
  }
  dynamic "vpc_config" {
    for_each = (var.subnet_ids != null && var.security_group_ids != null) ? ["tmp"] : []
    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = var.security_group_ids
    }
  }

  depends_on = [aws_iam_role_policy_attachment.base_policy[0]]
}

resource "aws_iam_role" "role" {
  count              = var.enabled ? 1 : 0
  name_prefix        = "${substr(var.name, 0, 37)}_"
  path               = "/lambda/${terraform.workspace}/"
  tags               = var.tags
  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow"
      }
    ]
  }
  EOF
}

data "archive_file" "archive" {
  count       = var.enabled ? 1 : 0
  type        = "zip"
  source_dir  = var.dir
  output_path = "${path.module}/.tmp/${md5(var.dir)}.zip"
}

resource "aws_iam_role_policy_attachment" "base_policy" {
  count      = var.enabled ? 1 : 0
  role       = aws_iam_role.role[0].id
  policy_arn = (var.subnet_ids != null && var.security_group_ids != null) ? "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole" : "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

locals {
  log_group_name = "/aws/lambda/${local.name}"
}

module "log_key" {
  count          = var.enabled ? 1 : 0
  source         = "../log_key"
  log_group_name = local.log_group_name
  tags           = var.tags
}

resource "aws_cloudwatch_log_group" "yada" {
  count             = var.enabled ? 1 : 0
  name              = local.log_group_name
  retention_in_days = var.log_retention
  tags              = var.tags
  kms_key_id        = module.log_key[0].key_arn
}

data "aws_iam_policy_document" "xray" {
  statement {
    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "xray" {
  count       = var.trace && var.enabled ? 1 : 0
  name_prefix = "${var.name}_xtrace"
  path        = "/lambda/${terraform.workspace}/"
  policy      = data.aws_iam_policy_document.xray.json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "xray" {
  count      = var.trace && var.enabled ? 1 : 0
  policy_arn = aws_iam_policy.xray[0].arn
  role       = aws_iam_role.role[0].id
}
