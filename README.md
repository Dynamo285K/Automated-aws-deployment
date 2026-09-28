# Automated aws deployment with Terraform and Ansible

Fully automated provisioning and deployment pipeline for a static HTML website. This project uses Terraform to provision AWS infrastructure and Ansible with a dynamic inventory to configure the server and deploy the application.

## Features

**Infrastructure & Automation**
* **Infrastructure as Code (Terraform):** Automatically provisions an AWS EC2 instance, Security Groups (Firewall), and configures SSH key pairs.
* **One-Click Deployment Script:** A robust Bash script (`set -euo pipefail`) that handles the entire lifecycle: building infrastructure, waiting for initialization, running configuration, and cleaning up.
* **Dynamic AWS Inventory:** Ansible automatically discovers the newly created EC2 instances based on Terraform tags (e.g., `Role = "app"`) using the `aws_ec2` plugin.
* **Automated SSH Configuration:** The deployment script safely generates a dynamic SSH config file (`~/.ssh/config.d/aws_server`) and integrates it via the `Include` directive, allowing seamless connection without managing IPs manually.

**Configuration Management (Ansible Roles)**
* **System Prep (`base` role):** Updates system packages and installs essential security utilities (like Fail2ban).
* **Web Server (`nginx` role):** Installs, configures, and manages the Nginx web server state.
* **Deployment (`app` role):** Cleans the default web directory and automatically clones the latest static website code directly from GitHub.

## Prerequisites

Before running the project, ensure you have the following installed on your local machine (or Docker container):

* **Terraform** (v1.0+)
* **Ansible** (v2.9+)
* **AWS CLI** configured with your credentials (`aws configure`)
* **Python AWS Libraries:** Required for Ansible's dynamic inventory.
  ```bash
  pip3 install boto3 botocore