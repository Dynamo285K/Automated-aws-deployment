output "bastion_public_ip" {
    description = "Public IP address of the bastion instance"
    value = aws_instance.bastion.public_ip
}

output "app_private_ip" {
    description = "Private IP address of the app instance"
    value = aws_instance.app.private_ip
}

resource "local_file" "ansible_inventory" {
  content = <<-EOT
    [bastion_group]
    bastion ansible_host=${aws_instance.bastion.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_ed25519

    [app_servers]
    app ansible_host=${aws_instance.app.private_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_ed25519 ansible_ssh_common_args='-o ProxyJump=ubuntu@${aws_instance.bastion.public_ip}:22'
  EOT
  filename = "${path.module}/../ansible/inventory.ini"
}

resource "local_file" "ssh_config" {
  content = <<-EOT
    Host bastion
        HostName ${aws_instance.bastion.public_ip}
        User ubuntu
        IdentityFile ~/.ssh/id_ed25519
        StrictHostKeyChecking no

    Host app
        HostName ${aws_instance.app.private_ip}
        User ubuntu
        IdentityFile ~/.ssh/id_ed25519
        ProxyJump bastion
        StrictHostKeyChecking no
  EOT
  filename = pathexpand("~/.ssh/config")
}