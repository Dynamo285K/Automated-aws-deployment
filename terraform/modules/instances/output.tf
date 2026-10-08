output "public_ip" {
  description = "Returns public IP of an instance"
  value       = aws_instance.ec2.public_ip
}

output "private_ip" {
  description = "Returns private IP of an instance"
  value       = aws_instance.ec2.private_ip
}



