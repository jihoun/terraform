variable "name" {
  type        = string
  default     = "ssm-jump"
  description = "Prefix for resource names (e.g. project or service name)"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID for the jump instance (e.g. private app subnet)"
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security group IDs for the jump instance (must allow outbound to SSM and to DB if used for port forwarding)"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all resources"
}

variable "instance_type" {
  type        = string
  default     = "t3.nano"
  description = "EC2 instance type for the jump host"
}
