# AWS Infrastructure & Web Deployment Automation

Fully automated provisioning and deployment pipeline for a static HTML website. This project uses Terraform to provision AWS infrastructure, Ansible with a dynamic inventory to configure the server, and Docker to ensure a 100% reproducible execution environment.

## Features

**Infrastructure & Automation**
* **Isolated Environment (Docker):** Zero local tool installation required. Terraform, Ansible, and AWS CLI are fully containerized.
* **Infrastructure as Code (Terraform):** Automatically provisions an AWS EC2 instance, Security Groups, and SSH key pairs.
* **One-Click Deployment Script:** A robust Bash script (`set -euo pipefail`) that handles the entire lifecycle: building infrastructure, waiting for initialization, running configuration, and cleaning up.
* **Dynamic AWS Inventory:** Ansible automatically discovers newly created EC2 instances based on Terraform tags (e.g., `Role = "app"`).

**Configuration Management (Ansible Roles)**
* **System Prep (`base` role):** Updates system packages and installs essential security utilities (like Fail2ban).
* **Web Server (`nginx` role):** Installs, configures, and manages the Nginx web server state.
* **Deployment (`app` role):** Cleans the default web directory and automatically clones the latest static website code directly from GitHub.

## Prerequisites

* **Docker** and **Docker Compose** installed.
* **AWS Credentials:** Configured on your host machine (usually located in `~/.aws/`).
* **SSH Key Pair:** A local SSH private key (e.g., `~/.ssh/id_ed25519`).

*Note: Your credentials and keys are safely mounted into the container as read-only (`:ro`) and are never baked into the Docker image.*

## Project Structure

```text
.
├── Dockerfile              # Enterprise toolset image definition
├── docker-compose.yml      # Container runtime config & volume mounts
├── .dockerignore           # Prevents bloated image builds
├── deploy.sh               # Main automation script
├── terraform/              # Infrastructure definitions
└── ansible/                # Configuration management