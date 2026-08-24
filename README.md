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

AWS resources are created from configuration stored within:

`/infrastructure`

The AWS Management Console is primarily used for verification and evidence collection rather than manual infrastructure creation.

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
- Security groups for the Bastion, Web/Application and Database tiers
- An Ubuntu 22.04 LTS Bastion host
- Encrypted Bastion EBS storage
- IMDSv2 enforced on the Bastion

## Network Addressing

| Tier | CIDR | Purpose |
|---|---|---|
| VPC | `10.20.0.0/16` | MediCore cloud network |
| Public | `10.20.10.0/24` | Bastion host |
| Private | `10.20.20.0/24` | Web/Application tier |
| Restricted | `10.20.30.0/24` | Database tier |

Reserved private addresses:

- Bastion: `10.20.10.10`
- Web/Application VM: `10.20.20.10`
- Database VM: `10.20.30.10`

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

### In Progress

- Bastion SSH verification

### Next

- Web/Application VM
- Dedicated Database VM
- Bastion-only SSH verification
- Private S3 storage
- AWS RDS

## Security

No AWS credentials, SSH private keys, Terraform state files or sensitive variable files are committed to this repository.

Administrative SSH access to the Bastion is restricted to a single authorised public IPv4 `/32` address.