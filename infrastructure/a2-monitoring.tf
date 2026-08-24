# ============================================================
# A2 - CloudWatch Monitoring
#
# Five assessed CloudWatch metric alarms.
#
# Standard metric periods are used rather than enabling
# additional EC2 detailed monitoring at this stage.
# ============================================================


# ============================================================
# A2-ALARM-01
# Bastion Status Check Failure
# ============================================================

resource "aws_cloudwatch_metric_alarm" "bastion_status_check_failed" {
  alarm_name = "${var.project_name}-a2-bastion-status-check-failed"

  alarm_description = "IRP-A2-01: Bastion StatusCheckFailed >= 1. Response: verify EC2 instance/system checks, preserve diagnostic evidence, investigate availability or compromise, and escalate through the MediCore incident response procedure."

  namespace   = "AWS/EC2"
  metric_name = "StatusCheckFailed"

  dimensions = {
    InstanceId = aws_instance.bastion.id
  }

  statistic = "Maximum"
  period    = 300

  evaluation_periods  = 1
  datapoints_to_alarm = 1

  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1

  treat_missing_data = "notBreaching"

  tags = {
    Name            = "${var.project_name}-a2-bastion-status-check-failed"
    AlertID         = "A2-ALARM-01"
    IRPReference    = "IRP-A2-01"
    AssignmentStage = "A2"
  }
}


# ============================================================
# A2-ALARM-02
# Web/Application CPU High
# ============================================================

resource "aws_cloudwatch_metric_alarm" "web_cpu_high" {
  alarm_name = "${var.project_name}-a2-web-cpu-high"

  alarm_description = "IRP-A2-02: Web/Application CPUUtilization > 70 percent for two consecutive 5-minute periods. Response: verify workload, review unexpected demand, inspect application activity, and escalate if abnormal or malicious activity is suspected."

  namespace   = "AWS/EC2"
  metric_name = "CPUUtilization"

  dimensions = {
    InstanceId = aws_instance.web.id
  }

  statistic = "Average"
  period    = 300

  evaluation_periods  = 2
  datapoints_to_alarm = 2

  comparison_operator = "GreaterThanThreshold"
  threshold           = 70

  treat_missing_data = "notBreaching"

  tags = {
    Name            = "${var.project_name}-a2-web-cpu-high"
    AlertID         = "A2-ALARM-02"
    IRPReference    = "IRP-A2-02"
    AssignmentStage = "A2"
  }
}


# ============================================================
# A2-ALARM-03
# Dedicated Database VM CPU High
# ============================================================

resource "aws_cloudwatch_metric_alarm" "database_cpu_high" {
  alarm_name = "${var.project_name}-a2-database-cpu-high"

  alarm_description = "IRP-A2-03: Dedicated Database VM CPUUtilization > 70 percent for two consecutive 5-minute periods. Response: investigate database workload and unexpected processes, preserve evidence, confirm service availability, and escalate suspicious behaviour."

  namespace   = "AWS/EC2"
  metric_name = "CPUUtilization"

  dimensions = {
    InstanceId = aws_instance.database.id
  }

  statistic = "Average"
  period    = 300

  evaluation_periods  = 2
  datapoints_to_alarm = 2

  comparison_operator = "GreaterThanThreshold"
  threshold           = 70

  treat_missing_data = "notBreaching"

  tags = {
    Name            = "${var.project_name}-a2-database-cpu-high"
    AlertID         = "A2-ALARM-03"
    IRPReference    = "IRP-A2-03"
    AssignmentStage = "A2"
  }
}


# ============================================================
# A2-ALARM-04
# RDS CPU High
# ============================================================

resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name = "${var.project_name}-a2-rds-cpu-high"

  alarm_description = "IRP-A2-04: Managed RDS CPUUtilization > 70 percent for two consecutive 5-minute periods. Response: review database workload, connections and performance, determine whether the event is operational or security-related, and escalate according to the MediCore incident response procedure."

  namespace   = "AWS/RDS"
  metric_name = "CPUUtilization"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.clinical.identifier
  }

  statistic = "Average"
  period    = 300

  evaluation_periods  = 2
  datapoints_to_alarm = 2

  comparison_operator = "GreaterThanThreshold"
  threshold           = 70

  treat_missing_data = "notBreaching"

  tags = {
    Name            = "${var.project_name}-a2-rds-cpu-high"
    AlertID         = "A2-ALARM-04"
    IRPReference    = "IRP-A2-04"
    AssignmentStage = "A2"
  }
}


# ============================================================
# A2-ALARM-05
# RDS Free Storage Low
#
# Threshold = 2 GiB
# 2 * 1024 * 1024 * 1024 = 2147483648 bytes
# ============================================================

resource "aws_cloudwatch_metric_alarm" "rds_free_storage_low" {
  alarm_name = "${var.project_name}-a2-rds-free-storage-low"

  alarm_description = "IRP-A2-05: Managed RDS FreeStorageSpace < 2 GiB. Response: investigate storage growth, preserve database availability, determine whether abnormal ingestion or malicious activity is responsible, and escalate if patient-data availability is threatened."

  namespace   = "AWS/RDS"
  metric_name = "FreeStorageSpace"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.clinical.identifier
  }

  statistic = "Minimum"
  period    = 300

  evaluation_periods  = 1
  datapoints_to_alarm = 1

  comparison_operator = "LessThanThreshold"
  threshold           = 2147483648

  treat_missing_data = "notBreaching"

  tags = {
    Name            = "${var.project_name}-a2-rds-free-storage-low"
    AlertID         = "A2-ALARM-05"
    IRPReference    = "IRP-A2-05"
    AssignmentStage = "A2"
  }
}