resource "aws_vpc" "medicore" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_subnet" "public_bastion" {
  vpc_id                  = aws_vpc.medicore.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-subnet-public-bastion"
    Tier = "Public"
  }
}

resource "aws_subnet" "private_web" {
  vpc_id                  = aws_vpc.medicore.id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-subnet-private-web"
    Tier = "Private"
  }
}

resource "aws_subnet" "restricted_database" {
  vpc_id                  = aws_vpc.medicore.id
  cidr_block              = var.restricted_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[2]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-subnet-restricted-database"
    Tier = "Restricted"
  }
}

resource "aws_internet_gateway" "medicore" {
  vpc_id = aws_vpc.medicore.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}