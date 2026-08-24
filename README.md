# MediCore Secure Clinical Cloud Infrastructure

Infrastructure-as-Code implementation for the DTS206 Virtualisation and Infrastructure assignment.

## Project Scenario

MediCore Health Systems is a UK digital healthcare organisation requiring secure, scalable and resilient cloud infrastructure for clinical systems and patient data.

The AWS infrastructure in this repository is primarily deployed using Terraform so that the environment is reproducible, version-controlled and auditable.

## Cloud Provider

Amazon Web Services (AWS)

Primary deployment region:

- Europe (London)
- `eu-west-2`

## Infrastructure as Code

Terraform is used as the primary Infrastructure-as-Code tool.

AWS resources are defined within:

`/infrastructure`

The AWS Management Console is primarily used for deployment verification and evidence collection rather than manual infrastructure creation.

## Current Architecture

The deployment contains:

- One MediCore VPC
- One public Bastion subnet
- One private Web/Application subnet
- One primary restricted Database subnet
- One secondary restricted RDS subnet
- Dedicated route tables for public, private and restricted tiers
- Internet Gateway access for the public tier only
- No general Internet route for the private Web/Application tier
- No general Internet route for the restricted Database tier
- Security groups implementing least-privilege network access
- Ubuntu 22.04 LTS Bastion host
- Ubuntu 22.04 LTS Web/Application VM
- Ubuntu 22.04 LTS dedicated Database VM
- Encrypted EBS root volumes
- IMDSv2 enforced on EC2 instances
- Private Amazon S3 storage
- S3 Block Public Access
- S3 SSE-S3 AES-256 encryption
- S3 versioning
- TLS-only S3 bucket policy
- S3 Gateway VPC Endpoint
- Managed Amazon RDS PostgreSQL database
- RDS storage encryption
- Seven-day automated backup retention
- Point-in-time recovery capability
- RDS deployed without public accessibility

## Network Addressing

| Tier | CIDR | Purpose |
|---|---|---|
| VPC | `10.20.0.0/16` | MediCore network |
| Public | `10.20.10.0/24` | Bastion |
| Private | `10.20.20.0/24` | Web/Application |
| Restricted | `10.20.30.0/24` | Database VM and primary RDS subnet |
| Restricted | `10.20.31.0/24` | Secondary RDS subnet |

Reserved EC2 private addresses:

- Bastion: `10.20.10.10`
- Web/Application: `10.20.20.10`
- Database VM: `10.20.30.10`

## Access Model

The Bastion host is the sole publicly addressable EC2 administration entry point.

SSH access to the Bastion is restricted to the deployment administrator's current public IPv4 `/32` address.

The Web/Application and Database VMs do not have public IPv4 addresses.

Administrative access to the Web/Application and Database VMs is performed through the Bastion using SSH ProxyJump.

## Network Isolation

The public route table contains an Internet Gateway route.

The private Web/Application and restricted Database route tables do not contain a general `0.0.0.0/0` Internet route.

The Web/Application and Database VMs therefore do not have general direct Internet connectivity.

## S3 Security

The MediCore S3 bucket is intended for private static files and backup data.

Security controls include:

- Block Public Access enabled
- Bucket-owner-enforced object ownership
- ACLs disabled
- SSE-S3 AES-256 encryption
- Versioning enabled
- Plain HTTP denied through `aws:SecureTransport`
- S3 Gateway VPC Endpoint
- S3 endpoint access restricted to the MediCore bucket
- Web and Database HTTPS egress restricted to the S3 service prefix

## Managed Database Security

Amazon RDS PostgreSQL is deployed in the restricted database tier.

Controls include:

- PostgreSQL
- `db.t3.micro`
- No public accessibility
- Dedicated RDS security group
- TCP 5432 permitted only from the Web/Application VM private address
- Encrypted storage
- Seven-day automated backup retention
- Point-in-time recovery capability
- DB subnet group spanning two Availability Zones

## AWS-Specific RDS Adaptation

The logical MediCore architecture contains three security tiers:

1. Public
2. Private
3. Restricted

Amazon RDS requires a DB subnet group containing subnets in at least two Availability Zones.

A second restricted subnet (`10.20.31.0/24`) was therefore added to extend the existing restricted database tier into another Availability Zone.

This does not introduce a fourth security tier. Both database subnets remain part of the restricted tier and have no direct Internet route.

## Repository Structure

- `/infrastructure` - Terraform Infrastructure-as-Code
- `/docker` - Docker configuration and vulnerability evidence
- `/kubernetes` - Kubernetes manifests
- `/screenshots` - deployment and security evidence
- `/analysis` - monitoring analysis and Jupyter Notebook
- `/docs` - supporting documentation
- `/scripts` - supporting administration scripts

## Deployment Status

### Completed

- Development environment configured
- Terraform configured
- AWS provider configured
- MediCore VPC deployed
- Public/private/restricted network architecture deployed
- Bastion deployed
- Bastion SSH verified
- Web/Application VM deployed
- Database VM deployed
- Private Web and Database addressing verified
- Bastion-only administration verified
- Direct Database SSH failure verified
- EC2 EBS encryption enabled
- IMDSv2 required
- Private S3 bucket deployed
- S3 public access blocked
- S3 AES-256 encryption enabled
- S3 versioning enabled
- TLS-only S3 policy deployed
- S3 Gateway VPC Endpoint deployed
- Managed PostgreSQL RDS deployed
- RDS private connectivity configured
- RDS encryption enabled
- Seven-day RDS backups enabled
- RDS PITR capability configured

### Next

- IAM roles and policies
- CloudWatch monitoring and alarms
- Load balancing
- Auto Scaling
- Multi-AZ Web/Application architecture
- Docker
- Vulnerability scanning
- Kubernetes
- Monitoring analysis

## Security

AWS credentials, SSH private keys, Terraform state files, saved Terraform plans and sensitive Terraform variable files are excluded from Git.

Terraform state is maintained locally during the assignment.

The SSH private key remains outside this repository under the local user's `~/.ssh` directory.

The RDS master password is stored only in the local ignored `terraform.tfvars` and local Terraform state for this assignment environment.