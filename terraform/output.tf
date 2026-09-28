output "instance_id" {
    value = aws_instance.RM.id
}

output "instance_public_ip" {
    description = "Public IP adress of the instance"
    value = aws_instance.RM.public_ip
}