
data "aws_servicequotas_service_quota" "quotas" {
  for_each     = var.quotas
  service_code = each.value.service_code
  quota_code   = each.value.quota_code
}

resource "aws_cloudwatch_metric_alarm" "quota" {
  for_each            = var.enabled ? var.quotas : {}
  alarm_name          = "${data.aws_servicequotas_service_quota.quotas[each.key].service_name} ${data.aws_servicequotas_service_quota.quotas[each.key].quota_name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 80
  datapoints_to_alarm = 1
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.sns != null ? [var.sns] : []

  metric_query {
    id          = "m1"
    period      = 0
    return_data = false

    dynamic "metric" {
      for_each = data.aws_servicequotas_service_quota.quotas[each.key].usage_metric

      content {
        dimensions = {
          class    = metric.value.metric_dimensions[0].class
          resource = metric.value.metric_dimensions[0].resource
          service  = metric.value.metric_dimensions[0].service
          type     = metric.value.metric_dimensions[0].type
        }
        metric_name = metric.value.metric_name
        namespace   = metric.value.metric_namespace
        period      = 300
        stat        = metric.value.metric_statistic_recommendation
      }
    }
  }

  metric_query {
    expression  = "m1/${data.aws_servicequotas_service_quota.quotas[each.key].value}*100"
    id          = "e2"
    label       = "% of quota"
    period      = 0
    return_data = true
  }
}
