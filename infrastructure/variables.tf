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

variable "vpc_cidr" {
  description = "CIDR range for the MediCore VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR range for the public bastion subnet."
  type        = string
  default     = "10.20.10.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR range for the private web/application subnet."
  type        = string
  default     = "10.20.20.0/24"
}

variable "restricted_subnet_cidr" {
  description = "CIDR range for the restricted database subnet."
  type        = string
  default     = "10.20.30.0/24"
}