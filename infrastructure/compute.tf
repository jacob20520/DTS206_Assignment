# ============================================================
# Bastion Host
# ============================================================

resource "aws_instance" "bastion" {
  ami           = data.aws_ami.ubuntu_2204.id
  instance_type = var.bastion_instance_type

  subnet_id = aws_subnet.public_bastion.id

  private_ip = var.bastion_private_ip

  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.bastion.id
  ]

  key_name = aws_key_pair.medicore.key_name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  user_data = <<-EOF
    #!/bin/bash

    hostnamectl set-hostname medicore-bastion

    cat > /etc/motd.d/medicore <<'MOTD'
    MediCore Health Systems
    Bastion Administration Host
    DTS206 Secure Clinical Cloud Infrastructure
    MOTD
  EOF

  tags = {
    Name = "${var.project_name}-bastion"
    Role = "Bastion"
    Tier = "Public"
  }
}


# ============================================================
# Web / Application VM
# ============================================================

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu_2204.id
  instance_type = var.web_instance_type

  subnet_id = aws_subnet.private_web.id

  private_ip = var.web_private_ip

  associate_public_ip_address = false

  vpc_security_group_ids = [
    aws_security_group.web.id
  ]

  key_name = aws_key_pair.medicore.key_name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  user_data = <<-EOF
    #!/bin/bash

    hostnamectl set-hostname medicore-web

    cat > /etc/motd.d/medicore <<'MOTD'
    MediCore Health Systems
    Web / Application Tier
    Private Subnet
    DTS206 Secure Clinical Cloud Infrastructure
    MOTD
  EOF

  tags = {
    Name = "${var.project_name}-web"
    Role = "Web-Application"
    Tier = "Private"
  }
}


# ============================================================
# Dedicated Database VM
# ============================================================

resource "aws_instance" "database" {
  ami           = data.aws_ami.ubuntu_2204.id
  instance_type = var.database_instance_type

  subnet_id = aws_subnet.restricted_database.id

  private_ip = var.database_private_ip

  associate_public_ip_address = false

  vpc_security_group_ids = [
    aws_security_group.database.id
  ]

  key_name = aws_key_pair.medicore.key_name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  user_data = <<-EOF
    #!/bin/bash

    hostnamectl set-hostname medicore-database

    cat > /etc/motd.d/medicore <<'MOTD'
    MediCore Health Systems
    Dedicated Database Tier
    Restricted Subnet
    DTS206 Secure Clinical Cloud Infrastructure
    MOTD
  EOF

  tags = {
    Name = "${var.project_name}-database"
    Role = "Database"
    Tier = "Restricted"
  }
}