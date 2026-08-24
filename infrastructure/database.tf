# ============================================================
# RDS DB Subnet Group
# ============================================================

resource "aws_db_subnet_group" "medicore" {
  name        = "${var.project_name}-rds-subnet-group"
  description = "Restricted multi-AZ subnet group for MediCore RDS."

  subnet_ids = [
    aws_subnet.restricted_database.id,
    aws_subnet.restricted_rds_secondary.id
  ]

  tags = {
    Name = "${var.project_name}-rds-subnet-group"
    Tier = "Restricted"
  }
}


# ============================================================
# Managed PostgreSQL RDS Database
# ============================================================

resource "aws_db_instance" "clinical" {
  identifier = "${var.project_name}-clinical-db"

  engine         = "postgres"
  instance_class = var.rds_instance_class

  allocated_storage = var.rds_allocated_storage
  storage_type      = "gp3"

  db_name  = var.rds_database_name
  username = var.rds_master_username
  password = var.db_master_password

  port = 5432

  db_subnet_group_name = aws_db_subnet_group.medicore.name

  vpc_security_group_ids = [
    aws_security_group.rds.id
  ]

  publicly_accessible = false

  storage_encrypted = true

  backup_retention_period = 7

  multi_az = false

  auto_minor_version_upgrade = true
  apply_immediately          = true

  performance_insights_enabled = false

  deletion_protection = false

  copy_tags_to_snapshot = true

  # Assignment/test environment.
  #
  # A production clinical environment would normally use
  # deletion protection and an approved final snapshot /
  # retention policy.
  skip_final_snapshot = true

  delete_automated_backups = true

  tags = {
    Name        = "${var.project_name}-clinical-db"
    Role        = "Managed-Database"
    Tier        = "Restricted"
    DataType    = "Clinical"
    Environment = var.environment
  }
}