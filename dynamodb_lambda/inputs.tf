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
}

variable "reports_errors" {
  type    = bool
  default = true
}
