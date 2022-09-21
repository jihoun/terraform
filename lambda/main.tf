terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.31.0"
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
  role             = aws_iam_role.role.arn
  function_name    = local.name
  handler          = var.handler
  runtime          = var.runtime
  tags             = var.tags
  publish          = true
  timeout          = var.timeout
  source_code_hash = data.archive_file.archive.output_base64sha256
  filename         = data.archive_file.archive.output_path
  memory_size      = var.memory_size
  environment {
    variables = var.environment_variables
  }
}

resource "aws_iam_role" "role" {
  name_prefix        = "lambda_${var.name}_${terraform.workspace}"
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
  type        = "zip"
  source_dir  = var.dir
  output_path = "${path.module}/.tmp/${md5(var.dir)}.zip"
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

locals {
  log_group_name = "/aws/lambda/${local.name}"
}

module "log_key" {
  source         = "../log_key"
  log_group_name = local.log_group_name
  tags           = var.tags
}

resource "aws_cloudwatch_log_group" "yada" {
  name              = local.log_group_name
  retention_in_days = 365
  tags              = var.tags
  kms_key_id        = module.log_key.key_arn
}
