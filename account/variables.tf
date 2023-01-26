variable "tags" {
  type    = map(string)
  default = {}
}

variable "backup_plan" {
  type    = bool
  default = true
}

variable "config_packs" {
  type        = list(string)
  default     = null
  description = "List of config sample packs to activate"
}

locals {
  config_packs = var.config_packs == null ? ["reliability", "s3", "security", "serverless"] : var.config_packs
}
