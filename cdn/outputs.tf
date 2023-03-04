output "url" {
  value = var.enabled ? (length(var.domain_names) > 0 ? "https://${var.domain_names[0]}" : "https://${aws_cloudfront_distribution.cloudfront[0].domain_name}") : ""
}

output "bucket_name" {
  value = module.bucket.bucket_name
}

output "bucket_arn" {
  value = module.bucket.bucket_arn
}

output "domain_name" {
  value = var.enabled ? "https://${aws_cloudfront_distribution.cloudfront[0].domain_name}" : ""
}
