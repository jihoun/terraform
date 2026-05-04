variable "name_prefix" {
  type        = string
  description = "Prefix for resource names and Name tags (e.g. robert-production)."
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  type        = string
  description = "VPC IPv4 CIDR; used for NAT instance security group ingress."
}

variable "app_subnet_ids" {
  type        = list(string)
  description = "Private app subnet IDs: execute-api endpoint is placed here; default routes target the NAT ENI."
}

variable "app_security_group_ids" {
  type        = list(string)
  description = "Security groups allowed to reach the execute-api VPC endpoint on 443."
}

variable "nat_public_subnet_id" {
  type        = string
  description = "Public subnet ID where the NAT instance runs."
}

variable "nat_instance_type" {
  type        = string
  default     = "t3.nano"
  description = "EC2 instance type for the NAT instance."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Common tags merged into all resources."
}
