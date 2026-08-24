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
  description = "CIDR range for the public Bastion subnet."
  type        = string
  default     = "10.20.10.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR range for the private Web/Application subnet."
  type        = string
  default     = "10.20.20.0/24"
}

variable "restricted_subnet_cidr" {
  description = "CIDR range for the restricted Database subnet."
  type        = string
  default     = "10.20.30.0/24"
}

variable "admin_cidr" {
  description = "Public IPv4 CIDR permitted to SSH to the Bastion host."
  type        = string

  validation {
    condition = (
      can(cidrhost(var.admin_cidr, 0)) &&
      can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/32$", var.admin_cidr))
    )

    error_message = "admin_cidr must be a valid IPv4 /32 CIDR, for example 203.0.113.10/32."
  }
}

variable "ssh_public_key_path" {
  description = "Path to the local SSH public key imported into AWS."
  type        = string
  default     = "~/.ssh/medicore_ed25519.pub"
}

variable "bastion_private_ip" {
  description = "Static private IPv4 address of the Bastion host."
  type        = string
  default     = "10.20.10.10"
}

variable "web_private_ip" {
  description = "Static private IPv4 address reserved for the Web/Application VM."
  type        = string
  default     = "10.20.20.10"
}

variable "database_private_ip" {
  description = "Static private IPv4 address reserved for the Database VM."
  type        = string
  default     = "10.20.30.10"
}

variable "bastion_instance_type" {
  description = "EC2 instance type used by the Bastion host."
  type        = string
  default     = "t3.micro"
}