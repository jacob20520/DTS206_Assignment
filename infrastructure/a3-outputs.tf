# ============================================================
# A3 - Public ALB Subnets
# ============================================================

output "a3_public_alb_subnets" {
  description = "Three public ALB subnets spanning three Availability Zones."

  value = {
    az1 = {
      id   = aws_subnet.a3_public_alb_az1.id
      cidr = aws_subnet.a3_public_alb_az1.cidr_block
      az   = aws_subnet.a3_public_alb_az1.availability_zone
    }

    az2 = {
      id   = aws_subnet.a3_public_alb_az2.id
      cidr = aws_subnet.a3_public_alb_az2.cidr_block
      az   = aws_subnet.a3_public_alb_az2.availability_zone
    }

    az3 = {
      id   = aws_subnet.a3_public_alb_az3.id
      cidr = aws_subnet.a3_public_alb_az3.cidr_block
      az   = aws_subnet.a3_public_alb_az3.availability_zone
    }
  }
}


# ============================================================
# A3 - Private Web Subnets
# ============================================================

output "a3_private_web_subnets" {
  description = "Three private Web/Application subnets spanning three Availability Zones."

  value = {
    az1 = {
      id   = aws_subnet.a3_private_web_az1.id
      cidr = aws_subnet.a3_private_web_az1.cidr_block
      az   = aws_subnet.a3_private_web_az1.availability_zone
    }

    az2 = {
      id   = aws_subnet.private_web.id
      cidr = aws_subnet.private_web.cidr_block
      az   = aws_subnet.private_web.availability_zone
    }

    az3 = {
      id   = aws_subnet.a3_private_web_az3.id
      cidr = aws_subnet.a3_private_web_az3.cidr_block
      az   = aws_subnet.a3_private_web_az3.availability_zone
    }
  }
}


# ============================================================
# A3 - Load Balancer
# ============================================================

output "a3_alb_dns_name" {
  description = "Public DNS name of the MediCore Application Load Balancer."
  value       = aws_lb.a3_web.dns_name
}

output "a3_alb_url" {
  description = "HTTP URL used to test the MediCore Application Load Balancer."
  value       = "http://${aws_lb.a3_web.dns_name}"
}

output "a3_target_group_arn" {
  description = "ARN of the MediCore Web target group."
  value       = aws_lb_target_group.a3_web.arn
}


# ============================================================
# A3 - Auto Scaling
# ============================================================

output "a3_asg_name" {
  description = "Name of the MediCore Web Auto Scaling Group."
  value       = aws_autoscaling_group.a3_web.name
}

output "a3_asg_min_size" {
  description = "Minimum Web Auto Scaling capacity."
  value       = aws_autoscaling_group.a3_web.min_size
}

output "a3_asg_max_size" {
  description = "Maximum Web Auto Scaling capacity."
  value       = aws_autoscaling_group.a3_web.max_size
}

output "a3_launch_template_id" {
  description = "Launch template used by the scalable Web tier."
  value       = aws_launch_template.a3_web.id
}

output "a3_scale_out_alarm_name" {
  description = "CloudWatch alarm controlling A3 Web scale-out."
  value       = aws_cloudwatch_metric_alarm.a3_web_cpu_scale_out.alarm_name
}