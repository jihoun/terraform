variable "quotas" {
  type = map(object({
    service_code = string
    quota_code   = string
  }))
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "enabled" {
  type = bool
}
