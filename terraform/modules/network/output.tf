output "vpc_id" {
  description = "Returns id of a virtual private cloud"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "Returns the cidr block of a vpc"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_id" {
  description = "Returns id of a public subnet"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "Returns id of a private subnet"
  value       = aws_subnet.private.id
}