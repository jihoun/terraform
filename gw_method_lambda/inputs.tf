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

variable "cache_key_parameters" {
  type    = list(string)
  default = []
}

variable "enabled" {
  type    = bool
  default = true
}

variable "authorization_scopes" {
  type        = list(string)
  default     = []
  description = "List of OAuth scopes required for the method. When non-empty, API Gateway expects an access token and validates these scopes (Cognito). When empty, expects an identity token."
}
