output "url" {
  value = length(var.domain_names) > 0 ? "https://${var.domain_names[0]}" : "https://${aws_cloudfront_distribution.cloudfront.domain_name}"
}

output "bucket_name" {
  value = module.bucket.bucket_name
}

output "bucket_arn" {
  value = module.bucket.bucket_arn
}
