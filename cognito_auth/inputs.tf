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

variable "invite_email_subject" {
  description = "Optional custom invitation email subject. Must be set together with invite_email_message. Used as the known toggle for the invite template block so the message can be a computed token."
  type        = string
  default     = null
}

variable "invite_email_message" {
  description = "Optional custom invitation email HTML. Must include {username} and {####}. Must be set together with invite_email_subject."
  type        = string
  default     = null

  validation {
    condition     = var.invite_email_message == null || (strcontains(var.invite_email_message, "{username}") && strcontains(var.invite_email_message, "{####}"))
    error_message = "invite_email_message must contain {username} and {####}."
  }
}

variable "verification_email_subject" {
  description = "Optional custom verification/forgot-password email subject. Must be set together with verification_email_message. Used as the known toggle for the verification template block so the message can be a computed token."
  type        = string
  default     = null
}

variable "verification_email_message" {
  description = "Optional custom verification/forgot-password email HTML. Must include {####}. Must be set together with verification_email_subject."
  type        = string
  default     = null

  validation {
    condition     = var.verification_email_message == null || strcontains(var.verification_email_message, "{####}")
    error_message = "verification_email_message must contain {####}."
  }
}
