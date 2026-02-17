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
