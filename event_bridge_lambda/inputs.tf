variable "bus_name" {
  type    = string
  default = "default"
}

variable "event_pattern" {
  type = string
}

variable "lambda" {
  type = object({
    name = string
    arn  = string
  })
}

variable "tags" {
  type    = map(string)
  default = {}
}
