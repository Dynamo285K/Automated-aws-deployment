resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "bastion-vpc"
  }
}     

resource "aws_subnet" "public" {
    vpc_id                  = aws_vpc.main.id
    cidr_block              = "10.0.1.0/24"
    map_public_ip_on_launch = true

    tags = {
        Name = "bastion-public-subnet"
    }
}

resource "aws_subnet" "private" {
    vpc_id                  = aws_vpc.main.id
    cidr_block              = "10.0.2.0/24"
    map_public_ip_on_launch = false

    tags = {
        Name = "bastion-private-subnet"
    }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main.id
}

resource "aws_eip" "nat_eip" {
    domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
    allocation_id = aws_eip.nat_eip.id
    subnet_id     = aws_subnet.public.id
    depends_on    = [aws_internet_gateway.igw]

    tags = {
        Name = "bastion-nat-gateway"
    }
}

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
}

resource "aws_route_table_association" "public" {
    subnet_id      = aws_subnet.public.id
    route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block     = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat.id
    }
}

resource "aws_route_table_association" "private" {
    subnet_id      = aws_subnet.private.id
    route_table_id = aws_route_table.private.id
}
