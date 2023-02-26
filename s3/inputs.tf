variable "name" {
  type = string
  validation {
    # regex(...) fails if it cannot find a match
    condition     = can(regex("^[a-zA-Z\\d-]+$", var.name))
    error_message = "The name should only contain alpha numerics and hypens"
  }

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
