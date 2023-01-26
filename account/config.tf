resource "aws_config_configuration_recorder" "config" {
  name     = "default"
  role_arn = aws_iam_service_linked_role.config.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "s3" {
  s3_bucket_name = module.log_bucket.bucket_name
  s3_key_prefix  = "config"
  depends_on = [
    aws_config_configuration_recorder.config
  ]
}

resource "aws_config_configuration_recorder_status" "enabled" {
  name       = aws_config_configuration_recorder.config.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.s3]
}

locals {
  sample_packs = {
    s3          = "${path.module}/config-sample-packs/Operational-Best-Practices-for-Amazon-S3.yaml",
    reliability = "${path.module}/config-sample-packs/Operational-Best-Practices-for-AWS-Well-Architected-Reliability-Pillar.yaml"
    security    = "${path.module}/config-sample-packs/Operational-Best-Practices-for-AWS-Well-Architected-Security-Pillar.yaml"
    serverless  = "${path.module}/config-sample-packs/Operational-Best-Practices-for-Serverless.yaml"
  }
}
resource "aws_config_conformance_pack" "Operational-Best-Practices-for-Serverless" {
  for_each      = toset(var.config_packs)
  name          = each.key
  template_body = file(local.sample_packs[each.key])
  depends_on    = [aws_config_configuration_recorder.config]
}
