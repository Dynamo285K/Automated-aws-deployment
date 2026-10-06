output "bastion_public_ip" {
  description = "Public IP address of the bastion instance"
  value       = aws_instance.bastion.public_ip
}

output "app_private_ip" {
  description = "Private IP address of the app instance"
  value       = aws_instance.app.private_ip
}

resource "local_file" "ansible_inventory" {
  content  = <<-EOT
    [bastion_group]
    bastion ansible_host=${aws_instance.bastion.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_ed25519

    [app_servers]
    app ansible_host=${aws_instance.app.private_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_ed25519 ansible_ssh_common_args='-o ProxyJump=ubuntu@${aws_instance.bastion.public_ip}:22'
  EOT
  filename = "${path.module}/../ansible/inventory.ini"
}

# Writes only its own fragment; deploy.sh adds "Include ~/.ssh/config.d/*" to ~/.ssh/config.
# Never point this at ~/.ssh/config itself - apply would overwrite it and destroy would delete it.
resource "local_file" "ssh_config" {
  content              = <<-EOT
    # Managed by Terraform (Automated-aws-deployment) - changes will be overwritten
    Host aws-bastion
        HostName ${aws_instance.bastion.public_ip}
        User ubuntu
        IdentityFile ~/.ssh/id_ed25519
        StrictHostKeyChecking no

    Host aws-app
        HostName ${aws_instance.app.private_ip}
        User ubuntu
        IdentityFile ~/.ssh/id_ed25519
        ProxyJump aws-bastion
        StrictHostKeyChecking no
  EOT
  filename             = pathexpand("~/.ssh/config.d/aws-deployment")
  file_permission      = "0600"
  directory_permission = "0700"
}