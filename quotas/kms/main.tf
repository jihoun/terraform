module "generics" {
  source  = "../generic"
  tags    = var.tags
  enabled = var.enabled
  sns     = var.sns
  quotas = {
    cancel_key_deletion = {
      quota_code   = "L-635264CC"
      service_code = "kms"
    }
    connect_custom_key_store = {
      quota_code   = "L-705B9E79"
      service_code = "kms"
    }
    create_alias = {
      quota_code   = "L-F7504F73"
      service_code = "kms"
    }
    CreateCustomKeyStore = {
      quota_code   = "L-08932E37"
      service_code = "kms"
    }
    CreateGrant = {
      quota_code   = "L-0428A42E"
      service_code = "kms"
    }
    CreateKey = {
      quota_code   = "L-32B67F4A"
      service_code = "kms"
    }
    Cryptographic_operations_ecc = {
      quota_code   = "L-DC14942D"
      service_code = "kms"
    }
    Cryptographic_operations_rsa = {
      quota_code   = "L-2AC98190"
      service_code = "kms"
    }
    Cryptographic_operations_symmetric = {
      quota_code   = "L-6E3AF000"
      service_code = "kms"
    }
    delete_alias = {
      quota_code   = "L-1F75ADD1"
      service_code = "kms"
    }
    delete_custom_key_store = {
      quota_code   = "L-E99520CB"
      service_code = "kms"
    }
    DeleteImportedKeyMaterial = {
      quota_code   = "L-1233BF9B"
      service_code = "kms"
    }
    DescribeCustomKeyStores = {
      quota_code   = "L-E20AA94C"
      service_code = "kms"
    }
    DescribeKey = {
      quota_code   = "L-FAE8F084"
      service_code = "kms"
    }
    DisableKey = {
      quota_code   = "L-6B8C93BD"
      service_code = "kms"
    }
    DisableKeyRotation = {
      quota_code   = "L-CE1DB614"
      service_code = "kms"
    }
    DisconnectCustomKeyStore = {
      quota_code   = "L-9F1FCF6D"
      service_code = "kms"
    }
    EnableKey = {
      quota_code   = "L-BD96F100"
      service_code = "kms"
    }
    EnableKeyRotation = {
      quota_code   = "L-BE799B67"
      service_code = "kms"
    }
    GenerateDataKeyPair_ECC_NIST_P256 = {
      quota_code   = "L-D2EEB5E0"
      service_code = "kms"
    }
    GenerateDataKeyPair_ECC_NIST_P384 = {
      quota_code   = "L-16B46EF0"
      service_code = "kms"
    }
    GenerateDataKeyPair_ECC_NIST_P521 = {
      quota_code   = "L-1D966DA0"
      service_code = "kms"
    }
  }
}
