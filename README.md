# Secure AWS Infrastructure Automation (Bastion + Private App Server)

Terraform builds an isolated AWS network with a bastion host and a private web server, and Ansible then configures the server and deploys a static website to it. A single script does both, and everything runs inside a Docker container, so the only tools you need locally are Docker and an AWS account.

## Architecture

```
                 Internet
                    │
            ┌───────┴────────┐
            │ Internet GW    │
┌───────────┴────────────────┴──────────── VPC 10.0.0.0/16 ─┐
│  Public subnet 10.0.1.0/24                                │
│   ┌──────────────┐     ┌─────────────┐                    │
│   │ Bastion host │     │ NAT Gateway │                    │
│   └──────┬───────┘     └──────▲──────┘                    │
│          │ SSH (ProxyJump)    │ outbound only             │
│  Private subnet 10.0.2.0/24   │                           │
│   ┌──────▼────────────────────┴─┐                         │
│   │ App server (Nginx + site)   │                         │
│   └─────────────────────────────┘                         │
└───────────────────────────────────────────────────────────┘
```

- **Bastion host:** the only machine with a public IP. SSH (port 22) is the only port open to the internet.
- **App server:** has a private IP only. It accepts SSH only from the bastion's security group and HTTP only from inside the VPC.
- **NAT Gateway:** lets the app server download packages and the website, while the internet still can't reach it.

Region: `eu-north-1` (Stockholm). Both instances are `t3.micro` running Ubuntu 22.04.

## What gets deployed

**Terraform** ([terraform/](terraform/))
- VPC, public and private subnet, Internet Gateway, NAT Gateway with an Elastic IP, and route tables
- Security groups for the bastion and the app server
- An EC2 key pair created from your `~/.ssh/id_ed25519.pub`, plus both instances
- Two generated local files:
  - `ansible/inventory.ini`: the server IPs Ansible connects to
  - `~/.ssh/config.d/aws-deployment`: SSH aliases (`aws-bastion`, `aws-app`) for you

**Ansible** ([ansible/playbooks/setup.yml](ansible/playbooks/setup.yml)), applied to the app server through the bastion:

| Role    | What it does                                                                   | Tags              |
|---------|--------------------------------------------------------------------------------|-------------------|
| `base`  | `apt` upgrade, basic utilities, and `fail2ban`                                 | `base`, `setup`   |
| `nginx` | Installs and enables Nginx                                                     | `nginx`, `web`    |
| `app`   | Clones [gh-deployment-workflow](https://github.com/Dynamo285K/gh-deployment-workflow) into `/var/www/html` | `app`, `web` |
| `ssh`   | Adds an extra authorized public key for the `ubuntu` user                      | `ssh`, `security` |

## Prerequisites

- Docker with Docker Compose
- AWS credentials in `~/.aws`, for example from `aws configure`. The `default` profile is used.
- An SSH key at `~/.ssh/id_ed25519`, which you can create with `ssh-keygen -t ed25519`

You don't need to install `terraform`, `ansible`, or the AWS CLI locally. They're all in the container.

> **Cost:** the NAT Gateway isn't covered by the AWS Free Tier and is billed per hour while it exists. Run `terraform destroy` when you're done (see [Tear down](#tear-down)).

## Quick start

```bash
# 1. Build and start the workspace container
docker compose up -d --build

# 2. Open a shell inside it
docker compose exec workspace bash      # or: docker exec -it aws-automation-env bash

# 3. Deploy everything
./deploy.sh
```

`deploy.sh` does the following:
1. Makes sure `~/.ssh/config` starts with `Include ~/.ssh/config.d/*`. It adds the line only once and leaves the rest of the file untouched.
2. Runs `terraform init` and `terraform apply`, which creates the infrastructure and generates the inventory and the SSH aliases.
3. Waits 30 seconds for the instances to boot.
4. Runs the Ansible playbook against the app server.

## Connecting to the servers

After a deploy, these commands work from your host machine (and from the container):

```bash
ssh aws-bastion
ssh aws-app          # jumps through the bastion automatically
```

The app server isn't reachable from the internet. To view the website, forward a local port through SSH and open <http://localhost:8080>:

```bash
ssh -L 8080:localhost:80 aws-app
```

To re-run only part of the configuration, run the playbook from the `ansible/` folder with a tag:

```bash
cd ansible
ansible-playbook -i inventory.ini playbooks/setup.yml --tags web
```

## Tear down

```bash
cd terraform
terraform destroy
```

This removes all AWS resources, `ansible/inventory.ini`, and `~/.ssh/config.d/aws-deployment`. Your own `~/.ssh/config` is left as it is.

## Working with the container

- **The project folder is mounted into the container at `/workspace`.** Code changes are visible right away, and `terraform.tfstate` stays on your host, so stopping or rebuilding the container loses nothing. You only need `--build` after changing the `Dockerfile`.
- **`~/.ssh` is mounted read-write and `~/.aws` read-only.** Terraform needs write access to `~/.ssh` to create the SSH alias file.
- **Run Terraform only inside the container.** The container pins Terraform 1.9.8. A newer Terraform on your host would upgrade the state file, and the container would then refuse to read it.
- **`exit` doesn't stop the container.** Stop it with `docker compose down`.

## Project structure

```
.
├── Dockerfile             # Ubuntu + Terraform + Ansible + AWS CLI
├── docker-compose.yml     # mounts the project, ~/.ssh and ~/.aws
├── deploy.sh              # SSH config check → terraform apply → ansible-playbook
├── terraform/
│   ├── main.tf            # provider, Ubuntu AMI lookup, key pair
│   ├── networking.tf      # VPC, subnets, gateways, routes
│   ├── security.tf        # security groups
│   ├── istances.tf        # bastion and app EC2 instances
│   ├── output.tf          # outputs + generated inventory and SSH config
│   └── variables.tf
└── ansible/
    ├── ansible.cfg
    ├── playbooks/setup.yml
    └── roles/             # base, nginx, app, ssh
```

## Known limitations

- **SSH to the bastion is open to `0.0.0.0/0`.** Restrict it to your own IP for anything beyond a demo.
- **Host key checking is disabled** (`StrictHostKeyChecking no`, `host_key_checking = False`), because the IPs change with every deploy.
- **The AMI is resolved with `most_recent = true`.** When Canonical publishes a new Ubuntu image, `terraform plan` will want to replace both instances.
- **Terraform state is stored locally.** A remote backend such as S3 would be needed if more people work on the project.
