variable "name" {
  type = string
}

variable "dir" {
  type = string
}

variable "handler" {
  type    = string
  default = "main.handler"
}

variable "runtime" {
  type    = string
  default = "nodejs16.x"
}

variable "environment_variables" {
  type    = map(string)
  default = { foo = "bar" }
}

variable "tags" {
  type    = map(string)
  default = null
}

variable "memory_size" {
  type    = number
  default = 128
}

variable "timeout" {
  default     = 3
  type        = number
  description = "Max duration in seconds per execution"
}
