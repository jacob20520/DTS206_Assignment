# ============================================================
# A2 - AWS Account Information
# ============================================================

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}