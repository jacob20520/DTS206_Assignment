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

AWS CLI commands are also used to verify deployed configuration and produce repeatable technical evidence.

---

## Current Architecture

The current deployment contains:

- One MediCore VPC
- Public Bastion subnet
- Private Web/Application subnet
- Restricted Database subnet
- Secondary restricted RDS subnet
- Dedicated route tables for public, private and restricted tiers
- Internet Gateway access for the public tier only
- No general Internet route for the private Web/Application tier
- No general Internet route for the restricted Database tier
- Least-privilege Security Groups
- Ubuntu 22.04 LTS Bastion host
- Ubuntu 22.04 LTS Web/Application VM
- Ubuntu 22.04 LTS dedicated Database VM
- Encrypted EC2 EBS root volumes
- IMDSv2 enforced on EC2
- Private Amazon S3 storage
- Amazon S3 Gateway VPC Endpoint
- Managed Amazon RDS PostgreSQL database
- Five least-privilege IAM roles
- Five CloudWatch security and operational alarms
- Regional EBS encryption by default

---

## Network Addressing

| Tier | CIDR | Purpose |
|---|---|---|
| VPC | `10.20.0.0/16` | MediCore cloud network |
| Public | `10.20.10.0/24` | Bastion |
| Private | `10.20.20.0/24` | Web/Application |
| Restricted | `10.20.30.0/24` | Database VM and primary RDS subnet |
| Restricted | `10.20.31.0/24` | Secondary RDS subnet |

Reserved EC2 private addresses:

- Bastion: `10.20.10.10`
- Web/Application VM: `10.20.20.10`
- Database VM: `10.20.30.10`

---

## Three-Tier Security Architecture

The logical MediCore architecture uses three security tiers:

1. Public
2. Private
3. Restricted

### Public Tier

The Bastion host provides the administrative entry point.

SSH access is restricted to the deployment administrator's current public IPv4 `/32`.

### Private Tier

The Web/Application VM:

- Has no public IPv4 address
- Is administered through the Bastion
- Has no general Internet route
- Can communicate only with specifically permitted downstream services

### Restricted Tier

The Database VM and managed RDS service operate within the restricted database tier.

Database connectivity is restricted to the Web/Application tier.

Neither the Database VM nor RDS is publicly accessible.

---

## Bastion Access Model

The Bastion host is the sole publicly addressable EC2 administrative entry point.

Inbound SSH:

- TCP 22
- Source: authorised administrator public IPv4 `/32`

The Web/Application and Database VMs have no public IPv4 addresses.

SSH access to private EC2 resources is performed using OpenSSH ProxyJump through the Bastion.

The SSH private key remains on the administrator workstation and is not copied onto the Bastion.

---

## EC2 Security

All EC2 instances use:

- Ubuntu 22.04 LTS
- Encrypted EBS root storage
- IMDSv2
- Dedicated Security Groups
- Least-privilege inbound and outbound rules

Current EC2 roles:

- `medicore-bastion`
- `medicore-web`
- `medicore-database`

---

## Security Group Model

### Bastion Security Group

Inbound:

- TCP 22 from administrator public IPv4 `/32`

Outbound:

- TCP 22 to Web/Application tier
- TCP 22 to Database tier

### Web/Application Security Group

Inbound:

- TCP 22 from Bastion private IPv4 only
- TCP 80 for HTTP application traffic
- TCP 443 for HTTPS application traffic

Outbound:

- TCP 5432 to the dedicated Database VM
- TCP 5432 to managed RDS
- TCP 443 to the Amazon S3 service prefix

### Database VM Security Group

Inbound:

- TCP 22 from Bastion private IPv4 only
- TCP 5432 from Web/Application private IPv4 only

Outbound:

- TCP 443 to the Amazon S3 service prefix for backup use

### RDS Security Group

Inbound:

- TCP 5432 from Web/Application private IPv4 only

No SSH access is permitted to RDS.

---

## S3 Private Storage

Amazon S3 is used for private static files and backups.

Implemented security controls:

- S3 Block Public Access enabled
- All four public-access protections enabled
- Bucket-owner-enforced object ownership
- ACLs disabled
- SSE-S3 server-side encryption
- AES-256 encryption
- Versioning enabled
- HTTP requests denied using `aws:SecureTransport`
- HTTPS/TLS required
- S3 Gateway VPC Endpoint
- Endpoint policy restricted to the MediCore bucket
- Security Group HTTPS egress restricted to the AWS S3 service prefix

Private resources therefore do not require a general Internet route to communicate with Amazon S3.

---

## Managed Database

Amazon RDS PostgreSQL is used as the managed clinical database service.

Configuration:

- Engine: PostgreSQL
- Instance class: `db.t3.micro`
- Private accessibility only
- Dedicated RDS Security Group
- TCP 5432 only from the Web/Application tier
- Encrypted storage
- Seven-day automated backup retention
- Point-in-time recovery capability
- DB subnet group spanning two Availability Zones

---

## AWS-Specific RDS Adaptation

The original architecture contained three physical subnets corresponding to the three security tiers.

Amazon RDS requires its DB subnet group to contain subnets spanning at least two Availability Zones.

A second restricted subnet was therefore introduced:

`10.20.31.0/24`

This subnet does not represent a new security tier.

It extends the existing restricted database tier into another Availability Zone while retaining:

- No public addressing
- No Internet Gateway route
- Restricted Security Group access

This adaptation is retained as B3 adaptability evidence and is referenced through Git history.

---

# A2 Security Controls

## IAM

Five assessed least-privilege IAM roles have been created:

1. `clinical-read-only`
2. `clinical-write`
3. `db-admin`
4. `monitoring-only`
5. `backup-operator`

### clinical-read-only

Permitted:

- List the `clinical/` S3 prefix
- Read clinical objects
- Read object versions

Not permitted:

- Upload
- Delete
- IAM administration
- Infrastructure administration

### clinical-write

Permitted:

- List the `clinical/` prefix
- Read clinical objects
- Upload clinical objects

Not permitted:

- Delete objects
- IAM administration
- General infrastructure administration

### db-admin

Permitted:

- Inspect RDS configuration
- Start the MediCore RDS instance
- Stop the MediCore RDS instance
- Reboot the MediCore RDS instance
- Create database snapshots

Not permitted:

- Delete the RDS database
- Administer IAM
- Modify the VPC

### monitoring-only

Permitted:

- View CloudWatch metrics
- View CloudWatch alarms
- View CloudWatch logs
- View relevant EC2 metadata
- View relevant RDS metadata

Not permitted:

- Modify infrastructure
- Modify IAM
- Start or terminate infrastructure

### backup-operator

Permitted:

- Read backup objects
- Write backup objects
- Inspect RDS snapshots
- Create RDS snapshots

Not permitted:

- Delete backup objects
- Delete the RDS database
- IAM administration

---

## IAM Security Model

The assessed IAM roles use customer-managed policies rather than broad administrator policies.

Permissions are separated according to operational responsibility.

IAM role assumption requires MFA.

The deployment identity used by Terraform is separate from the assessed operational IAM roles.

This separation ensures that infrastructure deployment privileges are not confused with day-to-day clinical, monitoring, database or backup permissions.

---

## Encryption at Rest

| Service | Control | Encryption |
|---|---|---|
| Bastion EBS | Encrypted root volume | AES-256 EBS encryption |
| Web EBS | Encrypted root volume | AES-256 EBS encryption |
| Database EBS | Encrypted root volume | AES-256 EBS encryption |
| Future EBS | Encryption by default | Enabled |
| S3 | SSE-S3 | AES-256 |
| RDS | Storage encryption | AES-256 |
| RDS automated backups | Inherits DB encryption | AES-256 |
| RDS snapshots | Inherits DB encryption | AES-256 |

---

## Encryption in Transit

### SSH

Administrative communication uses encrypted SSH.

Private EC2 administration occurs through SSH ProxyJump via the Bastion.

### Amazon S3

The S3 bucket policy explicitly denies requests where:

`aws:SecureTransport = false`

This requires HTTPS/TLS.

### Amazon RDS PostgreSQL

RDS PostgreSQL supports TLS connections.

The deployed PostgreSQL parameter configuration is verified during A2 to establish the value of:

`rds.force_ssl`

The final security evidence records the actual deployed value rather than assuming TLS configuration.

### Public Web TLS

Production TLS termination for the scalable Web/Application tier will be integrated with the Application Load Balancer architecture.

A trusted public certificate requires an appropriate DNS/domain and certificate validation workflow.

The deployment documentation therefore does not claim public ALB HTTPS termination until that control has actually been deployed and evidenced.

---

# A2 CloudWatch Monitoring

Five CloudWatch alarms are deployed.

| Alert ID | Resource | Metric | Threshold |
|---|---|---|---|
| A2-ALARM-01 | Bastion | `StatusCheckFailed` | >= 1 |
| A2-ALARM-02 | Web VM | `CPUUtilization` | >70% |
| A2-ALARM-03 | Database VM | `CPUUtilization` | >70% |
| A2-ALARM-04 | RDS | `CPUUtilization` | >70% |
| A2-ALARM-05 | RDS | `FreeStorageSpace` | <2 GiB |

Each CloudWatch alarm includes an incident-response identifier in its description.

These identifiers link monitoring events to the incident-response material used later in the assignment.

---

## Monitoring Response Model

### IRP-A2-01

Bastion status failure:

- Verify EC2 system and instance checks
- Preserve diagnostic evidence
- Determine whether failure is operational or security-related
- Escalate through the MediCore incident-response process

### IRP-A2-02

Web CPU threshold:

- Inspect workload
- Review unexpected application demand
- Check for abnormal or malicious activity
- Escalate when required

### IRP-A2-03

Database VM CPU threshold:

- Investigate database workload
- Inspect unexpected processes
- Confirm database availability
- Preserve evidence where suspicious activity is identified

### IRP-A2-04

RDS CPU threshold:

- Inspect database workload
- Review connections and performance
- Determine whether the event is operational or security-related
- Escalate where required

### IRP-A2-05

RDS storage threshold:

- Investigate unexpected storage growth
- Protect database availability
- Determine whether abnormal ingestion or malicious activity is occurring
- Escalate if clinical-data availability is threatened

---

## Repository Structure

- `/infrastructure` - Terraform Infrastructure-as-Code
- `/docker` - Docker configuration and vulnerability evidence
- `/kubernetes` - Kubernetes manifests
- `/screenshots` - deployment and security evidence
- `/analysis` - CloudWatch data analysis and Jupyter Notebook
- `/docs` - supporting technical documentation
- `/scripts` - supporting scripts

---

## Infrastructure Terraform Files

Current Terraform configuration includes:

- `versions.tf`
- `provider.tf`
- `variables.tf`
- `data.tf`
- `network.tf`
- `key-pair.tf`
- `security-groups.tf`
- `compute.tf`
- `storage.tf`
- `database.tf`
- `outputs.tf`
- `a2-data.tf`
- `a2-security.tf`
- `a2-iam.tf`
- `a2-monitoring.tf`
- `a2-outputs.tf`

Local-only Terraform files such as `terraform.tfvars`, state files and saved plan files are excluded from Git.

---

## Deployment Status

### A1 — Complete

- VPC deployed
- Initial three-tier network deployed
- Public Bastion subnet deployed
- Private Web/Application subnet deployed
- Restricted Database subnet deployed
- Bastion deployed
- Bastion SSH verified
- Web VM deployed
- Database VM deployed
- Web and Database private addressing verified
- Bastion-only private administration verified
- Direct Database access failure evidenced
- S3 deployed
- S3 public access blocked
- S3 AES-256 encryption enabled
- S3 TLS requirement enabled
- S3 Gateway Endpoint deployed
- RDS PostgreSQL deployed
- RDS private accessibility configured
- RDS encryption enabled
- Seven-day automated backups enabled
- Point-in-time recovery capability configured

### A2 — Complete

- Least-privilege Security Groups configured
- EBS encryption verified
- EBS encryption by default enabled
- S3 encryption verified
- S3 TLS control verified
- RDS encryption verified
- Five assessed IAM roles deployed
- Least-privilege IAM policies deployed
- Five CloudWatch alarms deployed
- Alarm thresholds documented
- Incident-response actions documented

### A3 — Next

- Multi-AZ Web/Application architecture
- Application Load Balancer
- HTTP `GET /` health check
- Auto Scaling Group
- Minimum capacity 2
- Maximum capacity 4
- CPU-based scale-out
- Three Availability Zones
- Failure simulation and traffic-rerouting evidence

### Later

- A4 Docker and Kubernetes
- A5 repository/evidence completion
- A6 CloudWatch monitoring analysis
- Deliverable B technical report
- Deliverable C Linux and data representation work

---

## Security of Repository

The repository does not contain:

- AWS passwords
- AWS access keys
- AWS secret keys
- AWS session tokens
- SSH private keys
- RDS passwords
- Terraform state
- Saved Terraform plans
- Sensitive `.tfvars`

The local SSH private key remains outside the repository under:

`~/.ssh/medicore_ed25519`

The RDS master password is held in the ignored local `terraform.tfvars` and Terraform state for this assignment environment.

---

## Deployment Methodology

The infrastructure is being implemented incrementally.

Major infrastructure stages are committed separately so Git history provides evidence of architectural progression and adaptation.

Completed stages include:

- Initial network
- Bastion
- Private application and database tiers
- Private storage
- Managed RDS
- Security and IAM controls
- CloudWatch monitoring

Each subsequent stage builds upon the previously validated Terraform state.

This supports repeatability, traceability and controlled infrastructure change.