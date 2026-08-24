# ============================================================
# A3 - Application Load Balancer Security Group
# ============================================================

resource "aws_security_group" "a3_alb" {
  name        = "${var.project_name}-sg-a3-alb"
  description = "Public HTTP entry point for the MediCore Application Load Balancer."
  vpc_id      = aws_vpc.medicore.id

  tags = {
    Name            = "${var.project_name}-sg-a3-alb"
    Tier            = "Public"
    AssignmentStage = "A3"
  }
}


# Internet -> ALB HTTP
resource "aws_vpc_security_group_ingress_rule" "a3_alb_http" {
  security_group_id = aws_security_group.a3_alb.id

  description = "Public HTTP application traffic to the Application Load Balancer."

  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80

  cidr_ipv4 = "0.0.0.0/0"
}


# ALB -> scalable Web tier
resource "aws_vpc_security_group_egress_rule" "a3_alb_to_web" {
  security_group_id = aws_security_group.a3_alb.id

  description = "Application traffic from ALB to scalable Web/Application instances."

  ip_protocol = "tcp"
  from_port   = var.a3_backend_port
  to_port     = var.a3_backend_port

  referenced_security_group_id = aws_security_group.a3_web.id
}


# ============================================================
# A3 - Scalable Web/Application Security Group
# ============================================================

resource "aws_security_group" "a3_web" {
  name        = "${var.project_name}-sg-a3-web"
  description = "Least-privilege access for Auto Scaling Web/Application instances."
  vpc_id      = aws_vpc.medicore.id

  tags = {
    Name            = "${var.project_name}-sg-a3-web"
    Tier            = "Private"
    AssignmentStage = "A3"
  }
}


# ALB -> Web backend only
resource "aws_vpc_security_group_ingress_rule" "a3_web_from_alb" {
  security_group_id = aws_security_group.a3_web.id

  description = "Backend application traffic from the Application Load Balancer only."

  ip_protocol = "tcp"
  from_port   = var.a3_backend_port
  to_port     = var.a3_backend_port

  referenced_security_group_id = aws_security_group.a3_alb.id
}


# Bastion -> ASG Web SSH
resource "aws_vpc_security_group_ingress_rule" "a3_web_ssh_bastion" {
  security_group_id = aws_security_group.a3_web.id

  description = "SSH administration from Bastion private IPv4 only."

  ip_protocol = "tcp"
  from_port   = 22
  to_port     = 22

  cidr_ipv4 = "${var.bastion_private_ip}/32"
}


# Bastion -> dynamic Web ASG instances
resource "aws_vpc_security_group_egress_rule" "a3_bastion_ssh_web_asg" {
  security_group_id = aws_security_group.bastion.id

  description = "SSH from Bastion to scalable Web/Application instances."

  ip_protocol = "tcp"
  from_port   = 22
  to_port     = 22

  referenced_security_group_id = aws_security_group.a3_web.id
}


# Scalable Web -> RDS
resource "aws_vpc_security_group_egress_rule" "a3_web_postgresql_rds" {
  security_group_id = aws_security_group.a3_web.id

  description = "PostgreSQL traffic from scalable Web/Application tier to managed RDS."

  ip_protocol = "tcp"
  from_port   = 5432
  to_port     = 5432

  referenced_security_group_id = aws_security_group.rds.id
}


# RDS <- scalable Web
resource "aws_vpc_security_group_ingress_rule" "a3_rds_postgresql_web_asg" {
  security_group_id = aws_security_group.rds.id

  description = "PostgreSQL access from scalable Web/Application instances."

  ip_protocol = "tcp"
  from_port   = 5432
  to_port     = 5432

  referenced_security_group_id = aws_security_group.a3_web.id
}


# Scalable Web -> private S3 path
resource "aws_vpc_security_group_egress_rule" "a3_web_https_s3" {
  security_group_id = aws_security_group.a3_web.id

  description = "HTTPS access from scalable Web tier to Amazon S3."

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443

  prefix_list_id = aws_vpc_endpoint.s3.prefix_list_id
}