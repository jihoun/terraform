variable "name" {
  type = string
}

variable "dir" {
  type        = string
  default     = null
  description = "Local path to folder that needs to be synced with S3 bucket"
}

variable "log_bucket" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "domain_names" {
  type        = list(string)
  default     = []
  description = "If left empty, will default to cloudfront domain name. Should come with certificate_arn."
}

variable "certificate_arn" {
  type        = string
  default     = null
  description = "If left empty, will default to cloudfront default certificate. Should come with domain_names."
}

variable "hosted_zone_id" {
  type        = string
  default     = null
  description = "Required when domain_names is specified and it should obviously match the domain name."
}
