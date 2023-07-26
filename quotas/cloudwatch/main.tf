module "generics" {
  source  = "../generic"
  tags    = var.tags
  enabled = var.enabled
  sns     = var.sns
  quotas = {
    kms_key_throttle = {
      quota_code   = "L-7A4B5D2F"
      service_code = "logs"
    }
    cancel_export_task = {
      service_code = "logs"
      quota_code   = "L-97393AE2"
    }
    create_export_task = {
      service_code = "logs"
      quota_code   = "L-BD9DB0EB"
    }
    create_log_group = {
      service_code = "logs"
      quota_code   = "L-D2832119"
    }
    create_log_stream = {
      service_code = "logs"
      quota_code   = "L-76507CEF"
    }
    delete_destination = {
      service_code = "logs"
      quota_code   = "L-BE2A59B1"
    }
    delete_log_group = {
      service_code = "logs"
      quota_code   = "L-07A912D5"
    }
    delete_log_stream = {
      service_code = "logs"
      quota_code   = "L-C029A21C"
    }
    delete_metric_filter = {
      service_code = "logs"
      quota_code   = "L-363FC8B0"
    }
    delete_retention_policy = {
      service_code = "logs"
      quota_code   = "L-66F5762A"
    }
    delete_subscription_filter = {
      service_code = "logs"
      quota_code   = "L-56B91A0A"
    }
    describe_destinations = {
      service_code = "logs"
      quota_code   = "L-BEB90E24"
    }
    describe_export_tasks = {
      service_code = "logs"
      quota_code   = "L-ACAEE94E"
    }
    describe_log_groups = {
      service_code = "logs"
      quota_code   = "L-4284EEDE"
    }
    describe_log_streams = {
      service_code = "logs"
      quota_code   = "L-3F243AD0"
    }
    describe_metric_filters = {
      service_code = "logs"
      quota_code   = "L-69BF6BAC"
    }
    describe_subscription_filters = {
      service_code = "logs"
      quota_code   = "L-9D43025B"
    }
    filter_log_events = {
      service_code = "logs"
      quota_code   = "L-55E3CA17"
    }
    get_log_events = {
      service_code = "logs"
      quota_code   = "L-4FE15505"
    }
    list_tags_for_resources = {
      service_code = "logs"
      quota_code   = "L-E6EF8674"
    }
    list_tags_log_group = {
      service_code = "logs"
      quota_code   = "L-3E4C85B1"
    }
    put_destination = {
      service_code = "logs"
      quota_code   = "L-7A9B3427"
    }
    put_destination_policy = {
      service_code = "logs"
      quota_code   = "L-7EB1C513"
    }
    put_log_events = {
      service_code = "logs"
      quota_code   = "L-7E1FAE88"
    }
    put_metric_filter = {
      service_code = "logs"
      quota_code   = "L-E5FB5933"
    }
    put_retention_filter = {
      service_code = "logs"
      quota_code   = "L-0397E41F"
    }
    put_subscription_filter = {
      service_code = "logs"
      quota_code   = "L-A5D79081"
    }
    tag_log_group = {
      service_code = "logs"
      quota_code   = "L-BBECF742"
    }
    tag_resource = {
      service_code = "logs"
      quota_code   = "L-956BB71D"
    }
    tag_metric_filter = {
      service_code = "logs"
      quota_code   = "L-1CD226BD"
    }
    untag_log_group = {
      service_code = "logs"
      quota_code   = "L-EEEC3365"
    }
    untag_resource = {
      service_code = "logs"
      quota_code   = "L-B501C43C"
    }
  }
}
