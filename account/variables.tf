variable "tags" {
  type    = map(string)
  default = {}
}

variable "backup_plan" {
  type    = bool
  default = true
}
