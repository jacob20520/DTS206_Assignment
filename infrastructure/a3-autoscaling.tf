# ============================================================
# A3 - Web/Application Launch Template
# ============================================================

resource "aws_launch_template" "a3_web" {
  name_prefix = "${var.project_name}-a3-web-"

  image_id      = data.aws_ami.ubuntu_2204.id
  instance_type = var.a3_web_instance_type
  key_name      = aws_key_pair.medicore.key_name

  update_default_version = true

  vpc_security_group_ids = [
    aws_security_group.a3_web.id
  ]


  # ==========================================================
  # Encrypted Root Storage
  # ==========================================================

  block_device_mappings {
    device_name = data.aws_ami.ubuntu_2204.root_device_name

    ebs {
      volume_type = "gp3"
      volume_size = 8

      encrypted             = true
      delete_on_termination = true
    }
  }


  # ==========================================================
  # IMDSv2
  # ==========================================================

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }


  # ==========================================================
  # 1-Minute Detailed Monitoring
  #
  # Required so the CPU >70% for three 1-minute periods
  # can be represented accurately.
  # ==========================================================

  monitoring {
    enabled = true
  }


  # ==========================================================
  # Bootstrap Minimal Web Application
  #
  # No apt update/install is required because the private
  # subnets deliberately have no general Internet route.
  #
  # Ubuntu already provides Python 3 for cloud-init.
  # ==========================================================

  user_data = base64encode(<<-EOF
    #!/bin/bash

    set -euxo pipefail

    PRIVATE_IP=$(hostname -I | awk '{print $1}')
    SAFE_IP=$(echo "$PRIVATE_IP" | tr '.' '-')

    hostnamectl set-hostname "medicore-web-$${SAFE_IP}"

    if ! id medicoreweb >/dev/null 2>&1; then
      useradd \
        --system \
        --home-dir /opt/medicore-web \
        --shell /usr/sbin/nologin \
        medicoreweb
    fi

    mkdir -p /opt/medicore-web

    cat > /opt/medicore-web/index.html <<HTML
    <!doctype html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <title>MediCore Web Tier</title>
    </head>
    <body>
      <h1>MediCore Health Systems</h1>
      <p>Status: healthy</p>
      <p>Backend: medicore-web-$${SAFE_IP}</p>
      <p>Private IP: $${PRIVATE_IP}</p>
      <p>Environment: Assignment A3</p>
    </body>
    </html>
    HTML

    chown -R medicoreweb:medicoreweb /opt/medicore-web

    cat > /etc/systemd/system/medicore-web.service <<'SERVICE'
    [Unit]
    Description=MediCore A3 Web Service
    After=network-online.target
    Wants=network-online.target

    [Service]
    Type=simple
    User=medicoreweb
    Group=medicoreweb

    WorkingDirectory=/opt/medicore-web

    ExecStart=/usr/bin/python3 -m http.server 8080 --bind 0.0.0.0 --directory /opt/medicore-web

    Restart=always
    RestartSec=5

    NoNewPrivileges=true
    PrivateTmp=true
    ProtectHome=true
    ProtectSystem=strict

    [Install]
    WantedBy=multi-user.target
    SERVICE

    systemctl daemon-reload
    systemctl enable medicore-web.service
    systemctl start medicore-web.service
  EOF
  )


  # ==========================================================
  # Instance Tags
  # ==========================================================

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name            = "${var.project_name}-web-asg"
      Role            = "Web-Application"
      Tier            = "Private"
      ManagedBy       = "AutoScaling"
      AssignmentStage = "A3"
    }
  }


  # ==========================================================
  # Volume Tags
  # ==========================================================

  tag_specifications {
    resource_type = "volume"

    tags = {
      Name            = "${var.project_name}-web-asg-volume"
      Tier            = "Private"
      AssignmentStage = "A3"
    }
  }

  tags = {
    Name            = "${var.project_name}-a3-web-launch-template"
    AssignmentStage = "A3"
  }
}


# ============================================================
# A3 - Auto Scaling Group
# ============================================================

resource "aws_autoscaling_group" "a3_web" {
  name = "${var.project_name}-a3-web-asg"

  min_size         = var.a3_asg_min_size
  max_size         = var.a3_asg_max_size
  desired_capacity = var.a3_asg_desired_capacity

  vpc_zone_identifier = [
    aws_subnet.a3_private_web_az1.id,
    aws_subnet.private_web.id,
    aws_subnet.a3_private_web_az3.id
  ]

  target_group_arns = [
    aws_lb_target_group.a3_web.arn
  ]

  health_check_type         = "ELB"
  health_check_grace_period = 180

  default_cooldown        = 300
  default_instance_warmup = 120

  launch_template {
    id      = aws_launch_template.a3_web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-web-asg"
    propagate_at_launch = true
  }

  tag {
    key                 = "Tier"
    value               = "Private"
    propagate_at_launch = true
  }

  tag {
    key                 = "AssignmentStage"
    value               = "A3"
    propagate_at_launch = true
  }

  # Scaling policies are allowed to change desired capacity
  # without Terraform immediately trying to reset the group.
  lifecycle {
    ignore_changes = [
      desired_capacity
    ]
  }

  depends_on = [
    aws_lb_listener.a3_http
  ]
}


# ============================================================
# A3 - Scale-Out Policy
#
# When the CloudWatch alarm fires, add one Web instance.
# ============================================================

resource "aws_autoscaling_policy" "a3_web_scale_out" {
  name = "${var.project_name}-a3-web-scale-out"

  autoscaling_group_name = aws_autoscaling_group.a3_web.name

  policy_type        = "SimpleScaling"
  adjustment_type    = "ChangeInCapacity"
  scaling_adjustment = 1

  cooldown = 300
}


# ============================================================
# A3 - CPU >70% For 3 Minutes
#
# 60-second metric period
# x
# 3 consecutive evaluation periods
# =
# 3 minutes
# ============================================================

resource "aws_cloudwatch_metric_alarm" "a3_web_cpu_scale_out" {
  alarm_name = "${var.project_name}-a3-web-cpu-scale-out"

  alarm_description = "A3 scaling rule: Web Auto Scaling Group average CPU exceeds 70 percent for three consecutive one-minute periods. Scale out by one instance."

  namespace   = "AWS/EC2"
  metric_name = "CPUUtilization"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.a3_web.name
  }

  statistic = "Average"

  period = 60

  evaluation_periods  = 3
  datapoints_to_alarm = 3

  comparison_operator = "GreaterThanThreshold"
  threshold           = var.a3_scale_out_cpu_threshold

  treat_missing_data = "notBreaching"

  alarm_actions = [
    aws_autoscaling_policy.a3_web_scale_out.arn
  ]

  tags = {
    Name            = "${var.project_name}-a3-web-cpu-scale-out"
    AssignmentStage = "A3"
  }
}