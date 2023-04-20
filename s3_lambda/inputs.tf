variable "function_arn" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "bucket_arn" {
  type = string
}

variable "events" {
  type    = list(string)
  default = ["s3:ObjectCreated:*"]
}

variable "prefix" {
  type    = string
  default = null
}

variable "suffix" {
  type    = string
  default = null
}

variable "eventbridge" {
  type    = bool
  default = false
}
