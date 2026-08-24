# ============================================================
# Availability Zones
# ============================================================

data "aws_availability_zones" "available" {
  state = "available"
}


# ============================================================
# Ubuntu 22.04 LTS
# ============================================================

data "aws_ami" "ubuntu_2204" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name = "name"

    values = [
      "ubuntu/images/hvm-ssd-gp3/ubuntu-jammy-22.04-amd64-server-*",
      "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
    ]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}