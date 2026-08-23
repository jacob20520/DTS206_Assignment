output "vpc_id" {
  description = "ID of the MediCore VPC."
  value       = aws_vpc.medicore.id
}

output "public_bastion_subnet" {
  description = "Public subnet used by the Bastion host."
  value = {
    id   = aws_subnet.public_bastion.id
    cidr = aws_subnet.public_bastion.cidr_block
    az   = aws_subnet.public_bastion.availability_zone
  }
}

output "private_web_subnet" {
  description = "Private subnet used by the web/application tier."
  value = {
    id   = aws_subnet.private_web.id
    cidr = aws_subnet.private_web.cidr_block
    az   = aws_subnet.private_web.availability_zone
  }
}

output "restricted_database_subnet" {
  description = "Restricted subnet used by the database tier."
  value = {
    id   = aws_subnet.restricted_database.id
    cidr = aws_subnet.restricted_database.cidr_block
    az   = aws_subnet.restricted_database.availability_zone
  }
}