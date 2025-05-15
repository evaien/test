variable "target_account_id" {
  type = string
}

variable "terraform_role_name" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "azs" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "public_subnets" {
  type = list(string)
}

variable "cluster_name" {
  type = string
}

variable "cluster_version" {
  type    = string
  default = "1.29"
}

variable "cluster_addons" {
  type    = any
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "node_group_config" {
  type = any
}