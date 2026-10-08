variable "bastion_instance_type" {
  description = "Type of the bastion EC2 instance, e.g. t3.micro"
  type        = string
  default     = "t3.micro"
}

variable "app_instance_type" {
  description = "Type of the app EC2 instance, e.g. t3.micro"
  type        = string
  default     = "t3.micro"
}