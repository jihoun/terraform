module "generics" {
  source  = "../generic"
  tags    = var.tags
  enabled = var.enabled
  quotas = {
    client_authentication = {
      quota_code   = "L-74D3DD04"
      service_code = "cognito-idp"
    }
    user_account_recovery = {
      quota_code   = "L-7D6E8ED3"
      service_code = "cognito-idp"
    }
    user_auth = {
      quota_code   = "L-026ADBA3"
      service_code = "cognito-idp"
    }
    user_creation = {
      quota_code   = "L-5987B8A0"
      service_code = "cognito-idp"
    }
    user_federation = {
      quota_code   = "L-BB3E7CCF"
      service_code = "cognito-idp"
    }
    user_list = {
      quota_code   = "L-259E3368"
      service_code = "cognito-idp"
    }
    user_pool_client_read = {
      quota_code   = "L-A412573D"
      service_code = "cognito-idp"
    }
    user_pool_client_update = {
      quota_code   = "L-12C4D74A"
      service_code = "cognito-idp"
    }
    user_pool_read = {
      quota_code   = "L-CFFBE34A"
      service_code = "cognito-idp"
    }
    user_pool_resource_read = {
      quota_code   = "L-A01C9633"
      service_code = "cognito-idp"
    }
    user_pool_resource_update = {
      quota_code   = "L-B7575496"
      service_code = "cognito-idp"
    }
    user_pool_update = {
      quota_code   = "L-60A0B411"
      service_code = "cognito-idp"
    }
    user_read = {
      quota_code   = "L-D6BD5178"
      service_code = "cognito-idp"
    }
    user_resource_read = {
      quota_code   = "L-55545DC8"
      service_code = "cognito-idp"
    }
    user_resource_update = {
      quota_code   = "L-574C86AE"
      service_code = "cognito-idp"
    }
    user_token = {
      quota_code   = "L-F21F8BB4"
      service_code = "cognito-idp"
    }
    user_update = {
      quota_code   = "L-6621E65D"
      service_code = "cognito-idp"
    }
  }
}
