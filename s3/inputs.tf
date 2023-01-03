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

variable "cors" {
  type    = bool
  default = false
}

variable "enabled" {
  type    = bool
  default = true
}
