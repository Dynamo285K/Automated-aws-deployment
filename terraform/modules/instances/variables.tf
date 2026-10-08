variable "ami_id" {
  description = "AMI ID to launch the instance from, e.g. data.aws_ami.ubuntu.id from the root."
  type        = string
}

variable "instance_type" {
  description = "Sets the type of the instance, e.g. t3.micro, t3.large."
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of an existing EC2 key pair used for SSH access."
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet to launch the instance in; determines whether it is public or private."
  type        = string
}

variable "security_groups" {
  description = "IDs of security groups attached to the instance."
  type        = list(string)
}

variable "public_ip_bool" {
  description = "Determines if instance should have public ip assigned"
  type        = bool
}

variable "name" {
  description = "Value of the Name tag, shown in the AWS console, e.g. Bastion-Host."
  type        = string
}

variable "role" {
  description = "Value of the Role tag describing the instance's purpose, e.g. bastion or app."
  type        = string
}

