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
  type = string
}

variable "name" {
  type = string
}
