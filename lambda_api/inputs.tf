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

variable "cache" {
  type    = bool
  default = false
}

variable "cache_key_parameters" {
  type    = list(string)
  default = []
}
