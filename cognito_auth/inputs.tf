variable "tags" {
  type    = map(string)
  default = {}
}

variable "name" {
  type    = string
  default = "cognito_auth"
}

variable "enabled" {
  type    = bool
  default = true
}
