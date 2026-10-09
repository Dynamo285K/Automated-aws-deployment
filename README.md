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
- VPC, public and private subnet, Internet Gateway, NAT Gateway with an Elastic IP, and route tables (module [modules/network](terraform/modules/network/))
- Security groups for the bastion and the app server
- An EC2 key pair created from your `~/.ssh/id_ed25519.pub`, plus both instances (module [modules/instances](terraform/modules/instances/), called once for each)
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
- AWS credentials in `~/.aws`, for example from `aws configure`. The `default` profile is used. Besides EC2 and VPC, it needs access to S3 for the state bucket.
- An SSH key at `~/.ssh/id_ed25519`, which you can create with `ssh-keygen -t ed25519`

You don't need to install `terraform`, `ansible`, or the AWS CLI locally. They're all in the container.

> **Cost:** the NAT Gateway isn't covered by the AWS Free Tier and is billed per hour while it exists. Run `terraform destroy` when you're done (see [Tear down](#tear-down)).

## Quick start

```bash
# 1. Build and start the workspace container
docker compose up -d --build

# 2. Open a shell inside it
docker compose exec workspace bash      # or: docker exec -it aws-automation-env bash

# 3. Deploy everything (after the one-time state setup below)
./deploy.sh
```

`deploy.sh` does the following:
1. Makes sure `~/.ssh/config` starts with `Include ~/.ssh/config.d/*`. It adds the line only once and leaves the rest of the file untouched.
2. Runs `terraform init -backend-config=backend.hcl` and `terraform apply`, which creates the infrastructure and generates the inventory and the SSH aliases.
3. Waits 30 seconds for the instances to boot.
4. Runs the Ansible playbook against the app server.

## Terraform state (one-time setup)

Terraform state is stored in an S3 bucket, not on your machine. Anyone with access to the AWS account works with the same state, and a lock file in the bucket stops two `apply` runs from colliding. The bucket has versioning (old state versions are kept for 90 days, the newest 10 always), encryption, and all public access blocked.

The bucket can't be created by the configuration that stores its state in it, so it has its own small configuration in [bootstrap/](bootstrap/). Do this once per AWS account, inside the container:

```bash
# 1. Create the state bucket
cd bootstrap
terraform init
terraform apply
terraform output -raw bucket_name      # automated-aws-deployment-tfstate-<account-id>

# 2. Point the main configuration at it
cd ../terraform
cp backend.hcl.example backend.hcl     # then put the bucket name from step 1 into backend.hcl
terraform init -backend-config=backend.hcl
```

- **`backend.hcl` is gitignored.** The bucket name contains your AWS account ID, which shouldn't end up in a public repo. Only `backend.hcl.example` is committed.
- **The backend settings can't use variables**, because Terraform reads them during `init`, before anything else. That's why the bucket name is passed in with `-backend-config`.
- **`bootstrap/` keeps its own state locally** in `bootstrap/terraform.tfstate`. It only tracks the bucket. If you lose it, the bucket keeps working and can be brought back under Terraform with `terraform import`.

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

The state bucket isn't removed, and the state in it is left empty, ready for the next deploy. The bucket costs a fraction of a cent per month. It has `prevent_destroy` set, so `terraform destroy` in `bootstrap/` refuses to delete it. To remove it for good, delete that `lifecycle` block, delete every object version in the bucket, and then run `terraform destroy` in `bootstrap/`.

## Working with the container

- **The project folder is mounted into the container at `/workspace`.** Code changes are visible right away. The main state lives in S3 and `bootstrap/terraform.tfstate` stays on your host, so stopping or rebuilding the container loses nothing. You only need `--build` after changing the `Dockerfile`.
- **`~/.ssh` is mounted read-write and `~/.aws` read-only.** Terraform needs write access to `~/.ssh` to create the SSH alias file.
- **Use the Terraform version from the container.** The container pins Terraform 1.16.2. If a newer Terraform writes the state in S3, the container will refuse to read it. Both configurations require at least Terraform 1.10, which is the first version with S3 lock files.
- **`exit` doesn't stop the container.** Stop it with `docker compose down`.

## Project structure

```
.
├── Dockerfile             # Ubuntu + Terraform + Ansible + AWS CLI
├── docker-compose.yml     # mounts the project, ~/.ssh and ~/.aws
├── deploy.sh              # SSH config check → terraform apply → ansible-playbook
├── bootstrap/             # one-time: S3 bucket for Terraform state (local state)
│   ├── main.tf
│   └── output.tf
├── terraform/
│   ├── backend.tf         # version constraints + S3 backend (bucket name comes from backend.hcl)
│   ├── backend.hcl.example
│   ├── main.tf            # provider, Ubuntu AMI lookup, key pair
│   ├── networking.tf      # calls modules/network
│   ├── security.tf        # security groups
│   ├── instances.tf       # calls modules/instances for the bastion and the app server
│   ├── output.tf          # outputs + generated inventory and SSH config
│   ├── variables.tf
│   └── modules/
│       ├── network/       # VPC, subnets, gateways, routes
│       └── instances/     # one EC2 instance
└── ansible/
    ├── ansible.cfg
    ├── playbooks/setup.yml
    └── roles/             # base, nginx, app, ssh
```

## Known limitations

- **SSH to the bastion is open to `0.0.0.0/0`.** Restrict it to your own IP for anything beyond a demo.
- **Host key checking is disabled** (`StrictHostKeyChecking no`, `host_key_checking = False`), because the IPs change with every deploy.
- **The AMI is resolved with `most_recent = true`.** When Canonical publishes a new Ubuntu image, `terraform plan` will want to replace both instances.
- **AWS access uses long-lived keys from `aws configure`.** Short-lived credentials from IAM Identity Center (`aws sso login`) would be safer.
