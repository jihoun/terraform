variable "stream_arn" {
  type = string
}

variable "function_name" {
  type = string
}

variable "function_role_name" {
  type = string
}

variable "tags" {
  type = map(string)
  default = {}
}

variable "reports_errors" {
  type    = bool
  default = true
}

variable "enabled" {
  type    = bool
  default = true
}
