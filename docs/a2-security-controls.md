# A2 Security Controls

## Overview

This document records the security controls implemented for MediCore Health Systems as part of DTS206 Deliverable A2.

The controls use defence in depth, least privilege, encryption, network segmentation and cloud-native monitoring.

---

## Security Group Model

### Bastion

Inbound:

- TCP 22 from the authorised administrator public IPv4 /32 only.

Outbound:

- TCP 22 to the Web/Application VM private IPv4 only.
- TCP 22 to the Database VM private IPv4 only.

The Bastion is the only EC2 administration entry point exposed to the public Internet.

### Web/Application Tier

Inbound:

- TCP 22 from the Bastion private IPv4 only.
- TCP 80 permitted for application HTTP traffic.
- TCP 443 permitted for application HTTPS traffic.

Outbound:

- TCP 5432 to the dedicated Database VM.
- TCP 5432 to managed RDS.
- TCP 443 to the Amazon S3 service prefix.

The Web/Application instance has no public IPv4 address and its subnet has no general Internet route.

### Dedicated Database VM

Inbound:

- TCP 22 from the Bastion private IPv4 only.
- TCP 5432 from the Web/Application VM private IPv4 only.

Outbound:

- TCP 443 to the Amazon S3 service prefix for backup use.

The Database VM has no public IPv4 address and no general Internet route.

### Managed RDS

Inbound:

- TCP 5432 from the Web/Application VM private IPv4 only.

No SSH access is permitted to RDS.

RDS is configured as not publicly accessible.

---

## Encryption at Rest

| Service | Control | Encryption |
|---|---|---|
| Bastion EBS | Encrypted root volume | AES-256 through Amazon EBS encryption |
| Web EBS | Encrypted root volume | AES-256 through Amazon EBS encryption |
| Database EBS | Encrypted root volume | AES-256 through Amazon EBS encryption |
| Future EBS | EBS encryption by default | Enabled |
| S3 | SSE-S3 | AES-256 |
| RDS | Storage encryption | AES-256 |
| RDS backups | Inherit RDS encryption | AES-256 |
| RDS snapshots | Inherit RDS encryption | AES-256 |

---

## Encryption in Transit

### Administrative SSH

Administrative access uses SSH.

The Bastion is accessed from the authorised administrator address.

Web and Database administration occurs using SSH ProxyJump through the Bastion.

### Amazon S3

The S3 bucket policy explicitly denies requests where:

`aws:SecureTransport = false`

This prevents plaintext HTTP access and requires HTTPS/TLS.

Private Web and Database workloads reach S3 through an S3 Gateway VPC Endpoint rather than general Internet access.

### Amazon RDS PostgreSQL

RDS PostgreSQL supports TLS connections.

The deployed `rds.force_ssl` value must be verified as part of A2 evidence.

For PostgreSQL 15 and later, AWS enables `rds.force_ssl` by default.

The application must use TLS when connecting to the managed PostgreSQL database.

### Web/Application HTTPS

TCP 443 is permitted by the Web security-group configuration.

Production-quality TLS termination will be implemented at the Application Load Balancer during A3.

The A2 report must not falsely claim that ALB TLS has been deployed before the A3 implementation is complete.

---

# IAM Roles

## clinical-read-only

Purpose:

Allow authorised clinical personnel or applications to retrieve clinical objects without modifying them.

Permissions:

- List the S3 `clinical/` prefix.
- Read clinical objects and object versions.

Explicitly excluded:

- PutObject.
- DeleteObject.
- IAM administration.
- Infrastructure administration.

Least-privilege justification:

Read-only personnel do not require modification or deletion permissions. Removing write permissions reduces the impact of compromised credentials and accidental alteration.

---

## clinical-write

Purpose:

Allow approved workflows to read and create/update clinical objects.

Permissions:

- List the S3 `clinical/` prefix.
- Read clinical objects.
- Upload clinical objects.

Explicitly excluded:

- DeleteObject.
- IAM administration.
- Infrastructure administration.

Least-privilege justification:

Write workflows require upload access but routine deletion is not required. Object deletion is therefore excluded.

---

## db-admin

Purpose:

Operational administration of the MediCore managed RDS database.

Permissions:

- View RDS configuration.
- Start the MediCore DB.
- Stop the MediCore DB.
- Reboot the MediCore DB.
- Create MediCore DB snapshots.

Explicitly excluded:

- DeleteDBInstance.
- Public-network changes.
- IAM administration.
- VPC administration.

Least-privilege justification:

Operational administrators need lifecycle and recovery functions but do not require unrestricted AWS administration or permission to delete the production database.

---

## monitoring-only

Purpose:

Permit security and operational monitoring without infrastructure modification.

Permissions:

- View CloudWatch metrics.
- View CloudWatch alarms.
- View CloudWatch logs.
- View EC2 metadata.
- View RDS metadata.

Explicitly excluded:

- Modify alarms.
- Start or terminate EC2.
- Modify RDS.
- Change IAM.

Least-privilege justification:

Monitoring personnel require visibility but do not require configuration-changing permissions.

---

## backup-operator

Purpose:

Operate MediCore backup workflows.

Permissions:

- Read/write the `backups/` S3 prefix.
- Inspect RDS snapshots.
- Create RDS snapshots.

Explicitly excluded:

- Delete S3 backup objects.
- Delete RDS snapshots.
- Delete RDS databases.
- IAM administration.

Least-privilege justification:

Backup operators require the ability to create and verify backups, but routine destructive privileges are deliberately excluded.

---

# CloudWatch Alert Matrix

| ID | Resource | Metric | Threshold | Response |
|---|---|---|---|---|
| A2-ALARM-01 | Bastion | StatusCheckFailed | >= 1 | IRP-A2-01: investigate Bastion health, preserve evidence and escalate |
| A2-ALARM-02 | Web VM | CPUUtilization | >70% for 2 x 5 min | IRP-A2-02: investigate workload/application activity |
| A2-ALARM-03 | Database VM | CPUUtilization | >70% for 2 x 5 min | IRP-A2-03: investigate DB workload and unexpected processes |
| A2-ALARM-04 | RDS | CPUUtilization | >70% for 2 x 5 min | IRP-A2-04: investigate database workload and connections |
| A2-ALARM-05 | RDS | FreeStorageSpace | <2 GiB | IRP-A2-05: investigate storage growth and protect availability |

The IRP identifiers above will be reused in the incident response material so that each CloudWatch alert has a clearly documented operational response.

---

# Adaptability Evidence

The original three-tier design used three physical subnets.

During RDS deployment it was discovered that Amazon RDS requires a DB subnet group spanning at least two Availability Zones.

A second restricted RDS subnet was therefore introduced.

The logical architecture remains three-tier:

- Public
- Private
- Restricted

The additional RDS subnet remains part of the restricted database tier and has no general Internet route.

The Git commit that introduced the RDS subnet should be referenced in the final B3 adaptability evidence.