module "generics" {
  source  = "../generic"
  tags    = var.tags
  enabled = var.enabled
  quotas = {
    table_count = {
      service_code = "dynamodb"
      quota_code   = "L-F98FE922"
    }
    write_throughput = {
      service_code = "dynamodb"
      quota_code   = "L-34F8CCC8"
    }
    read_throughput = {
      service_code = "dynamodb"
      quota_code   = "L-34F6A552"
    }
  }
}
