variable "name" {
  description = "Value of the Name tag on the VPC, shown in the AWS console."
  type        = string
  default     = "bastion"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC, e.g. 10.0.0.0/16. Subnet CIDRs must fall inside it."
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet, e.g. 10.0.1.0/24. Must be inside vpc_cidr and not overlap private_subnet_cidr."
  type        = string
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet, e.g. 10.0.2.0/24. Must be inside vpc_cidr and not overlap public_subnet_cidr."
  type        = string
}

variable "availability_zone" {
  description = "AZ for both subnets, e.g. eu-north-1a. Must belong to the provider's region."
  type        = string
}
