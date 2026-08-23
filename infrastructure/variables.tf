variable "aws_region" {
  description = "AWS region used for the MediCore deployment."
  type        = string
  default     = "eu-west-2"
}

variable "project_name" {
  description = "Project name used when naming AWS resources."
  type        = string
  default     = "medicore"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "assignment"
}