variable "cloudwatch" {
  type    = bool
  default = false
}

variable "cognito" {
  type    = bool
  default = false
}

variable "dynamodb" {
  type    = bool
  default = false
}

variable "kms" {
  type    = bool
  default = false
}

variable "lambda" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
