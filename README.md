# Secure AWS Infrastructure Automation (Bastion + Private App Server)

A fully automated and secure AWS architecture running within the AWS Free Tier (t3.micro), built using Terraform and Ansible.

## Architecture
The project creates an isolated environment (VPC `10.0.0.0/16`) divided into two parts:
1. **Public Subnet:** Contains the Internet Gateway (IGW), NAT Gateway, and Bastion Host (public IP address, entry point).
2. **Private Subnet:** Contains the App Server (private IP address `10.0.x.x`, without direct internet access).
3. **Connectivity:** Secure access to the private server is provided via SSH ProxyJump through the Bastion Host.

---

## Technologies Used
* **Terraform:** Infrastructure provisioning, dynamic generation of the Ansible inventory, and local SSH configuration.
* **Ansible:** Configuration management and application deployment (Roles: base, nginx, app, ssh).
* **AWS:** VPC, Subnets, Internet/NAT Gateways, Security Groups, EC2 (`t3.micro`).

---

## How to Run the Project

### Prerequisites
* Installed `docker` and `docker-compose`.
* Configured AWS credentials (e.g., via `aws configure`, so they're available under `~/.aws`).
* A local SSH key created (`~/.ssh/id_ed25519`).

> `terraform`, `ansible`, and `ssh` do not need to be installed locally — they run inside the Docker workspace container.

### Deployment

The project runs inside a Docker container that provides all required tools (`terraform`, `ansible`, `ssh`) pre-installed. It mounts your local SSH key (`~/.ssh`) and AWS credentials (`~/.aws`) into the container.

1. **Build and start the workspace container** (in detached mode):
```bash
   docker compose up -d --build
```

2. **Attach to the running container:**
```bash
   docker compose exec workspace bash
```

3. **Inside the container**, run the automated deployment script (terraform apply + configuration generation + ansible playbook):
```bash
   ./deploy.sh