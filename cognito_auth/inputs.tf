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
