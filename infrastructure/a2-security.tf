# ============================================================
# A2 - Regional EBS Encryption By Default
#
# Existing MediCore EC2 root volumes are already encrypted
# individually. This additionally ensures that future EBS
# volumes created in eu-west-2 are encrypted by default.
# ============================================================

resource "aws_ebs_encryption_by_default" "medicore" {
  enabled = true
}