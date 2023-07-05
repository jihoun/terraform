module "generics" {
  source  = "../generic"
  tags    = var.tags
  enabled = var.enabled
  quotas = {
    concurrent = {
      quota_code   = "L-B99A9384"
      service_code = "lambda"
    }
  }
}
