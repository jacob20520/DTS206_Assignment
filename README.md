# MediCore Secure Clinical Cloud Infrastructure

## DTS206 — Virtualisation and Infrastructure

This repository contains the Infrastructure-as-Code, security controls, containerisation configuration, Kubernetes manifests, monitoring evidence and supporting documentation for the MediCore Health Systems secure clinical cloud infrastructure project.

MediCore Health Systems is a UK digital healthcare organisation supporting NHS services and managing sensitive clinical information.

The objective of this project is to design, deploy, secure and evaluate a cloud platform that provides:

- Network isolation
- Least-privilege access
- Encryption
- Secure administrative access
- Managed database services
- Monitoring
- High availability
- Auto Scaling
- Container security
- Kubernetes orchestration
- Vulnerability management
- Reproducible Infrastructure-as-Code

The primary cloud provider used is Amazon Web Services (AWS).

---

# Cloud Provider

## Amazon Web Services

Primary region:

`eu-west-2`

Region name:

`Europe (London)`

The London region was selected because the project concerns a UK healthcare organisation and keeping cloud resources within a UK AWS region supports the wider data-governance and residency strategy discussed in the technical report.

---

# Infrastructure as Code

Terraform is the primary Infrastructure-as-Code tool.

AWS infrastructure is defined within:

`/infrastructure`

Terraform was selected because it provides:

- Declarative infrastructure definitions
- Reproducible deployment
- Dependency management
- State management
- Plan-before-apply workflow
- Version control integration
- AWS provider support
- Infrastructure change visibility

The AWS Management Console is not used as the primary deployment method.

AWS CLI commands are used for:

- Deployment verification
- Security-control verification
- Operational testing
- Monitoring checks
- Evidence collection

---

# Repository Structure

```text
medicore-cloud/
├── README.md
├── .gitignore
│
├── infrastructure/
│   ├── versions.tf
│   ├── provider.tf
│   ├── variables.tf
│   ├── terraform.tfvars.example
│   ├── data.tf
│   ├── network.tf
│   ├── key-pair.tf
│   ├── security-groups.tf
│   ├── compute.tf
│   ├── storage.tf
│   ├── database.tf
│   ├── outputs.tf
│   │
│   ├── a2-data.tf
│   ├── a2-security.tf
│   ├── a2-iam.tf
│   ├── a2-monitoring.tf
│   ├── a2-outputs.tf
│   │
│   ├── a3-variables.tf
│   ├── a3-network.tf
│   ├── a3-security-groups.tf
│   ├── a3-load-balancer.tf
│   ├── a3-autoscaling.tf
│   └── a3-outputs.tf
│
├── docker/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── .dockerignore
│   ├── pyproject.toml
│   ├── vulnerability-notes.md
│   ├── .trivyignore.yaml
│   ├── .grype.yaml
│   │
│   ├── src/
│   │   └── medicore_app/
│   │       └── __init__.py
│   │
│   ├── scans/
│   │   ├── trivy-baseline.txt
│   │   ├── trivy-final.txt
│   │   ├── grype-baseline.txt
│   │   └── grype-final.txt
│   │
│   ├── scripts/
│   │   └── generate-vulnerability-notes.py
│   │
│   └── secrets/
│       ├── .gitkeep
│       └── README.md
│
├── kubernetes/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── README.md
│
├── screenshots/
│
├── analysis/
│
├── docs/
│   ├── a2-security-controls.md
│   └── a3-scalability-ha.md
│
└── scripts/
```

---

# Architecture Overview

The MediCore infrastructure uses a logically separated three-tier architecture.

```text
                         INTERNET
                            |
                            |
              +-------------+-------------+
              |                           |
              v                           v
       Bastion Host                Application Load
       Public Admin                   Balancer
          Entry                         |
              |                         |
              | SSH                     |
              |                         |
              |                 +-------+-------+
              |                 |       |       |
              |                 v       v       v
              |               AZ1     AZ2     AZ3
              |                |       |       |
              |                +--- Web ASG ---+
              |                         |
              |                         |
              +------ Admin ------------+
                                        |
                                        |
                                  PostgreSQL
                                        |
                                        v
                                Restricted Tier
                                        |
                              +---------+---------+
                              |                   |
                              v                   v
                         Database VM             RDS

Private Web/Database resources
        |
        |
        v
S3 Gateway VPC Endpoint
        |
        v
Private MediCore S3 Bucket
```

---

# Network Architecture

The logical security tiers are:

1. Public
2. Private
3. Restricted

## VPC

CIDR:

`10.20.0.0/16`

## Initial A1 Subnets

| Tier | CIDR | Purpose |
|---|---|---|
| Public | `10.20.10.0/24` | Bastion administration |
| Private | `10.20.20.0/24` | Original Web/Application tier |
| Restricted | `10.20.30.0/24` | Database tier |
| Restricted | `10.20.31.0/24` | Secondary RDS subnet |

The additional `10.20.31.0/24` subnet is an AWS-specific adaptation because Amazon RDS requires a DB subnet group spanning at least two Availability Zones.

It remains part of the same logical restricted database tier.

---

# A3 Multi-AZ Application Subnets

A3 expanded the physical network so that the scalable application tier could operate across three Availability Zones.

## Public ALB subnets

- `10.20.11.0/24`
- `10.20.12.0/24`
- `10.20.13.0/24`

## Private Web subnets

- `10.20.21.0/24`
- `10.20.20.0/24`
- `10.20.22.0/24`

The additional physical subnets do not introduce additional logical security tiers.

They provide Availability Zone redundancy while preserving the Public / Private / Restricted security model.

---

# A1 — Cloud Architecture

## Bastion Host

The Bastion host is the administrative entry point for EC2 resources.

Reserved private IPv4 address:

`10.20.10.10`

Controls include:

- Ubuntu 22.04 LTS
- Encrypted EBS
- IMDSv2 required
- Public IPv4 address
- SSH TCP 22
- SSH source restricted to the administrator IPv4 `/32`
- No SSH private key stored on the Bastion

Private hosts are accessed using OpenSSH ProxyJump.

---

# Web/Application VM

Original A1 Web private IPv4:

`10.20.20.10`

Controls include:

- No public IPv4 address
- Private subnet placement
- Encrypted EBS
- IMDSv2
- SSH only from the Bastion
- Database connectivity only where explicitly permitted
- S3 access through the private Gateway Endpoint

The original VM is retained as evidence of the initial A1 three-tier deployment.

A3 later introduces the scalable Web tier.

---

# Database VM

Reserved private IPv4:

`10.20.30.10`

Controls include:

- Restricted subnet
- No public IPv4
- No general Internet route
- Encrypted EBS
- IMDSv2
- SSH only from Bastion
- PostgreSQL TCP 5432 accepted only from the Web tier

Direct Internet connectivity to the Database VM is deliberately unavailable.

---

# Private Amazon S3 Storage

Amazon S3 is used for private static content and backup-related storage.

Security controls include:

- Block Public Access
- Bucket-owner-enforced object ownership
- ACLs disabled
- SSE-S3
- AES-256 server-side encryption
- Versioning
- TLS-only bucket policy
- S3 Gateway VPC Endpoint
- Endpoint policy restricted to the MediCore bucket

The S3 bucket is not intended to operate as a public website or public storage location.

---

# S3 Gateway Endpoint

The private and restricted tiers do not have a general Internet route.

An Amazon S3 Gateway VPC Endpoint therefore provides private routing to S3.

This allows authorised workloads to reach S3 without requiring:

- Public IP addresses
- NAT Gateway
- General Internet access

---

# Amazon RDS PostgreSQL

The managed clinical database uses Amazon RDS PostgreSQL.

Controls include:

- PostgreSQL
- Private accessibility
- `db.t3.micro` assignment instance
- 20 GiB GP3 storage
- Encrypted storage
- Seven-day automated backup retention
- Point-in-time recovery capability
- Restricted DB subnet group
- No public database endpoint
- TCP 5432 accepted only from authorised Web/Application resources

The assignment deployment uses a low-cost specification.

A production clinical deployment would require capacity, backup, resilience and performance sizing based on workload requirements.

---

# A2 — Security Controls

## Security Groups

### Bastion

Inbound:

- TCP 22 from administrator `/32`

Outbound:

- SSH to authorised private administration targets

### Original Web VM

Inbound:

- TCP 22 from Bastion
- TCP 80/443 according to the A2 evidence requirements

Outbound:

- TCP 5432 to database resources
- HTTPS to S3 through the permitted AWS S3 prefix

### Database VM

Inbound:

- TCP 22 from Bastion
- TCP 5432 from Web/Application tier

### RDS

Inbound:

- TCP 5432 from authorised Web/Application resources

### Scalable A3 Web Tier

Inbound:

- Application traffic from the ALB Security Group
- SSH from Bastion only

The scalable Web instances are not directly exposed to Internet application traffic.

---

# Encryption at Rest

| Service | Control |
|---|---|
| EC2 | Encrypted EBS |
| Future EBS volumes | Regional encryption-by-default |
| S3 | SSE-S3 AES-256 |
| RDS | Encrypted database storage |
| RDS backups | Inherit database encryption |
| RDS snapshots | Inherit database encryption |

---

# Encryption in Transit

## SSH

Administrative access uses SSH.

Private instances are administered through the Bastion using ProxyJump.

## S3

The S3 bucket policy denies requests when:

`aws:SecureTransport = false`

This requires TLS/HTTPS.

## RDS

PostgreSQL TLS support and the deployed `rds.force_ssl` configuration are verified as part of the A2 security evidence.

## Application Layer

A3 introduced the Application Load Balancer.

The assignment demonstration uses HTTP for the explicitly assessed `GET /` health probe and availability demonstration.

A production clinical system would terminate trusted TLS at the public application boundary and redirect plaintext HTTP to HTTPS.

---

# IAM Roles

Five assessed operational IAM roles are implemented:

1. `clinical-read-only`
2. `clinical-write`
3. `db-admin`
4. `monitoring-only`
5. `backup-operator`

These roles use customer-managed least-privilege policies rather than general administrator permissions.

---

## clinical-read-only

Permitted:

- List the relevant clinical S3 prefix
- Read clinical objects
- Read object versions

Not permitted:

- Write clinical objects
- Delete objects
- IAM administration
- General infrastructure administration

---

## clinical-write

Permitted:

- List relevant clinical objects
- Read clinical objects
- Upload clinical objects

Not permitted:

- Delete clinical data
- General IAM administration
- General AWS administration

---

## db-admin

Permitted:

- Inspect RDS
- Start RDS
- Stop RDS
- Reboot RDS
- Create appropriate RDS snapshots

Not permitted:

- Delete the database
- IAM administration
- General network administration

---

## monitoring-only

Permitted:

- Read CloudWatch metrics
- Read alarms
- Read CloudWatch Logs
- Inspect relevant EC2 and RDS metadata

Not permitted:

- Modify infrastructure
- Terminate infrastructure
- Modify IAM

---

## backup-operator

Permitted:

- Read/write authorised backup storage
- Inspect RDS snapshots
- Create approved snapshots

Not permitted:

- Delete the clinical database
- General IAM administration

---

# CloudWatch Monitoring

A2 introduced five CloudWatch alarms.

| Alert | Resource | Metric | Threshold |
|---|---|---|---|
| A2-ALARM-01 | Bastion | `StatusCheckFailed` | >= 1 |
| A2-ALARM-02 | Web VM | `CPUUtilization` | >70% |
| A2-ALARM-03 | Database VM | `CPUUtilization` | >70% |
| A2-ALARM-04 | RDS | `CPUUtilization` | >70% |
| A2-ALARM-05 | RDS | `FreeStorageSpace` | <2 GiB |

Alarm descriptions link monitoring conditions to documented incident-response actions.

---

# A3 — Scalability and High Availability

A3 converts the application layer from a single Web VM into a scalable multi-Availability-Zone application architecture.

It uses:

- Application Load Balancer
- Target Group
- Launch Template
- Auto Scaling Group
- Three Availability Zones
- Three private Web subnets
- Three public ALB subnets
- CloudWatch scale-out alarm

---

# Application Load Balancer

The ALB is Internet-facing and operates across three Availability Zones.

The scalable Web servers remain private.

Traffic flow:

```text
Internet
   |
   v
Application Load Balancer
   |
   v
Private Web ASG
```

The ALB Security Group accepts public application traffic.

The private Web Security Group accepts backend application traffic only from the ALB Security Group.

---

# ALB Health Check

Health check configuration:

- Protocol: HTTP
- Path: `/`
- Expected response: `200`
- Backend port: `8080`

Healthy targets remain eligible to receive requests.

Unhealthy targets are removed from normal load-balancer routing.

---

# Auto Scaling

The scalable Web Auto Scaling Group uses:

- Minimum capacity: `2`
- Maximum capacity: `4`
- Initial demonstration capacity: `3`
- Three Availability Zones

The initial capacity of three was used to produce clear three-AZ evidence.

---

# CPU Scale-Out

The scale-out condition is:

`CPUUtilization > 70%`

for:

`3 consecutive one-minute periods`

Detailed EC2 monitoring provides the one-minute CPU metrics required to represent this threshold accurately.

When the alarm enters the ALARM state, the scaling policy increases capacity by one instance subject to the maximum ASG capacity.

---

# High-Availability Failure Demonstration

High availability was demonstrated by deliberately terminating one ASG-managed Web instance without decrementing the desired capacity.

Observed behaviour:

1. One Web instance was terminated.
2. ALB traffic continued through healthy targets.
3. The terminated target was removed from service.
4. Auto Scaling detected missing capacity.
5. Auto Scaling launched replacement capacity.
6. The replacement passed health checks.
7. Healthy target capacity was restored.

This provides evidence of application resilience and automatic recovery.

---

# A4 — Containerisation

## Application

A small Python Flask/Gunicorn application is used to demonstrate the secure container configuration.

Endpoints include:

`/`

and:

`/health`

The health endpoint is used by Docker and Kubernetes.

---

# Multi-Stage Docker Build

The Dockerfile contains:

## Stage 1 — Builder

The builder:

- Uses Python 3.11
- Installs build dependencies
- Builds Python wheels
- Produces the application runtime artefacts

## Stage 2 — Production

The production stage:

- Uses `python:3.11-slim`
- Receives built artefacts from the builder
- Does not copy the original application source tree directly
- Creates `appuser`
- Uses UID `1001`
- Executes the application as non-root

---

# Docker Runtime Hardening

Docker Compose applies:

- Non-root UID 1001
- Read-only root filesystem
- Memory limit: 256 MiB
- CPU limit: 0.5 CPU
- PID limit
- `/tmp` tmpfs
- `noexec`
- `nosuid`
- Linux capabilities dropped
- `no-new-privileges`
- Localhost-only demonstration binding
- Health check
- Docker secret

These controls reduce the effects of process compromise and accidental resource exhaustion.

---

# Docker Secrets

The database demonstration password is not stored directly in a Compose environment variable.

The local source file is:

`docker/secrets/db_password.txt`

The file is explicitly ignored by Git.

Docker mounts it as:

`/run/secrets/db_password`

Only the secret file location is placed in the environment.

The secret value itself is not committed to Git.

---

# Container Vulnerability Management

The production image is independently scanned using:

- Trivy
- Grype

Raw scan results are retained in:

`docker/scans/`

The vulnerability-management workflow contains:

1. Baseline image scan
2. Identification of vulnerabilities
3. Investigation of package origin
4. Remediation where supported fixes exist
5. Rebuild
6. Final scan
7. Documentation of remaining upstream findings
8. Explicit vulnerability risk review

Detailed results are documented in:

`docker/vulnerability-notes.md`

---

# Trivy and Grype Comparison

Trivy and Grype produced different results against the same image.

This is useful because vulnerability scanners may use:

- Different advisory databases
- Different package-matching logic
- Different severity classifications
- Different vulnerability metadata

Using both scanners therefore provided broader visibility than relying on a single scanner.

The raw scanner evidence is retained rather than replacing the original results with only filtered results.

---

# Upstream Base-Image Vulnerabilities

During A4, CRITICAL vulnerabilities were identified in packages inherited from the required `python:3.11-slim` base image.

The same issues were tested against the upstream base image to establish that they were inherited rather than introduced by the MediCore Python application.

Where the stable upstream distribution did not yet provide a supported package fix, the finding was documented in `vulnerability-notes.md` together with:

- CVE
- Package
- Installed version
- Available fix information
- Applicability
- Compensating controls
- Accepted-risk reasoning
- Scanner differences

Specific reviewed exceptions are maintained rather than using a blanket severity suppression.

The raw scan reports remain available for audit.

---

# Docker User Namespace Remapping

Docker user namespace remapping was enabled at daemon level.

A separate disposable test container was used to verify the control.

Evidence demonstrated:

```text
Inside container:
UID 0

Same process on host:
unprivileged subordinate UID
```

This prevents container UID 0 from mapping directly to host UID 0.

The actual MediCore production container remains non-root and executes as UID 1001.

---

# Kubernetes

Minikube is used for the local Kubernetes demonstration.

The Kubernetes configuration is stored under:

`/kubernetes`

Resources include:

- Deployment
- NodePort Service

---

# Kubernetes Deployment

The application Deployment uses:

- Replicas: `2`
- `runAsNonRoot: true`
- `runAsUser: 1001`
- `runAsGroup: 1001`
- `readOnlyRootFilesystem: true`
- `allowPrivilegeEscalation: false`
- `RuntimeDefault` seccomp
- All Linux capabilities dropped
- CPU requests
- CPU limits
- Memory requests
- Memory limits
- Liveness probe
- Readiness probe
- Kubernetes Secret
- Memory-backed `/tmp`

---

# Kubernetes Health Probes

Both probes use:

`GET /health`

The liveness probe determines whether the container should be restarted.

The readiness probe determines whether the Pod should receive Service traffic.

---

# Kubernetes Service

The application is exposed within the Minikube demonstration using:

`type: NodePort`

NodePort:

`30080`

Service port:

`8080`

Container port:

`8080`

---

# Kubernetes Self-Healing

The Deployment specifies:

`replicas: 2`

Self-healing was tested by:

1. Recording both original Pod names.
2. Starting `kubectl get pods --watch`.
3. Deleting one Pod.
4. Observing the original Pod terminate.
5. Observing a replacement Pod appear.
6. Confirming the replacement had a different generated Pod name.
7. Confirming the replica count returned to two.
8. Confirming the application remained healthy.

Kubernetes events were retained as additional evidence of the replacement process.

---

# Security Rationale

Containerisation does not automatically make an application secure.

The NCSC recommends running containers using low-privilege users, avoiding privileged containers, preferring read-only filesystems, reducing unnecessary capabilities, applying network controls and securing the container runtime.

The MediCore Docker and Kubernetes controls implement these principles through:

- UID 1001
- Read-only filesystems
- Dropped capabilities
- Resource limits
- Secret-file handling
- Health probes
- User namespace isolation

OWASP container guidance similarly recommends explicit non-root users, resource limits, read-only filesystems, vulnerability scanning and user namespace controls.

These principles influenced the A4 implementation rather than relying on Docker's default runtime configuration alone.

---

# NHS Data Security Context

The NHS Data Security and Protection Toolkit is used by organisations with access to NHS patient data and systems to provide assurance that good data-security practices are being followed.

MediCore's scenario involves NHS-linked clinical information, so security controls are designed to provide auditable evidence rather than relying solely on undocumented configuration.

Evidence in this repository includes:

- Infrastructure configuration
- Encryption configuration
- IAM policies
- Security Groups
- Monitoring
- Vulnerability scans
- Kubernetes security controls
- Git history
- Named screenshots

---

# Tools and Rationale

## AWS

AWS provides the project's cloud networking, compute, object storage, managed database, monitoring, load balancing and scaling services.

The London AWS region supports the project's UK-hosted architecture.

---

## Terraform

Terraform was selected instead of manually creating all infrastructure in the AWS Management Console because Infrastructure-as-Code provides:

- Repeatability
- Version control
- Reviewable configuration
- Reproducible deployment
- Change planning
- Dependency management

This supports the assignment's requirement to provide auditable infrastructure evidence.

---

## Git and GitHub

Git provides local version control.

GitHub provides the remote repository used for the assignment.

Git history demonstrates progression from:

- A1 architecture
- A2 security
- A3 scalability
- A4 containerisation
- A5 documentation
- A6 analysis

Sensitive local files are excluded through `.gitignore`.

---

## Docker

Docker is used to package the MediCore demonstration application and its dependencies into a repeatable image.

Docker allows runtime security controls to be explicitly configured and tested.

---

## Docker Compose

Docker Compose is used to represent local runtime configuration as code.

It makes settings such as:

- Memory
- CPU
- Read-only filesystem
- tmpfs
- Security options
- Secrets
- Health checks

reproducible.

---

## Trivy

Trivy is used to identify vulnerabilities in operating-system and application packages within the image.

It provides one of the two independent vulnerability assessments required by the assignment.

---

## Grype

Grype is used as a second independent image scanner.

Comparing Grype with Trivy demonstrated that two scanners can report different vulnerabilities and severities against the same container image.

This provides stronger security evidence than relying on one scanner.

---

## Kubernetes

Kubernetes demonstrates declarative orchestration of the containerised service.

The Deployment controller provides self-healing by continuously reconciling actual Pod state against desired state.

---

## Minikube

Minikube provides a local Kubernetes environment suitable for demonstrating:

- Deployments
- Services
- NodePort
- Health probes
- Security contexts
- Pod self-healing

without introducing a separate managed Kubernetes cloud service solely for assignment evidence.

---

## CloudWatch

CloudWatch provides AWS-native monitoring of EC2 and RDS resources.

Using AWS-native metrics reduces the requirement to deploy an additional monitoring platform for the infrastructure demonstration.

A6 uses monitoring data as an analytical data source.

---

# Secure Container Guidance

The container security configuration is informed by recognised security guidance.

The National Cyber Security Centre recommends:

- Secure container image supply chains
- Low-privilege container users
- Read-only filesystems
- Avoiding unnecessary privilege
- Secure runtime configuration
- Monitoring
- Timely vulnerability remediation

OWASP's Docker Security guidance similarly recommends:

- Avoiding root containers
- User namespace controls
- Resource limits
- Read-only filesystems
- Vulnerability scanning

These recommendations align directly with the controls demonstrated in A4.

---

# Deployment From Scratch

## Prerequisites

A deployment workstation requires:

- Linux
- Git
- AWS CLI
- Terraform
- OpenSSH
- Docker Engine
- Docker Compose
- Trivy
- Grype
- kubectl
- Minikube
- Python 3
- GitHub access

---

# Clone Repository

Run on the local PC:

```bash
git clone <YOUR-GITHUB-REPOSITORY-URL>
cd medicore-cloud
```

---

# AWS Authentication

Authenticate using an authorised AWS deployment identity.

Do not place AWS access keys inside Terraform files.

For an AWS CLI login-based configuration:

```bash
aws login
```

Verify:

```bash
aws sts get-caller-identity
```

The deployment region is:

```text
eu-west-2
```

---

# Create SSH Key

If the MediCore SSH key does not already exist:

```bash
ssh-keygen \
  -t ed25519 \
  -f ~/.ssh/medicore_ed25519 \
  -C "medicore"
```

The private key must remain outside Git.

---

# Terraform Variables

Move into:

```bash
cd infrastructure
```

Create the local variables file from the example:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Update:

```text
admin_cidr
db_master_password
```

with local values.

`admin_cidr` should use the administrator's current public IPv4 address as a `/32`.

Do not commit:

```text
terraform.tfvars
```

---

# Initialise Terraform

From `/infrastructure`:

```bash
terraform init
```

Then:

```bash
terraform fmt -check
terraform validate
```

---

# Review Terraform Plan

```bash
terraform plan -out=deployment.tfplan
```

Review the plan before applying it.

Confirm that no unexpected existing resources are being destroyed or replaced.

---

# Deploy AWS Infrastructure

```bash
terraform apply deployment.tfplan
```

Terraform creates dependencies in the required technical order.

Operational verification should then confirm:

1. VPC and subnet configuration
2. Bastion accessibility
3. Private Web access through Bastion
4. Database isolation
5. Private S3 configuration
6. RDS configuration
7. IAM and monitoring controls
8. ALB
9. Auto Scaling
10. Multi-AZ operation

---

# Verify Terraform State

```bash
terraform plan
```

A stable deployment should return:

```text
No changes. Your infrastructure matches the configuration.
```

---

# Docker Deployment

Return to repository root:

```bash
cd ..
cd docker
```

Create the local secret:

```bash
openssl rand -hex 32 > secrets/db_password.txt
```

Protect it appropriately for the local runtime.

The secret file must remain ignored by Git.

Build:

```bash
docker compose build --pull --no-cache
```

Start:

```bash
docker compose up -d
```

Check:

```bash
docker compose ps
```

Health test:

```bash
curl -i http://127.0.0.1:8080/health
```

---

# Vulnerability Scanning

Run Trivy:

```bash
trivy image medicore-a4:1.0
```

Run Grype:

```bash
grype docker:medicore-a4:1.0
```

Detailed baseline and final evidence is stored under:

`docker/scans`

All findings must be reviewed and recorded in:

`docker/vulnerability-notes.md`

---

# Kubernetes Deployment

Before enabling Docker user namespace remapping, start Minikube:

```bash
minikube start \
  --driver=docker \
  --cpus=2 \
  --memory=2048
```

Verify:

```bash
kubectl get nodes
```

Load the local image:

```bash
minikube image load medicore-a4:1.0
```

From repository root, create the Kubernetes Secret:

```bash
kubectl create secret generic medicore-db-password \
  --from-file=db_password=docker/secrets/db_password.txt \
  --dry-run=client \
  -o yaml \
  | kubectl apply -f -
```

Deploy:

```bash
kubectl apply \
  -f kubernetes/deployment.yaml \
  -f kubernetes/service.yaml
```

Check:

```bash
kubectl rollout status deployment/medicore-a4
```

Then:

```bash
kubectl get pods -l app=medicore-a4
```

Two Pods should become ready.

---

# Kubernetes Self-Healing Test

Record the initial Pods:

```bash
kubectl get pods -l app=medicore-a4
```

Start watch mode:

```bash
kubectl get pods \
  -l app=medicore-a4 \
  --watch
```

In another terminal, select one Pod:

```bash
POD_TO_DELETE=$(kubectl get pods \
  -l app=medicore-a4 \
  -o jsonpath='{.items[0].metadata.name}')
```

Delete:

```bash
kubectl delete pod "$POD_TO_DELETE"
```

The Deployment should create a replacement with a different generated Pod name.

---

# User Namespace Remapping

User namespace remapping is a host-level Docker security control.

The assignment evidence demonstrates that a process with:

```text
UID 0
```

inside a disposable container maps to an unprivileged subordinate UID on the host.

The production MediCore application still runs as UID:

```text
1001
```

---

# Evidence

Deployment evidence is stored under:

`/screenshots`

Screenshot files are named according to the component and test they demonstrate.

Examples:

```text
a1-bastion-ssh
a2-five-iam-roles
a3-traffic-continues-during-failure
a4-kubernetes-self-healing-different-pod
```

Screenshots contain only evidence produced from the student's own deployed environment.

Passwords, tokens, access keys and private SSH keys must never appear in screenshots.

---

# Repository Security

The repository must not contain:

- AWS access keys
- AWS secret access keys
- AWS session tokens
- Passwords
- RDS master passwords
- Docker secret values
- SSH private keys
- Terraform state
- Saved Terraform plans
- Local `.tfvars`
- `.env` secrets

Relevant files are excluded through `.gitignore`.

---

# A1 Status — Complete

- VPC
- Three logical security tiers
- Bastion Host
- Private Web VM
- Restricted Database VM
- SSH ProxyJump
- Direct private-access failure test
- Private S3 bucket
- S3 Gateway Endpoint
- RDS PostgreSQL
- Encryption
- Seven-day RDS backups
- Point-in-time recovery capability

---

# A2 Status — Complete

- Least-privilege Security Groups
- EBS encryption
- EBS encryption-by-default
- S3 AES-256
- S3 TLS-only policy
- RDS encryption
- RDS TLS verification
- Five IAM roles
- Customer-managed IAM policies
- Five CloudWatch alarms
- Incident-response mapping

---

# A3 Status — Complete

- Application Load Balancer
- ALB subnets across three Availability Zones
- Private scalable Web tier across three Availability Zones
- Auto Scaling Group
- Minimum capacity 2
- Maximum capacity 4
- CPU >70% for three minutes scaling rule
- HTTP `GET /` health check returning 200
- Healthy target verification
- CPU scale-out demonstration
- Application failure simulation
- Traffic rerouting
- Automatic replacement
- Three-AZ recovery evidence

---

# A4 Status — Complete

- Multi-stage Dockerfile
- `python:3.11-slim`
- Built artefacts transferred between stages
- Non-root `appuser`
- UID 1001
- Read-only root filesystem
- 256 MiB memory limit
- 0.5 CPU limit
- `/tmp` tmpfs
- `noexec`
- `nosuid`
- Linux capabilities dropped
- `no-new-privileges`
- Docker secret
- Trivy
- Grype
- Vulnerability documentation
- Scanner comparison
- Docker user namespace remapping
- Kubernetes Deployment
- Two replicas
- CPU and memory requests/limits
- Liveness probe
- Readiness probe
- Non-root security context
- NodePort Service
- Kubernetes self-healing
- Replacement Pod with different name
- Kubernetes events evidence

---

# A5 Status — In Progress

A5 performs the final repository and documentation audit.

Required work includes:

- Repository structure verification
- README reproduction audit
- Screenshot naming audit
- Git history verification
- Secret-leakage checks
- Full CVE documentation check
- Tools and rationale review
- Harvard reference review
- AI Declaration review

---

# A6 Status — Next

A6 will add:

- Jupyter Notebook
- `requirements.txt`
- Monitoring dataset
- CPU/memory visualisation
- Failed-login visualisation
- Storage or other justified visualisation
- Analytical technique
- Written interpretation
- Data provenance
- Exported chart images

---

# AI Declaration

Generative AI tools were used during the development of this project to assist with planning, explanation of technical concepts, troubleshooting, review of configuration, and drafting supporting documentation.

All infrastructure commands, Terraform configurations, Docker configuration, vulnerability scans, Kubernetes deployments and evidence were executed, reviewed and tested by the student in the student's own environment.

AI-generated suggestions were not treated as automatically correct. Configuration was checked against the assignment requirements, actual deployment behaviour, command output and relevant primary or authoritative technical guidance.

The student retains responsibility for the submitted work and must be able to explain the configuration and decisions contained within the repository.

If the University-provided submission template contains a specific AI Declaration form or wording, that official declaration should be completed in addition to this repository statement.

---

# References

National Cyber Security Centre (2024) *Using containerisation: Building Container Images*. National Cyber Security Centre. Accessed: 25 August 2026.

National Cyber Security Centre (2024) *Using containerisation: Running Containers*. National Cyber Security Centre. Accessed: 25 August 2026.

National Cyber Security Centre (2024) *Using containerisation: Containerisation in the Cloud*. National Cyber Security Centre. Accessed: 25 August 2026.

OWASP Foundation (2026) *Docker Security Cheat Sheet*. OWASP Cheat Sheet Series. Accessed: 25 August 2026.

NHS England (2026) *Data Security and Protection Toolkit*. Accessed: 25 August 2026.

HashiCorp (2026) *Terraform Documentation*. HashiCorp. Accessed: 25 August 2026.

Amazon Web Services (2026) *AWS Documentation*. Amazon Web Services. Accessed: 25 August 2026.

Docker Inc. (2026) *Docker Documentation*. Docker Inc. Accessed: 25 August 2026.

Kubernetes Authors (2026) *Kubernetes Documentation*. Cloud Native Computing Foundation. Accessed: 25 August 2026.

---

# Academic and Security Note

This repository represents an academic assignment environment.

The AWS specifications used for cost-controlled demonstration are not presented as a complete production NHS architecture.

A production deployment would require further work including:

- Formal threat modelling
- Full NHS DSPT assessment
- Data Protection Impact Assessment
- Production TLS certificate management
- Managed secrets
- Enterprise identity federation
- Centralised audit logging
- SIEM integration
- Multi-AZ managed database resilience
- Production backup testing
- Disaster-recovery planning
- Vulnerability-management SLAs
- Secure CI/CD
- Container registry controls
- Runtime threat detection
- Formal penetration testing
- Capacity and performance testing