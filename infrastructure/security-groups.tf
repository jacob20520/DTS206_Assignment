# ============================================================
# Bastion Security Group
# ============================================================

resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-sg-bastion"
  description = "Least-privilege access for the MediCore Bastion host."
  vpc_id      = aws_vpc.medicore.id

  tags = {
    Name = "${var.project_name}-sg-bastion"
    Tier = "Public"
  }
}

resource "aws_vpc_security_group_ingress_rule" "bastion_ssh_admin" {
  security_group_id = aws_security_group.bastion.id
  description       = "SSH from authorised administrator public IPv4 only."

  ip_protocol = "tcp"
  from_port   = 22
  to_port     = 22

  cidr_ipv4 = var.admin_cidr
}

resource "aws_vpc_security_group_egress_rule" "bastion_ssh_web" {
  security_group_id = aws_security_group.bastion.id
  description       = "SSH from Bastion to Web/Application VM."

  ip_protocol = "tcp"
  from_port   = 22
  to_port     = 22

  cidr_ipv4 = "${var.web_private_ip}/32"
}

resource "aws_vpc_security_group_egress_rule" "bastion_ssh_database" {
  security_group_id = aws_security_group.bastion.id
  description       = "SSH from Bastion to restricted Database VM."

  ip_protocol = "tcp"
  from_port   = 22
  to_port     = 22

  cidr_ipv4 = "${var.database_private_ip}/32"
}


# ============================================================
# Web / Application Security Group
# ============================================================

resource "aws_security_group" "web" {
  name        = "${var.project_name}-sg-web"
  description = "Least-privilege access for the MediCore Web/Application tier."
  vpc_id      = aws_vpc.medicore.id

  tags = {
    Name = "${var.project_name}-sg-web"
    Tier = "Private"
  }
}

resource "aws_vpc_security_group_ingress_rule" "web_ssh_bastion" {
  security_group_id = aws_security_group.web.id
  description       = "SSH from Bastion private IPv4 only."

  ip_protocol = "tcp"
  from_port   = 22
  to_port     = 22

  cidr_ipv4 = "${var.bastion_private_ip}/32"
}

resource "aws_vpc_security_group_ingress_rule" "web_http" {
  security_group_id = aws_security_group.web.id
  description       = "HTTP application traffic."

  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80

  cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "web_https" {
  security_group_id = aws_security_group.web.id
  description       = "HTTPS application traffic."

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443

  cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "web_postgresql_database" {
  security_group_id = aws_security_group.web.id
  description       = "PostgreSQL traffic from Web/Application tier to Database VM."

  ip_protocol = "tcp"
  from_port   = 5432
  to_port     = 5432

  cidr_ipv4 = "${var.database_private_ip}/32"
}

resource "aws_vpc_security_group_egress_rule" "web_https_s3" {
  security_group_id = aws_security_group.web.id
  description       = "HTTPS access from Web/Application tier to Amazon S3."

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443

  prefix_list_id = aws_vpc_endpoint.s3.prefix_list_id
}


# ============================================================
# Dedicated Database VM Security Group
# ============================================================

resource "aws_security_group" "database" {
  name        = "${var.project_name}-sg-database"
  description = "Least-privilege access for the MediCore restricted Database VM."
  vpc_id      = aws_vpc.medicore.id

  tags = {
    Name = "${var.project_name}-sg-database"
    Tier = "Restricted"
  }
}

resource "aws_vpc_security_group_ingress_rule" "database_ssh_bastion" {
  security_group_id = aws_security_group.database.id
  description       = "SSH administration from Bastion private IPv4 only."

  ip_protocol = "tcp"
  from_port   = 22
  to_port     = 22

  cidr_ipv4 = "${var.bastion_private_ip}/32"
}

resource "aws_vpc_security_group_ingress_rule" "database_postgresql_web" {
  security_group_id = aws_security_group.database.id
  description       = "PostgreSQL from Web/Application private IPv4 only."

  ip_protocol = "tcp"
  from_port   = 5432
  to_port     = 5432

  cidr_ipv4 = "${var.web_private_ip}/32"
}

resource "aws_vpc_security_group_egress_rule" "database_https_s3" {
  security_group_id = aws_security_group.database.id
  description       = "HTTPS access from Database tier to Amazon S3 for backups."

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443

  prefix_list_id = aws_vpc_endpoint.s3.prefix_list_id
}


# ============================================================
# Managed RDS PostgreSQL Security Group
# ============================================================

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-sg-rds"
  description = "Least-privilege PostgreSQL access to the MediCore managed RDS database."
  vpc_id      = aws_vpc.medicore.id

  tags = {
    Name = "${var.project_name}-sg-rds"
    Tier = "Restricted"
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_postgresql_web" {
  security_group_id = aws_security_group.rds.id
  description       = "PostgreSQL access from the Web/Application VM private IPv4 only."

  ip_protocol = "tcp"
  from_port   = 5432
  to_port     = 5432

  cidr_ipv4 = "${var.web_private_ip}/32"
}

resource "aws_vpc_security_group_egress_rule" "web_postgresql_rds" {
  security_group_id = aws_security_group.web.id
  description       = "PostgreSQL traffic from Web/Application tier to managed RDS."

  ip_protocol = "tcp"
  from_port   = 5432
  to_port     = 5432

  referenced_security_group_id = aws_security_group.rds.id
}