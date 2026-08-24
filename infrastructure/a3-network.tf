# ============================================================
# A3 - Public Application Load Balancer Subnets
#
# These are separate from the original Bastion subnet so that
# the Bastion subnet remains dedicated to administration.
# ============================================================

resource "aws_subnet" "a3_public_alb_az1" {
  vpc_id                  = aws_vpc.medicore.id
  cidr_block              = var.a3_public_alb_az1_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name            = "${var.project_name}-subnet-public-alb-az1"
    Tier            = "Public"
    Purpose         = "Application Load Balancer"
    AssignmentStage = "A3"
  }
}

resource "aws_subnet" "a3_public_alb_az2" {
  vpc_id                  = aws_vpc.medicore.id
  cidr_block              = var.a3_public_alb_az2_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name            = "${var.project_name}-subnet-public-alb-az2"
    Tier            = "Public"
    Purpose         = "Application Load Balancer"
    AssignmentStage = "A3"
  }
}

resource "aws_subnet" "a3_public_alb_az3" {
  vpc_id                  = aws_vpc.medicore.id
  cidr_block              = var.a3_public_alb_az3_cidr
  availability_zone       = data.aws_availability_zones.available.names[2]
  map_public_ip_on_launch = false

  tags = {
    Name            = "${var.project_name}-subnet-public-alb-az3"
    Tier            = "Public"
    Purpose         = "Application Load Balancer"
    AssignmentStage = "A3"
  }
}


# ============================================================
# A3 - Public Route Table Associations
# ============================================================

resource "aws_route_table_association" "a3_public_alb_az1" {
  subnet_id      = aws_subnet.a3_public_alb_az1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "a3_public_alb_az2" {
  subnet_id      = aws_subnet.a3_public_alb_az2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "a3_public_alb_az3" {
  subnet_id      = aws_subnet.a3_public_alb_az3.id
  route_table_id = aws_route_table.public.id
}


# ============================================================
# A3 - Additional Private Web/Application Subnets
#
# The existing aws_subnet.private_web resource already
# provides the Web tier in Availability Zone 2.
# ============================================================

resource "aws_subnet" "a3_private_web_az1" {
  vpc_id                  = aws_vpc.medicore.id
  cidr_block              = var.a3_private_web_az1_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name            = "${var.project_name}-subnet-private-web-az1"
    Tier            = "Private"
    Purpose         = "Auto Scaling Web tier"
    AssignmentStage = "A3"
  }
}

resource "aws_subnet" "a3_private_web_az3" {
  vpc_id                  = aws_vpc.medicore.id
  cidr_block              = var.a3_private_web_az3_cidr
  availability_zone       = data.aws_availability_zones.available.names[2]
  map_public_ip_on_launch = false

  tags = {
    Name            = "${var.project_name}-subnet-private-web-az3"
    Tier            = "Private"
    Purpose         = "Auto Scaling Web tier"
    AssignmentStage = "A3"
  }
}


# ============================================================
# A3 - Private Web Route Table Associations
# ============================================================

resource "aws_route_table_association" "a3_private_web_az1" {
  subnet_id      = aws_subnet.a3_private_web_az1.id
  route_table_id = aws_route_table.private_web.id
}

resource "aws_route_table_association" "a3_private_web_az3" {
  subnet_id      = aws_subnet.a3_private_web_az3.id
  route_table_id = aws_route_table.private_web.id
}