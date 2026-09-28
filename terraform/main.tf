# Provider block
provider "aws" {
  profile = "default"
  region  = "eu-north-1"
}

resource "aws_key_pair" "my_ssh_key" {
    key_name  = "terraform-aws-key"
    public_key = file("~/.ssh/id_ed25519.pub")    
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh_traffic"
  description = "Allow SSH inbound traffic"
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_instance" "RM" {
  ami                         = "ami-0aba19e56f3eaec05"
  instance_type               = var.instance_type
  associate_public_ip_address = true
  
  key_name = aws_key_pair.my_ssh_key.key_name
  
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  tags = {
      Name                    = var.instance_name
      Role = "app"
  }
}
