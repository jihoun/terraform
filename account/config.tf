resource "aws_config_configuration_recorder" "config" {
  name     = "default"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "s3" {
  s3_bucket_name = module.log_bucket.bucket_name
  s3_key_prefix  = "config"
}

resource "aws_config_configuration_recorder_status" "enabled" {
  name       = aws_config_configuration_recorder.config.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.s3]
}

resource "aws_config_conformance_pack" "Operational-Best-Practices-for-Serverless" {
  for_each      = fileset("${path.module}/config-sample-packs", "*.yaml")
  name          = trimsuffix(each.key, ".yaml")
  template_body = file("${path.module}/config-sample-packs/${each.value}")
}
