variable "bucket_name" {
  type = string
}

variable "bucket_arn" {
  type = string
}

variable "events" {
  type = map(object({
    prefix       = optional(string)
    suffix       = optional(string)
    function_arn = string
    events       = optional(list(string), ["s3:ObjectCreated:*"])
  }))
}

variable "eventbridge" {
  type    = bool
  default = false
}
