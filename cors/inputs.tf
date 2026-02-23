variable "rest_api_id" {
  type = string
}

variable "resource_id" {
  type = string
}

variable "enabled" {
  type    = bool
  default = true
}

variable "allow_headers" {
  type = list(string)
  default = []
}