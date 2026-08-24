# ============================================================
# VPC
# ============================================================

output "vpc_id" {
  description = "ID of the MediCore VPC."
  value       = aws_vpc.medicore.id
}


# ============================================================
# Initial Three-Tier Subnets
# ============================================================

output "public_bastion_subnet" {
  description = "Public subnet used by the Bastion host."

  value = {
    id   = aws_subnet.public_bastion.id
    cidr = aws_subnet.public_bastion.cidr_block
    az   = aws_subnet.public_bastion.availability_zone
  }
}

output "private_web_subnet" {
  description = "Private subnet used by the Web/Application tier."

  value = {
    id   = aws_subnet.private_web.id
    cidr = aws_subnet.private_web.cidr_block
    az   = aws_subnet.private_web.availability_zone
  }
}

output "restricted_database_subnet" {
  description = "Primary restricted subnet used by the Database tier."

  value = {
    id   = aws_subnet.restricted_database.id
    cidr = aws_subnet.restricted_database.cidr_block
    az   = aws_subnet.restricted_database.availability_zone
  }
}


# ============================================================
# Secondary Restricted RDS Subnet
# ============================================================

output "restricted_rds_secondary_subnet" {
  description = "Secondary restricted subnet used by the RDS DB subnet group."

  value = {
    id   = aws_subnet.restricted_rds_secondary.id
    cidr = aws_subnet.restricted_rds_secondary.cidr_block
    az   = aws_subnet.restricted_rds_secondary.availability_zone
  }
}


# ============================================================
# Ubuntu AMI
# ============================================================

output "ubuntu_2204_ami_id" {
  description = "Canonical Ubuntu 22.04 LTS AMI selected for the deployment."
  value       = data.aws_ami.ubuntu_2204.id
}


# ============================================================
# Bastion
# ============================================================

output "bastion_instance_id" {
  description = "EC2 instance ID of the MediCore Bastion host."
  value       = aws_instance.bastion.id
}

output "bastion_public_ip" {
  description = "Public IPv4 address of the MediCore Bastion host."
  value       = aws_instance.bastion.public_ip
}

output "bastion_private_ip" {
  description = "Private IPv4 address of the MediCore Bastion host."
  value       = aws_instance.bastion.private_ip
}


# ============================================================
# Web / Application VM
# ============================================================

output "web_instance_id" {
  description = "EC2 instance ID of the MediCore Web/Application VM."
  value       = aws_instance.web.id
}

output "web_private_ip" {
  description = "Private IPv4 address of the MediCore Web/Application VM."
  value       = aws_instance.web.private_ip
}

output "web_availability_zone" {
  description = "Availability Zone hosting the Web/Application VM."
  value       = aws_instance.web.availability_zone
}


# ============================================================
# Dedicated Database VM
# ============================================================

output "database_instance_id" {
  description = "EC2 instance ID of the MediCore Database VM."
  value       = aws_instance.database.id
}

output "database_private_ip" {
  description = "Private IPv4 address of the MediCore Database VM."
  value       = aws_instance.database.private_ip
}

output "database_availability_zone" {
  description = "Availability Zone hosting the Database VM."
  value       = aws_instance.database.availability_zone
}


# ============================================================
# Security Groups
# ============================================================

output "bastion_security_group_id" {
  description = "Security group attached to the MediCore Bastion."
  value       = aws_security_group.bastion.id
}

output "web_security_group_id" {
  description = "Security group attached to the Web/Application tier."
  value       = aws_security_group.web.id
}

output "database_security_group_id" {
  description = "Security group attached to the dedicated Database VM."
  value       = aws_security_group.database.id
}

output "rds_security_group_id" {
  description = "Security group protecting the managed RDS database."
  value       = aws_security_group.rds.id
}


# ============================================================
# S3 Private Storage
# ============================================================

output "s3_bucket_name" {
  description = "Name of the private MediCore S3 storage bucket."
  value       = aws_s3_bucket.medicore_storage.id
}

output "s3_bucket_arn" {
  description = "ARN of the private MediCore S3 storage bucket."
  value       = aws_s3_bucket.medicore_storage.arn
}

output "s3_vpc_endpoint_id" {
  description = "ID of the S3 Gateway VPC Endpoint."
  value       = aws_vpc_endpoint.s3.id
}

output "s3_prefix_list_id" {
  description = "AWS-managed S3 prefix list used by security group egress rules."
  value       = aws_vpc_endpoint.s3.prefix_list_id
}


# ============================================================
# Managed RDS PostgreSQL
# ============================================================

output "rds_instance_id" {
  description = "Identifier of the MediCore managed RDS database."
  value       = aws_db_instance.clinical.identifier
}

output "rds_endpoint" {
  description = "PostgreSQL RDS endpoint including port."
  value       = aws_db_instance.clinical.endpoint
}

output "rds_address" {
  description = "DNS address of the MediCore PostgreSQL RDS instance."
  value       = aws_db_instance.clinical.address
}

output "rds_port" {
  description = "PostgreSQL port used by the MediCore RDS instance."
  value       = aws_db_instance.clinical.port
}

output "rds_subnet_group_name" {
  description = "Restricted RDS DB subnet group."
  value       = aws_db_subnet_group.medicore.name
}

output "rds_backup_retention_days" {
  description = "Automated backup retention period for the RDS database."
  value       = aws_db_instance.clinical.backup_retention_period
}

output "rds_storage_encrypted" {
  description = "Whether RDS storage encryption is enabled."
  value       = aws_db_instance.clinical.storage_encrypted
}

output "rds_publicly_accessible" {
  description = "Whether the managed RDS database is publicly accessible."
  value       = aws_db_instance.clinical.publicly_accessible
}