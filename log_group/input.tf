variable "log_group_name" {
  type = string
}

variable "enabled" {
  type    = bool
  default = true
}

variable "log_retention" {
  type    = number
  default = 60
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "encrypted" {
  type    = bool
  default = true
}
