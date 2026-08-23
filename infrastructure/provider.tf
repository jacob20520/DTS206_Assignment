provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "MediCore"
      Environment = "Assignment"
      ManagedBy   = "Terraform"
      Module      = "DTS206"
    }
  }
}