output "key_arn" {
  value = length(aws_kms_key.key) == 1 ? aws_kms_key.key[0].arn : ""
}
