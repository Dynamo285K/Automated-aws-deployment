resource "aws_instance" "bastion" {
    ami                         = data.aws_ami.ubuntu.id
    instance_type               = var.instance_type
    key_name                    = aws_key_pair.my_ssh_key.key_name
    subnet_id                   = aws_subnet.public.id
    vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
    associate_public_ip_address = true

    tags = {
        Name = "Bastion-Host"
        Role = "bastion"
    }
}

resource "aws_instance" "app" {
    ami                         = data.aws_ami.ubuntu.id
    instance_type               = var.instance_type
    key_name                    = aws_key_pair.my_ssh_key.key_name
    subnet_id                   = aws_subnet.private.id
    vpc_security_group_ids      = [aws_security_group.app_sg.id]
    associate_public_ip_address = false

    tags = {
        Name = "App-Private-Server"
        Role = "app"
    }
}
