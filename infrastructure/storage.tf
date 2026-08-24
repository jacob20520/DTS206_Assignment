# ============================================================
# Private S3 Storage
# ============================================================

resource "aws_s3_bucket" "medicore_storage" {
  bucket_prefix = "${var.project_name}-${var.environment}-private-"

  force_destroy = false

  tags = {
    Name    = "${var.project_name}-private-storage"
    Purpose = "Private static files and backups"
  }
}


# ============================================================
# S3 Public Access Protection
# ============================================================

resource "aws_s3_bucket_public_access_block" "medicore_storage" {
  bucket = aws_s3_bucket.medicore_storage.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}


# ============================================================
# S3 Object Ownership
# ============================================================

resource "aws_s3_bucket_ownership_controls" "medicore_storage" {
  bucket = aws_s3_bucket.medicore_storage.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}


# ============================================================
# S3 AES-256 Encryption At Rest
# ============================================================

resource "aws_s3_bucket_server_side_encryption_configuration" "medicore_storage" {
  bucket = aws_s3_bucket.medicore_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


# ============================================================
# S3 Versioning
# ============================================================

resource "aws_s3_bucket_versioning" "medicore_storage" {
  bucket = aws_s3_bucket.medicore_storage.id

  versioning_configuration {
    status = "Enabled"
  }
}


# ============================================================
# Require TLS For S3
# ============================================================

data "aws_iam_policy_document" "s3_tls_only" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:*"
    ]

    resources = [
      aws_s3_bucket.medicore_storage.arn,
      "${aws_s3_bucket.medicore_storage.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "medicore_storage" {
  bucket = aws_s3_bucket.medicore_storage.id
  policy = data.aws_iam_policy_document.s3_tls_only.json

  depends_on = [
    aws_s3_bucket_public_access_block.medicore_storage
  ]
}


# ============================================================
# S3 Gateway Endpoint Policy
# ============================================================

data "aws_iam_policy_document" "s3_endpoint" {
  statement {
    sid    = "MediCoreStorageOnly"
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketVersions",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject"
    ]

    resources = [
      aws_s3_bucket.medicore_storage.arn,
      "${aws_s3_bucket.medicore_storage.arn}/*"
    ]
  }
}


# ============================================================
# S3 Gateway VPC Endpoint
# ============================================================

resource "aws_vpc_endpoint" "s3" {
  vpc_id = aws_vpc.medicore.id

  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private_web.id,
    aws_route_table.restricted_database.id
  ]

  policy = data.aws_iam_policy_document.s3_endpoint.json

  tags = {
    Name    = "${var.project_name}-vpce-s3"
    Purpose = "Private S3 access from Web and Database tiers"
  }
}