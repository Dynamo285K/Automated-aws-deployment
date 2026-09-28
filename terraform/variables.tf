variable "instance_name" {
    description = "Name of the EC2 instance"
    type        = string
    default = "AWS-server" 
}

variable "instance_type" {
    description = "Type of the EC2 instance"
    type        = string
    default     = "t3.micro" 
}