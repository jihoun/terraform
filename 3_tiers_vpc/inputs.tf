variable "name" {
  type = string
}

variable "app_port" {
  type = number
}

variable "db_port" {
  type = number
}

variable "tags" {
  type    = map(string)
  default = {}
}
