variable "lambda_arn" {
  type = string
}

variable "lambda_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "cron" {
  type    = string
  default = null
}

variable "rate" {
  type    = string
  default = null
}

variable "name" {
  type = string
}

variable "enabled" {
  type    = bool
  default = true
}
