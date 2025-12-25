terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.31.0"
    }
  }
}

#tfsec:ignore:aws-s3-enable-bucket-logging
resource "aws_s3_bucket" "bucket" {
  count         = var.enabled ? 1 : 0
  bucket_prefix = "${var.name}-${terraform.workspace}"
  tags          = var.tags
  region        = var.region
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  count  = var.enabled ? 1 : 0
  bucket = aws_s3_bucket.bucket[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_logging" "logging" {
  count         = var.enabled && var.log_bucket != null ? 1 : 0
  bucket        = aws_s3_bucket.bucket[0].id
  target_bucket = var.log_bucket
  target_prefix = "s3/${aws_s3_bucket.bucket[0].id}/"
}

resource "aws_s3_bucket_acl" "acl" {
  count  = var.enabled && var.with_acl ? 1 : 0
  bucket = aws_s3_bucket.bucket[0].id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  count  = var.enabled ? 1 : 0
  bucket = aws_s3_bucket.bucket[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_versioning" "versioning_example" {
  count  = var.enabled ? 1 : 0
  bucket = aws_s3_bucket.bucket[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "files" {
  for_each     = var.dir != null && var.enabled ? fileset(var.dir, "**") : toset([])
  bucket       = aws_s3_bucket.bucket[0].id
  key          = each.key
  source       = "${var.dir}/${each.key}"
  content_type = length(regexall("\\.[^.]+$", each.key)) > 0 ? lookup(local.mime_types, regex("\\.[^.]+$", each.key), null) : null
  source_hash  = filemd5("${var.dir}/${each.key}")
}

resource "aws_s3_bucket_cors_configuration" "bucket" {
  count  = var.cors && var.enabled ? 1 : 0
  bucket = aws_s3_bucket.bucket[0].id

  cors_rule {
    allowed_methods = var.cors_methods
    allowed_origins = ["*"]
    allowed_headers = ["*"]
  }
}
