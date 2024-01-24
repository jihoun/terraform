variable "tags" {
  type    = map(string)
  default = {}
}

variable "log_group_name" {
  type = string
}

variable "enabled" {
  type    = bool
  default = true
}
