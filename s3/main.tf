terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.31.0"
    }
  }
}
# data "aws_region" "current" {}
# data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "bucket" {
  bucket_prefix = "${var.name}-${terraform.workspace}"
  tags          = var.tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_logging" "logging" {
  count = var.log_bucket != null ? 1 : 0

  bucket = aws_s3_bucket.bucket.id

  target_bucket = var.log_bucket
  target_prefix = "s3/${aws_s3_bucket.bucket.id}/"
}

resource "aws_s3_bucket_acl" "acl" {
  bucket = aws_s3_bucket.bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "files" {
  for_each     = var.dir != null ? fileset(var.dir, "**") : toset([])
  bucket       = aws_s3_bucket.bucket.id
  key          = each.key
  source       = "${var.dir}/${each.key}"
  content_type = length(regexall("\\.[^.]+$", each.key)) > 0 ? lookup(local.mime_types, regex("\\.[^.]+$", each.key), null) : null
  etag         = filemd5("${var.dir}/${each.key}")
}
