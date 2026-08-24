# A3 Scalability and High Availability

## Overview

The MediCore Web/Application tier was extended from a single private VM into a scalable multi-Availability-Zone architecture.

The original A1 Web VM remains as evidence of the initial three-tier deployment.

The A3 Web tier uses:

- Application Load Balancer
- EC2 Launch Template
- Auto Scaling Group
- Three Availability Zones
- Three private Web subnets
- Health checking
- CPU-based scaling
- Automatic instance replacement

## Auto Scaling Configuration

Minimum capacity:

2 instances

Maximum capacity:

4 instances

Initial desired capacity:

3 instances

The initial capacity of three is used to demonstrate active application capacity across three Availability Zones.

The minimum remains two, satisfying the assignment requirement.

## Scale-Out Rule

Metric:

`AWS/EC2 CPUUtilization`

Scope:

MediCore A3 Auto Scaling Group

Threshold:

Greater than 70 percent

Metric period:

60 seconds

Evaluation periods:

3

Datapoints to alarm:

3

Result:

The scale-out policy adds one EC2 instance.

Detailed EC2 monitoring is enabled to provide one-minute CPU metrics.

## Load Balancing

An internet-facing Application Load Balancer distributes application traffic to private Web/Application instances.

The ALB operates across three dedicated public application subnets.

The Web instances do not have public IPv4 addresses.

The scalable Web Security Group accepts application traffic only from the ALB Security Group.

## Health Check

Protocol:

HTTP

Backend port:

8080

Path:

`/`

Expected response:

`200`

Healthy threshold:

2 successful checks

Unhealthy threshold:

2 failed checks

## Three-AZ Design

The scalable Web tier spans three Availability Zones.

The original private Web subnet is retained as the AZ2 Web subnet.

Two additional private Web subnets provide capacity in AZ1 and AZ3.

Three dedicated public ALB subnets provide an application ingress path in the same three Availability Zones.

## Administrative Access

The Bastion remains the only public EC2 administrative entry point.

Scalable Web instances have no public IPv4 addresses.

SSH administration of an ASG Web instance is possible only through the Bastion.

## Architectural Adaptation

A1 began with a three-subnet architecture representing:

- Public
- Private
- Restricted

RDS required a second restricted subnet to satisfy AWS multi-AZ DB subnet group requirements.

A3 requires application resources across at least three Availability Zones.

The physical subnet count was therefore expanded while preserving the original three logical security tiers.

Public ALB subnets remain part of the public application tier.

Private ASG Web subnets remain part of the private tier.

Restricted RDS subnets remain part of the restricted database tier.

The Bastion subnet remains dedicated to administrative access.

## Public Entry-Point Adaptation

The Bastion remains the sole public administrative entry point.

A3 introduces an Application Load Balancer as the public application entry point.

The ALB does not provide SSH or administrative access.

This separates:

- Administrative ingress through the Bastion
- Application ingress through the ALB

## Availability-Zone Failure Simulation

An application instance in one Availability Zone is deliberately terminated without reducing desired ASG capacity.

Expected behaviour:

1. The target enters a draining/unhealthy state.
2. The Application Load Balancer stops routing new traffic to the failed target.
3. Requests continue to healthy targets in the remaining Availability Zones.
4. Auto Scaling detects the capacity loss.
5. Auto Scaling launches replacement capacity.
6. The replacement passes the `GET /` health check.
7. The replacement becomes an active ALB target.

Screenshots record the initial three-AZ state, failed target, continuing HTTP responses and replacement instance.

## Cost Considerations

Amazon EC2 Auto Scaling has no additional service charge, although the EC2, EBS and monitoring resources it operates remain chargeable.

The Application Load Balancer is a billable resource while deployed.

Detailed EC2 monitoring also incurs CloudWatch metric charges.

A production environment would retain the resilient architecture continuously.

The assignment environment can be scaled down or destroyed after evidence is collected to minimise unnecessary cost.