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
  default = "nodejs18.x"
}

variable "environment_variables" {
  type    = map(string)
  default = {}
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

variable "enabled" {
  type    = bool
  default = true
}

variable "log_retention" {
  type    = number
  default = 60
}

variable "trace" {
  type    = bool
  default = false
}

variable "subnet_ids" {
  type    = list(string)
  default = null
}

variable "security_group_ids" {
  type    = list(string)
  default = null
}

variable "layers" {
  type        = list(string)
  default     = []
  description = "list of arns"
}
