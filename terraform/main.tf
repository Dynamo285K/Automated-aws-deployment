# Provider block
provider "aws" {
  profile = "default"
  region  = "eu-north-1"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

resource "aws_key_pair" "my_ssh_key" {
    key_name  = "terraform-aws-key"
    public_key = file("~/.ssh/id_ed25519.pub")    
}
