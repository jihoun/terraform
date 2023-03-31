variable "environment_variables" {
  type    = map(string)
  default = {}
}

variable "port" {
  type    = number
  default = 80
}

variable "name" {
  type = string
}

variable "image_url" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "app_subnet_ids" {
  type = list(string)
}

variable "app_security_group_ids" {
  type = list(string)
}

variable "lb_subnet_ids" {
  type = list(string)
}

variable "lb_security_group_ids" {
  type = list(string)
}

variable "domain_name" {
  type    = string
  default = null
}

variable "zone_id" {
  type    = string
  default = null
}

variable "certificate_arn" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
