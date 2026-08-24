# ============================================================
# A3 - Application Load Balancer
# ============================================================

resource "aws_lb" "a3_web" {
  name = "${var.project_name}-a3-alb"

  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.a3_alb.id
  ]

  subnets = [
    aws_subnet.a3_public_alb_az1.id,
    aws_subnet.a3_public_alb_az2.id,
    aws_subnet.a3_public_alb_az3.id
  ]

  enable_deletion_protection = false
  drop_invalid_header_fields = true

  tags = {
    Name            = "${var.project_name}-a3-alb"
    Tier            = "Public"
    Purpose         = "Scalable Web/Application entry point"
    AssignmentStage = "A3"
  }
}


# ============================================================
# A3 - Web Target Group
# ============================================================

resource "aws_lb_target_group" "a3_web" {
  name = "${var.project_name}-a3-web-tg"

  port     = var.a3_backend_port
  protocol = "HTTP"

  vpc_id      = aws_vpc.medicore.id
  target_type = "instance"

  deregistration_delay = 30

  health_check {
    enabled = true

    protocol = "HTTP"
    port     = "traffic-port"

    path = "/"

    matcher = "200"

    interval = 30
    timeout  = 5

    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name            = "${var.project_name}-a3-web-tg"
    AssignmentStage = "A3"
  }
}


# ============================================================
# A3 - HTTP Listener
# ============================================================

resource "aws_lb_listener" "a3_http" {
  load_balancer_arn = aws_lb.a3_web.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.a3_web.arn
  }
}