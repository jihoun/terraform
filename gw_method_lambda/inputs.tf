variable "rest_api_id" {
  type = string
}

variable "resource_id" {
  type = string
}

variable "http_method" {
  type    = string
  default = "ANY"
}

variable "function_name" {
  type = string
}

variable "authorization" {
  type    = string
  default = "NONE"
}

variable "authorizer_id" {
  type    = string
  default = null
}

variable "api_key_required" {
  type    = bool
  default = false
}
