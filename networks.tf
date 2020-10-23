
# Create us-east-1 VPC
resource "aws_vpc" "vpc_master" {
  provider             = aws.region-master
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name  = "master-vpc-jenkins"
    Owner = "terraform"
  }
}

# Create us-west-2 VPC
resource "aws_vpc" "vpc_master_oregon" {
  provider             = aws.region-worker
  cidr_block           = "192.168.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name  = "worker-vpc-jenkins"
    Owner = "terraform"
  }
}

# Create us-east-1 IGW
resource "aws_internet_gateway" "igw" {
  provider = aws.region-master
  vpc_id   = aws_vpc.vpc_master.id
  tags = {
    Name  = "igw"
    Owner = "terraform"
  }
}

# Create us-west-2 IGW
resource "aws_internet_gateway" "igw_oregon" {
  provider = aws.region-worker
  vpc_id   = aws_vpc.vpc_master_oregon.id
  tags = {
    Name  = "igw_oregon"
    Owner = "terraform"
  }
}

# Get available AZ in master region
data "aws_availability_zones" "azs" {
  provider = aws.region-master
  state    = "available"
}

# Create subnet_1 in us-east-1
resource "aws_subnet" "subnet_1" {
  provider          = aws.region-master
  availability_zone = element(data.aws_availability_zones.azs.names, 0)
  vpc_id            = aws_vpc.vpc_master.id
  cidr_block        = "10.0.1.0/24"
  tags = {
    Name  = "subnet_1"
    Owner = "terraform"
  }
}

# Create subnet_2 in us-east-1
resource "aws_subnet" "subnet_2" {
  provider          = aws.region-master
  availability_zone = element(data.aws_availability_zones.azs.names, 1)
  vpc_id            = aws_vpc.vpc_master.id
  cidr_block        = "10.0.2.0/24"
  tags = {
    Name  = "subnet_2"
    Owner = "terraform"
  }
}

# Crete subnet_1 in us-west-2
resource "aws_subnet" "subnet_1_oregon" {
  provider   = aws.region-worker
  vpc_id     = aws_vpc.vpc_master_oregon.id
  cidr_block = "192.168.1.0/24"
  tags = {
    Name  = "subnet_1_oregon"
    Owner = "terraform"
  }
}

# Create VPC peering connection from us-east-1 to us-west-2
resource "aws_vpc_peering_connection" "useast1-uswest2" {
  provider    = aws.region-master
  peer_vpc_id = aws_vpc.vpc_master_oregon.id
  vpc_id      = aws_vpc.vpc_master.id
  peer_region = var.region-worker
}

# Accept VPC peering request in us-west-2 from us-east-1
resource "aws_vpc_peering_connection_accepter" "accept_peering" {
  provider                  = aws.region-worker
  vpc_peering_connection_id = aws_vpc_peering_connection.useast1-uswest2.id
  auto_accept               = true
}

# Create custom route table for us-east-1 VPC
resource "aws_route_table" "internet_route" {
  provider = aws.region-master
  vpc_id   = aws_vpc.vpc_master.id
  # Default via IGW
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  # us-west-2 via VPC peering
  route {
    cidr_block                = "192.168.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.useast1-uswest2.id
  }
  # Ignore changes except deletions
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name  = "Master-Region-RT"
    Owner = "terraform"
  }
}

# Update default route table of us-east-1 master VPC with "internet_route" table
resource "aws_main_route_table_association" "set-master-default-rt-assoc" {
  provider       = aws.region-master
  vpc_id         = aws_vpc.vpc_master.id
  route_table_id = aws_route_table.internet_route.id
}

# Create custom route table for us-west-2 VPC
resource "aws_route_table" "internet_route_oregon" {
  provider = aws.region-worker
  vpc_id   = aws_vpc.vpc_master_oregon.id
  # Default via IGW
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_oregon.id
  }
  # us-east-1 via VPC peering
  route {
    cidr_block                = "10.0.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.useast1-uswest2.id
  }
  # Ignore changes except deletions
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name  = "Worker-Region-RT"
    Owner = "terraform"
  }
}

# Update default route table of master us-west-2 VPC with "internet_route_oregon" table
resource "aws_main_route_table_association" "set-worker-default-rt-assoc" {
  provider       = aws.region-worker
  vpc_id         = aws_vpc.vpc_master_oregon.id
  route_table_id = aws_route_table.internet_route_oregon.id
}
