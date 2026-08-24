# ============================================================
# MediCore VPC
# ============================================================

resource "aws_vpc" "medicore" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}


# ============================================================
# Public Bastion Subnet
# ============================================================

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


# ============================================================
# Private Web / Application Subnet
# ============================================================

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


# ============================================================
# Restricted Database Subnet
# ============================================================

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


# ============================================================
# Internet Gateway
# ============================================================

resource "aws_internet_gateway" "medicore" {
  vpc_id = aws_vpc.medicore.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}


# ============================================================
# Public Route Table
# ============================================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.medicore.id

  tags = {
    Name = "${var.project_name}-rt-public"
    Tier = "Public"
  }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.medicore.id
}

resource "aws_route_table_association" "public_bastion" {
  subnet_id      = aws_subnet.public_bastion.id
  route_table_id = aws_route_table.public.id
}


# ============================================================
# Private Web Route Table
# ============================================================

resource "aws_route_table" "private_web" {
  vpc_id = aws_vpc.medicore.id

  tags = {
    Name = "${var.project_name}-rt-private-web"
    Tier = "Private"
  }
}

resource "aws_route_table_association" "private_web" {
  subnet_id      = aws_subnet.private_web.id
  route_table_id = aws_route_table.private_web.id
}


# ============================================================
# Restricted Database Route Table
# ============================================================

resource "aws_route_table" "restricted_database" {
  vpc_id = aws_vpc.medicore.id

  tags = {
    Name = "${var.project_name}-rt-restricted-database"
    Tier = "Restricted"
  }
}

resource "aws_route_table_association" "restricted_database" {
  subnet_id      = aws_subnet.restricted_database.id
  route_table_id = aws_route_table.restricted_database.id
}