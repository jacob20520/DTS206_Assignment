# ============================================================
# A3 - Public Application Load Balancer Subnets
# ============================================================

variable "a3_public_alb_az1_cidr" {
  description = "Public ALB subnet CIDR in Availability Zone 1."
  type        = string
  default     = "10.20.11.0/24"
}

variable "a3_public_alb_az2_cidr" {
  description = "Public ALB subnet CIDR in Availability Zone 2."
  type        = string
  default     = "10.20.12.0/24"
}

variable "a3_public_alb_az3_cidr" {
  description = "Public ALB subnet CIDR in Availability Zone 3."
  type        = string
  default     = "10.20.13.0/24"
}


# ============================================================
# A3 - Additional Private Web Subnets
#
# 10.20.20.0/24 already exists in AZ 2.
# These two subnets provide Web capacity in AZ 1 and AZ 3.
# ============================================================

variable "a3_private_web_az1_cidr" {
  description = "Additional private Web/Application subnet in Availability Zone 1."
  type        = string
  default     = "10.20.21.0/24"
}

variable "a3_private_web_az3_cidr" {
  description = "Additional private Web/Application subnet in Availability Zone 3."
  type        = string
  default     = "10.20.22.0/24"
}


# ============================================================
# A3 - Auto Scaling
# ============================================================

variable "a3_web_instance_type" {
  description = "EC2 instance type used by the scalable Web/Application tier."
  type        = string
  default     = "t3.micro"
}

variable "a3_asg_min_size" {
  description = "Minimum number of Web/Application instances."
  type        = number
  default     = 2
}

variable "a3_asg_max_size" {
  description = "Maximum number of Web/Application instances."
  type        = number
  default     = 4
}

variable "a3_asg_desired_capacity" {
  description = "Initial desired capacity used to demonstrate deployment across three AZs."
  type        = number
  default     = 3
}

variable "a3_backend_port" {
  description = "Internal application port used between the ALB and Web instances."
  type        = number
  default     = 8080
}

variable "a3_scale_out_cpu_threshold" {
  description = "Average ASG CPU threshold that triggers scale-out."
  type        = number
  default     = 70
}