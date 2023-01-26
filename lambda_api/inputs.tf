variable "tags" {
  type = map(string)
}

variable "name" {
  type = string
}

variable "function_name" {
  type = string
}

variable "binary_media_types" {
  type    = list(string)
  default = []
}

variable "stage_name" {
  type    = string
  default = "api"
}

variable "cognito" {
  type    = string
  default = null
}

variable "cors" {
  type    = bool
  default = true
}

variable "requires_key" {
  type        = bool
  default     = false
  description = "when true, the API will require an API key to be passed in the request"
}

variable "web_acl_arn" {
  type    = string
  default = null
}

variable "cache_size" {
  type        = number
  default     = null
  description = "If cache_ttl is defined but not this, it will default to 0.5."
}

variable "cache_ttl" {
  type        = number
  default     = null
  description = "If cache_size is defined but not this, it will default to 300."
}

variable "cache_key_parameters" {
  type    = list(string)
  default = []
}

variable "logging_level" {
  type    = string
  default = "ERROR"
  validation {
    condition     = contains(["OFF", "ERROR", "INFO"], self)
    error_message = "Must be one of OFF, ERROR, INFO"
  }
}

variable "metrics" {
  type    = bool
  default = false
}

variable "trace" {
  type    = bool
  default = false
}
