# ============================================================
# A2 - IAM Role Trust Policy
#
# The five assessed MediCore roles are intended to be assumed
# by authorised identities within this AWS account.
#
# MFA is required when assuming the roles.
#
# The account principal in the trust policy does NOT itself
# give every identity permission to assume a role. The calling
# identity must also be delegated sts:AssumeRole permission.
# ============================================================

data "aws_iam_policy_document" "medicore_role_trust" {
  statement {
    sid    = "AllowAuthorisedMediCoreAssumptionWithMFA"
    effect = "Allow"

    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "AWS"

      identifiers = [
        "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }

    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
  }
}


# ============================================================
# ROLE 1 - clinical-read-only
# ============================================================

resource "aws_iam_role" "clinical_read_only" {
  name        = "clinical-read-only"
  path        = "/medicore/"
  description = "Read-only access to MediCore clinical objects."

  assume_role_policy = data.aws_iam_policy_document.medicore_role_trust.json

  max_session_duration = 3600

  tags = {
    Name            = "clinical-read-only"
    SecurityRole    = "ClinicalReadOnly"
    AccessLevel     = "ReadOnly"
    LeastPrivilege  = "True"
    AssignmentStage = "A2"
  }
}


# ============================================================
# clinical-read-only Policy
# ============================================================

data "aws_iam_policy_document" "clinical_read_only" {
  statement {
    sid    = "ListClinicalPrefix"
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.medicore_storage.arn
    ]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"

      values = [
        "clinical",
        "clinical/*"
      ]
    }
  }

  statement {
    sid    = "ReadClinicalObjects"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]

    resources = [
      "${aws_s3_bucket.medicore_storage.arn}/clinical/*"
    ]
  }
}

resource "aws_iam_policy" "clinical_read_only" {
  name        = "medicore-clinical-read-only"
  description = "Least-privilege read-only access to MediCore clinical S3 objects."

  policy = data.aws_iam_policy_document.clinical_read_only.json

  tags = {
    Name            = "medicore-clinical-read-only"
    AssignmentStage = "A2"
  }
}

resource "aws_iam_role_policy_attachment" "clinical_read_only" {
  role       = aws_iam_role.clinical_read_only.name
  policy_arn = aws_iam_policy.clinical_read_only.arn
}


# ============================================================
# ROLE 2 - clinical-write
# ============================================================

resource "aws_iam_role" "clinical_write" {
  name        = "clinical-write"
  path        = "/medicore/"
  description = "Controlled read and write access to MediCore clinical objects."

  assume_role_policy = data.aws_iam_policy_document.medicore_role_trust.json

  max_session_duration = 3600

  tags = {
    Name            = "clinical-write"
    SecurityRole    = "ClinicalWrite"
    AccessLevel     = "ReadWrite"
    LeastPrivilege  = "True"
    AssignmentStage = "A2"
  }
}


# ============================================================
# clinical-write Policy
#
# Deliberately does NOT grant s3:DeleteObject.
# ============================================================

data "aws_iam_policy_document" "clinical_write" {
  statement {
    sid    = "ListClinicalPrefix"
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.medicore_storage.arn
    ]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"

      values = [
        "clinical",
        "clinical/*"
      ]
    }
  }

  statement {
    sid    = "ReadWriteClinicalObjects"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
      "s3:AbortMultipartUpload"
    ]

    resources = [
      "${aws_s3_bucket.medicore_storage.arn}/clinical/*"
    ]
  }
}

resource "aws_iam_policy" "clinical_write" {
  name        = "medicore-clinical-write"
  description = "Least-privilege read/write access to MediCore clinical S3 objects without delete permission."

  policy = data.aws_iam_policy_document.clinical_write.json

  tags = {
    Name            = "medicore-clinical-write"
    AssignmentStage = "A2"
  }
}

resource "aws_iam_role_policy_attachment" "clinical_write" {
  role       = aws_iam_role.clinical_write.name
  policy_arn = aws_iam_policy.clinical_write.arn
}


# ============================================================
# ROLE 3 - db-admin
# ============================================================

resource "aws_iam_role" "db_admin" {
  name        = "db-admin"
  path        = "/medicore/"
  description = "Operational administration of the MediCore managed RDS database."

  assume_role_policy = data.aws_iam_policy_document.medicore_role_trust.json

  max_session_duration = 3600

  tags = {
    Name            = "db-admin"
    SecurityRole    = "DatabaseAdministrator"
    AccessLevel     = "DatabaseOperations"
    LeastPrivilege  = "True"
    AssignmentStage = "A2"
  }
}


# ============================================================
# db-admin Policy
# ============================================================

data "aws_iam_policy_document" "db_admin" {
  statement {
    sid    = "DescribeRDS"
    effect = "Allow"

    actions = [
      "rds:DescribeDBInstances",
      "rds:DescribeDBSnapshots",
      "rds:DescribeDBSubnetGroups",
      "rds:DescribeDBParameterGroups",
      "rds:DescribeDBParameters",
      "rds:ListTagsForResource"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    sid    = "OperateMediCoreDatabase"
    effect = "Allow"

    actions = [
      "rds:StartDBInstance",
      "rds:StopDBInstance",
      "rds:RebootDBInstance"
    ]

    resources = [
      aws_db_instance.clinical.arn
    ]
  }

  statement {
    sid    = "CreateMediCoreDatabaseSnapshots"
    effect = "Allow"

    actions = [
      "rds:CreateDBSnapshot"
    ]

    resources = [
      aws_db_instance.clinical.arn,
      "arn:${data.aws_partition.current.partition}:rds:${var.aws_region}:${data.aws_caller_identity.current.account_id}:snapshot:${var.project_name}-*"
    ]
  }
}

resource "aws_iam_policy" "db_admin" {
  name        = "medicore-db-admin"
  description = "Least-privilege operational administration of the MediCore RDS database."

  policy = data.aws_iam_policy_document.db_admin.json

  tags = {
    Name            = "medicore-db-admin"
    AssignmentStage = "A2"
  }
}

resource "aws_iam_role_policy_attachment" "db_admin" {
  role       = aws_iam_role.db_admin.name
  policy_arn = aws_iam_policy.db_admin.arn
}


# ============================================================
# ROLE 4 - monitoring-only
# ============================================================

resource "aws_iam_role" "monitoring_only" {
  name        = "monitoring-only"
  path        = "/medicore/"
  description = "Read-only monitoring access to CloudWatch and MediCore infrastructure metadata."

  assume_role_policy = data.aws_iam_policy_document.medicore_role_trust.json

  max_session_duration = 3600

  tags = {
    Name            = "monitoring-only"
    SecurityRole    = "Monitoring"
    AccessLevel     = "ReadOnly"
    LeastPrivilege  = "True"
    AssignmentStage = "A2"
  }
}


# ============================================================
# monitoring-only Policy
# ============================================================

data "aws_iam_policy_document" "monitoring_only" {
  statement {
    sid    = "ReadCloudWatchMetricsAndAlarms"
    effect = "Allow"

    actions = [
      "cloudwatch:DescribeAlarms",
      "cloudwatch:DescribeAlarmHistory",
      "cloudwatch:GetMetricData",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:GetMetricWidgetImage",
      "cloudwatch:ListMetrics"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    sid    = "ReadCloudWatchLogs"
    effect = "Allow"

    actions = [
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:GetLogEvents",
      "logs:FilterLogEvents",
      "logs:StartQuery",
      "logs:StopQuery",
      "logs:GetQueryResults"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    sid    = "ReadInfrastructureMetadata"
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeVolumes",
      "rds:DescribeDBInstances",
      "rds:DescribeDBSnapshots"
    ]

    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "monitoring_only" {
  name        = "medicore-monitoring-only"
  description = "Read-only access to MediCore CloudWatch monitoring and infrastructure metadata."

  policy = data.aws_iam_policy_document.monitoring_only.json

  tags = {
    Name            = "medicore-monitoring-only"
    AssignmentStage = "A2"
  }
}

resource "aws_iam_role_policy_attachment" "monitoring_only" {
  role       = aws_iam_role.monitoring_only.name
  policy_arn = aws_iam_policy.monitoring_only.arn
}


# ============================================================
# ROLE 5 - backup-operator
# ============================================================

resource "aws_iam_role" "backup_operator" {
  name        = "backup-operator"
  path        = "/medicore/"
  description = "Controlled access to MediCore backup objects and RDS snapshot creation."

  assume_role_policy = data.aws_iam_policy_document.medicore_role_trust.json

  max_session_duration = 3600

  tags = {
    Name            = "backup-operator"
    SecurityRole    = "BackupOperator"
    AccessLevel     = "BackupOperations"
    LeastPrivilege  = "True"
    AssignmentStage = "A2"
  }
}


# ============================================================
# backup-operator Policy
#
# Deliberately excludes object and snapshot deletion.
# ============================================================

data "aws_iam_policy_document" "backup_operator" {
  statement {
    sid    = "ListBackupPrefix"
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:ListBucketVersions"
    ]

    resources = [
      aws_s3_bucket.medicore_storage.arn
    ]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"

      values = [
        "backups",
        "backups/*"
      ]
    }
  }

  statement {
    sid    = "ReadWriteBackupObjects"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
      "s3:AbortMultipartUpload"
    ]

    resources = [
      "${aws_s3_bucket.medicore_storage.arn}/backups/*"
    ]
  }

  statement {
    sid    = "DescribeRDSBackups"
    effect = "Allow"

    actions = [
      "rds:DescribeDBInstances",
      "rds:DescribeDBSnapshots",
      "rds:ListTagsForResource"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    sid    = "CreateMediCoreBackupSnapshots"
    effect = "Allow"

    actions = [
      "rds:CreateDBSnapshot"
    ]

    resources = [
      aws_db_instance.clinical.arn,
      "arn:${data.aws_partition.current.partition}:rds:${var.aws_region}:${data.aws_caller_identity.current.account_id}:snapshot:${var.project_name}-backup-*"
    ]
  }
}

resource "aws_iam_policy" "backup_operator" {
  name        = "medicore-backup-operator"
  description = "Least-privilege access for MediCore S3 backups and RDS snapshot creation."

  policy = data.aws_iam_policy_document.backup_operator.json

  tags = {
    Name            = "medicore-backup-operator"
    AssignmentStage = "A2"
  }
}

resource "aws_iam_role_policy_attachment" "backup_operator" {
  role       = aws_iam_role.backup_operator.name
  policy_arn = aws_iam_policy.backup_operator.arn
}