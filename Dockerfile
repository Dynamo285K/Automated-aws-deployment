FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    git \
    python3-pip \
    openssh-client && \
    rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir ansible boto3 botocore awscli

RUN curl -fsSL https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip -o terraform.zip && \
    unzip terraform.zip && \
    mv terraform /usr/local/bin/ && \
    rm terraform.zip

WORKDIR /workspace

COPY . /workspace/

RUN chmod 700 deploy.sh