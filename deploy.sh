#!/usr/bin/env bash

set -euo pipefail


echo "0. Checking and setting up SSH config"

mkdir -p ~/.ssh/config.d
chmod 700 ~/.ssh ~/.ssh/config.d
touch ~/.ssh/config
chmod 600 ~/.ssh/config

if ! grep -q "^Include ~/.ssh/config.d/\*" ~/.ssh/config; then
	echo "Adding Include to the beginning of the ~/.ssh/config"

	# Include must be at the top, before any Host/Match block, to apply globally.
	# Rewrite in place (cat >) instead of mv, so a symlinked config keeps its link and permissions.
	{ echo "Include ~/.ssh/config.d/*"; cat ~/.ssh/config; } > ~/.ssh/config.tmp
	cat ~/.ssh/config.tmp > ~/.ssh/config
	rm ~/.ssh/config.tmp
fi

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
