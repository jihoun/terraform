output "bucket_name" {
  value = aws_s3_bucket.bucket.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.bucket.arn
}

output "files_hash" {
  value = var.dir != null ? sha1(jsonencode({
    for fn in fileset("${var.dir}", "**") :
    fn => filesha256("${var.dir}/${fn}")
  })) : ""
}
