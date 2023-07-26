variable "tags" {
  type    = map(string)
  default = {}
}

variable "enabled" {
  type = bool
}

variable "sns" {
  type    = string
  default = null
}
