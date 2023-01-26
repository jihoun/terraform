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
  default     = ["reliability", "s3", "security", "serverless"]
  description = "List of config sample packs to activate"
}
