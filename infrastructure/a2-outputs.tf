# ============================================================
# A2 - IAM Role Outputs
# ============================================================

output "a2_iam_role_names" {
  description = "Names of the five assessed MediCore IAM roles."

  value = {
    clinical_read_only = aws_iam_role.clinical_read_only.name
    clinical_write     = aws_iam_role.clinical_write.name
    db_admin           = aws_iam_role.db_admin.name
    monitoring_only    = aws_iam_role.monitoring_only.name
    backup_operator    = aws_iam_role.backup_operator.name
  }
}

output "a2_iam_role_arns" {
  description = "ARNs of the five assessed MediCore IAM roles."

  value = {
    clinical_read_only = aws_iam_role.clinical_read_only.arn
    clinical_write     = aws_iam_role.clinical_write.arn
    db_admin           = aws_iam_role.db_admin.arn
    monitoring_only    = aws_iam_role.monitoring_only.arn
    backup_operator    = aws_iam_role.backup_operator.arn
  }
}


# ============================================================
# A2 - CloudWatch Alarm Outputs
# ============================================================

output "a2_cloudwatch_alarm_names" {
  description = "CloudWatch alarms created for A2."

  value = {
    bastion_status_check_failed = aws_cloudwatch_metric_alarm.bastion_status_check_failed.alarm_name
    web_cpu_high                = aws_cloudwatch_metric_alarm.web_cpu_high.alarm_name
    database_cpu_high           = aws_cloudwatch_metric_alarm.database_cpu_high.alarm_name
    rds_cpu_high                = aws_cloudwatch_metric_alarm.rds_cpu_high.alarm_name
    rds_free_storage_low        = aws_cloudwatch_metric_alarm.rds_free_storage_low.alarm_name
  }
}


# ============================================================
# A2 - Security Outputs
# ============================================================

output "a2_ebs_encryption_by_default" {
  description = "Whether EBS encryption by default is enabled in the deployment region."
  value       = aws_ebs_encryption_by_default.medicore.enabled
}

output "a2_rds_engine_version_actual" {
  description = "Actual PostgreSQL version running on the MediCore RDS database."
  value       = aws_db_instance.clinical.engine_version_actual
}