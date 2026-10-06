FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    git \
    python3-pip \
    openssh-client && \
    rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir ansible boto3 botocore awscli

# Must not be older than the Terraform that last wrote terraform.tfstate, otherwise it refuses to read it
ARG TERRAFORM_VERSION=1.9.8

# dpkg reports amd64/arm64, matching HashiCorp's release naming (works on Intel and Apple Silicon)
RUN ARCH="$(dpkg --print-architecture)" && \
    curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip" -o terraform.zip && \
    unzip terraform.zip terraform && \
    mv terraform /usr/local/bin/ && \
    rm terraform.zip

# The project is bind-mounted here by docker-compose.yml, so terraform.tfstate and
# generated files persist on the host instead of dying with the container
WORKDIR /workspace