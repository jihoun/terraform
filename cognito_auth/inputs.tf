variable "tags" {
  type    = map(string)
  default = {}
}

variable "name" {
  type = string
}

variable "enabled" {
  type    = bool
  default = true
}

variable "schema" {
  description = "Optional list of custom schema attributes to add to the user pool. Each attribute will be prefixed with 'custom:' by Cognito."
  type = list(object({
    name                = string
    attribute_data_type = string # "String" | "Number" | "DateTime" | "Boolean"
    mutable             = optional(bool, true)
    required            = optional(bool, false)
    min_length          = optional(number)
    max_length          = optional(number)
  }))
  default = []
}

variable "invite_email" {
  description = "Optional custom invitation email. Message must include {username} and {####}."
  type = object({
    subject = string
    message = string
  })
  default = null

  validation {
    condition     = var.invite_email == null || (strcontains(var.invite_email.message, "{username}") && strcontains(var.invite_email.message, "{####}"))
    error_message = "invite_email.message must contain {username} and {####}."
  }
}

variable "verification_email" {
  description = "Optional custom verification/forgot-password email. Message must include {####}."
  type = object({
    subject = string
    message = string
  })
  default = null

  validation {
    condition     = var.verification_email == null || strcontains(var.verification_email.message, "{####}")
    error_message = "verification_email.message must contain {####}."
  }
}

variable "email_configuration" {
  description = "Optional SES From address. When null, Cognito uses its default sender."
  type = object({
    from_email_address = string
    source_arn         = string
  })
  default = null
}

variable "refresh_token_validity" {
  type        = number
  default     = 7
  description = "Refresh token lifetime. Unit is token_validity_units.refresh_token. Cognito allows 60 minutes to 10 years."
}

variable "access_token_validity" {
  type        = number
  default     = 1
  description = "Access token lifetime. Unit is token_validity_units.access_token. Cognito allows 5 minutes to 24 hours."
}

variable "id_token_validity" {
  type        = number
  default     = 1
  description = "ID token lifetime. Unit is token_validity_units.id_token. Cognito allows 5 minutes to 24 hours."
}

variable "token_validity_units" {
  description = "Units for refresh, access, and ID token validity. Each value is seconds, minutes, hours, or days."
  type = object({
    refresh_token = string
    access_token  = string
    id_token      = string
  })
  default = {
    refresh_token = "days"
    access_token  = "hours"
    id_token      = "hours"
  }

  validation {
    condition = alltrue([
      contains(["seconds", "minutes", "hours", "days"], var.token_validity_units.refresh_token),
      contains(["seconds", "minutes", "hours", "days"], var.token_validity_units.access_token),
      contains(["seconds", "minutes", "hours", "days"], var.token_validity_units.id_token),
    ])
    error_message = "token_validity_units values must be seconds, minutes, hours, or days."
  }
}

variable "mfa_configuration" {
  description = "User pool MFA setting. OFF disables MFA, OPTIONAL lets users enroll, ON requires software-token MFA at sign-in."
  type        = string
  default     = "OPTIONAL"

  validation {
    condition     = contains(["OFF", "ON", "OPTIONAL"], var.mfa_configuration)
    error_message = "mfa_configuration must be OFF, ON, or OPTIONAL."
  }
}

variable "user_pool_tier" {
  description = "Cognito feature plan (LITE, ESSENTIALS, PLUS). Null keeps the AWS default (Essentials)."
  type        = string
  default     = null

  validation {
    condition     = var.user_pool_tier == null || contains(["LITE", "ESSENTIALS", "PLUS"], var.user_pool_tier)
    error_message = "user_pool_tier must be LITE, ESSENTIALS, or PLUS."
  }
}

variable "user_pool_add_ons" {
  description = "Threat protection settings. Null keeps prior behavior (no add-ons block). Threat protection requires user_pool_tier = PLUS."
  type = object({
    advanced_security_mode = string
    custom_auth_mode       = optional(string)
  })
  default = null

  validation {
    condition = var.user_pool_add_ons == null || contains(
      ["OFF", "AUDIT", "ENFORCED"],
      var.user_pool_add_ons.advanced_security_mode,
    )
    error_message = "user_pool_add_ons.advanced_security_mode must be OFF, AUDIT, or ENFORCED."
  }

  validation {
    condition = var.user_pool_add_ons == null || try(var.user_pool_add_ons.custom_auth_mode, null) == null || contains(
      ["AUDIT", "ENFORCED"],
      var.user_pool_add_ons.custom_auth_mode,
    )
    error_message = "user_pool_add_ons.custom_auth_mode must be AUDIT or ENFORCED."
  }
}
