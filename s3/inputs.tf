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

variable "with_acl" {
  type    = bool
  default = true
}

variable "cors_methods" {
  type    = list(string)
  default = ["GET"]
}

variable "region" {
  type        = string
  default     = null
  description = "Region to create the S3 bucket in. If not provided, will use the default region."
}

variable "sse_algorithm" {
  type        = string
  default     = "AES256"
  description = "Default bucket encryption algorithm (AES256 or aws:kms)."

  validation {
    condition     = contains(["AES256", "aws:kms"], var.sse_algorithm)
    error_message = "sse_algorithm must be AES256 or aws:kms."
  }
}

variable "kms_master_key_id" {
  type        = string
  default     = null
  description = "Optional CMK for SSE-KMS. Null uses the AWS managed aws/s3 key."
}

variable "bucket_key_enabled" {
  type        = bool
  default     = null
  description = "Enable S3 Bucket Key. Defaults to true when sse_algorithm is aws:kms, otherwise false."
}
