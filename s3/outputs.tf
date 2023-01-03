output "bucket_name" {
  value = var.enabled ? aws_s3_bucket.bucket[0].bucket : null
}

output "bucket_arn" {
  value = var.enabled ? aws_s3_bucket.bucket[0].arn : null
}

output "files_hash" {
  value = var.dir != null ? sha1(jsonencode({
    for fn in fileset("${var.dir}", "**") :
    fn => filesha256("${var.dir}/${fn}")
  })) : ""
}
