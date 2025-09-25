variable "queue_arn" {
  type = string
}

variable "function_arn" {
  type = string
}

variable "reports_errors" {
  type    = bool
  default = false
}

variable "function_role" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "enabled" {
  type    = bool
  default = true
}

variable "batch_size" {
  type    = number
  default = 10
}
