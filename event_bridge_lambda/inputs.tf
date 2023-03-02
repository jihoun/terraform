variable "bus_name" {
  type    = string
  default = "default"
}

variable "event_pattern" {
  type = string
}

variable "lambda_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
