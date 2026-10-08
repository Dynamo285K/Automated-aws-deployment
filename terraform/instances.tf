module "bastion" {
  source          = "./modules/instances"
  ami_id          = data.aws_ami.ubuntu.id
  instance_type   = var.bastion_instance_type
  key_name        = aws_key_pair.my_ssh_key.key_name
  subnet_id       = module.network.public_subnet_id
  security_groups = [aws_security_group.bastion_sg.id]
  public_ip_bool  = true
  name            = "Bastion-host-server"
  role            = "bastion"
}

module "app" {
  source          = "./modules/instances"
  ami_id          = data.aws_ami.ubuntu.id
  instance_type   = var.app_instance_type
  key_name        = aws_key_pair.my_ssh_key.key_name
  subnet_id       = module.network.private_subnet_id
  security_groups = [aws_security_group.app_sg.id]
  public_ip_bool  = false
  name            = "App-Private-Server"
  role            = "app"
}