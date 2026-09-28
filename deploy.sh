#!/usr/bin/env bash

set -euo pipefail


echo "0. Checking and setting up SSH config"

mkdir -p ~/.ssh
chmod 700 ~/.ssh

if ! grep -q "^Include ~/.ssh/config.d/\*" ~/.ssh/config 2>/dev/null; then
	echo "Adding Include to the beginning of the ~/.ssh/config"

	if [ -f ~/.ssh/config ]; then
		echo "Include ~/.ssh/config.d/*" | cat - ~/.ssh/config > ~/.ssh/config.tmp 
		mv ~/.ssh/config.tmp ~/.ssh/config
	else
		echo "Include ~/.ssh/config.d/*" > ~/.ssh/config
	fi
fi

chmod 600 ~/.ssh/config

echo "1. Preparing environment and building infrastructue with Terraform"

cd terraform
terraform init
terraform apply -auto-approve
cd ..

echo "2. Waiting 30 seconds until the system and SSH initialize"
sleep 30

echo "3. Starting Ansible configuration"
cd ansible 
ansible-playbook -i ../ansible/inventory.ini playbooks/setup.yml
cd ..

echo "Done"
