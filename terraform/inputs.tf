variable "log_bucket" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
