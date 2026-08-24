# MediCore Secure Clinical Cloud Infrastructure

Infrastructure-as-Code implementation for the DTS206 Virtualisation and Infrastructure assignment.

## Project Scenario

MediCore Health Systems is a UK digital healthcare organisation requiring a secure, scalable and robust cloud infrastructure for clinical systems and patient data.

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

The current deployment contains:

- One MediCore VPC
- One public Bastion subnet
- One private Web/Application subnet
- One restricted Database subnet
- Three dedicated route tables
- Internet Gateway access for the public subnet only
- No direct Internet route for the private Web/Application subnet
- No direct Internet route for the restricted Database subnet
- Security groups for Bastion, Web/Application and Database tiers
- Ubuntu 22.04 LTS Bastion host
- Ubuntu 22.04 LTS Web/Application VM
- Ubuntu 22.04 LTS dedicated Database VM
- Encrypted EBS root storage
- IMDSv2 enforced on EC2 instances
- Private Amazon S3 storage for static files and backups
- S3 Block Public Access enabled
- S3 SSE-S3 AES-256 encryption
- S3 versioning
- TLS-only S3 bucket policy
- S3 Gateway VPC Endpoint
- Private S3 connectivity from Web and Database tiers

## Network Addressing

| Tier | CIDR | Purpose |
|---|---|---|
| VPC | `10.20.0.0/16` | MediCore cloud network |
| Public | `10.20.10.0/24` | Bastion tier |
| Private | `10.20.20.0/24` | Web/Application tier |
| Restricted | `10.20.30.0/24` | Database tier |

Reserved private addresses:

- Bastion: `10.20.10.10`
- Web/Application VM: `10.20.20.10`
- Database VM: `10.20.30.10`

## Access Model

Administrative access follows a Bastion architecture.

The Bastion host is the only EC2 instance assigned a public IPv4 address.

SSH access to the Bastion is restricted to the deployment administrator's current public IPv4 `/32` address.

The Web/Application and Database VMs do not have public IPv4 addresses.

Administrative access to both private VMs is performed using SSH ProxyJump through the Bastion host.

## Storage Security

The MediCore S3 bucket is designed for static files and backups.

Security controls include:

- S3 Block Public Access
- Bucket-owner-enforced object ownership
- ACLs disabled
- SSE-S3 AES-256 encryption at rest
- Bucket versioning
- HTTP requests denied through an `aws:SecureTransport` policy
- S3 Gateway VPC Endpoint
- Security-group egress restricted to the AWS S3 service prefix

The private Web and restricted Database subnets therefore do not require general Internet access in order to reach Amazon S3.

## Repository Structure

- `/infrastructure` - Terraform Infrastructure-as-Code
- `/docker` - Docker configuration and vulnerability evidence
- `/kubernetes` - Kubernetes manifests
- `/screenshots` - deployment and security evidence
- `/analysis` - Jupyter Notebook and monitoring analysis
- `/docs` - supporting technical documentation
- `/scripts` - supporting administration scripts

## Deployment Status

### Completed

- Development environment configured
- Terraform configured
- AWS provider configured
- MediCore VPC deployed
- Three-tier subnet architecture deployed
- Public/private/restricted route isolation configured
- Security groups configured
- SSH public key registered with AWS
- Bastion host deployed
- Bastion SSH verified
- Web/Application VM deployed
- Dedicated Database VM deployed
- Web and Database VMs verified as having no public IPv4 addresses
- Web SSH access verified through Bastion
- Database SSH access verified through Bastion
- Direct Database SSH access verified as unavailable
- Encrypted EC2 root storage configured
- Private S3 storage deployed
- S3 public access blocked
- S3 AES-256 encryption enabled
- S3 versioning enabled
- TLS-only S3 access policy configured
- S3 Gateway VPC Endpoint deployed
- Private Web and Database S3 connectivity configured

### Next

- AWS RDS managed database
- RDS encryption
- Seven-day automated backup retention
- Point-in-time recovery
- Remaining security and monitoring controls
- High availability and auto scaling
- Containerisation
- Kubernetes
- Data analysis and visualisation

## Security

No AWS credentials, SSH private keys, Terraform state files or sensitive Terraform variable files are committed to this repository.

Terraform state is maintained locally during the assignment and excluded from Git using `.gitignore`.

The local administrator SSH private key is stored outside the repository under the user's `~/.ssh` directory.