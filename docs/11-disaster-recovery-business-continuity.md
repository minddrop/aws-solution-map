# Domain 11: Disaster Recovery & Business Continuity

## 1. Capability Scope & Service Taxonomy

### 1.1 Primary Purpose & Domain Boundaries
The Disaster Recovery & Business Continuity domain guarantees enterprise resilience, zero data loss (RPO -> seconds), and rapid automated service restoration (RTO < 15 minutes) across catastrophic regional outages, cyber/ransomware incidents, and physical infrastructure failures.

The domain boundary encapsulates:
- **Continuous Block-Level Replication (AWS Elastic Disaster Recovery [DRS])**: Sub-second asynchronous block-level replication of stateful EC2 instances and on-premises physical/virtual machines into a low-cost staging area in the target AWS disaster recovery region.
- **Cross-Region Cryptographic & Object Replication**: Multi-Region AWS KMS keys paired with Amazon S3 Cross-Region Replication (CRR), S3 Versioning, S3 Object Lock (WORM compliance), and Aurora Global Database replication.
- **Automated Regional Traffic Failover (Route 53 ARC & Zonal Autoshift)**: Highly available, 5-region quorum routing control cells with regional cluster endpoints, readiness checks, and Route 53 ARC Zonal Autoshift for automated evacuation of degraded AZs.
- **Automated Step Functions Failover Orchestration**: Orchestrates atomic DNS flips, primary DB isolation to prevent split-brain conditions, replication lag verification, secondary Aurora writer promotion, and Karpenter EKS scaling.
- **Centralized & Air-Gapped Immutable Backups (AWS Backup)**: Organization-wide AWS Backup policies delegating administration to the Backup/DR account, cross-region / cross-account copy into air-gapped Backup Vaults with AWS Backup Vault Lock (Compliance Mode).
- **Chaos Engineering & Resilience Validation (AWS Fault Injection Service [FIS])**: Automated chaos experiments injecting AZ outages, packet loss, and database failovers.

### 1.2 Core AWS Services & Modern Capabilities
- **AWS Elastic Disaster Recovery (AWS DRS)**: Continuous non-disruptive block-level data replication with point-in-time recovery rollbacks.
- **Amazon Route 53 Application Recovery Controller (ARC)**: Multi-region routing controls with 5-region redundant consensus data planes and automated readiness checks.
- **AWS Route 53 Zonal Shift & Autoshift**: Automated evacuation of impaired Availability Zones without human intervention.
- **AWS Backup & Backup Vault Lock (Air-Gapped)**: Centrally orchestrated, WORM-locked backup vaults across distinct AWS accounts.
- **Amazon Aurora Global Database & DynamoDB Global Tables**: Sub-second cross-region storage replication with fast storage-level promotion.
- **AWS Step Functions Automated DR Runbooks**: Atomic execution eliminating human error and split-brain risks.

---

## 2. IaC Repository Boundary & Inter-Module Contracts

### 2.1 Dedicated Repository Naming & Layout
- **Repository Name**: `terraform-aws-disaster-recovery-resilience`
- **Engine**: Terraform >= 1.9.0 with AWS Provider >= 5.60.0

```
terraform-aws-disaster-recovery-resilience/
├── .github/
│   └── workflows/
│       ├── lint-validate.yml
│       └── dr-readiness-check.yml
├── config/
│   ├── drs-replication-plan.tfvars
│   ├── arc-routing-controls.tfvars
│   └── aws-backup-vault-lock.tfvars
├── modules/
│   ├── elastic-disaster-recovery/
│   │   ├── main.tf
│   │   ├── replication_template.tf
│   │   ├── launch_template.tf
│   │   └── outputs.tf
│   ├── route53-arc-orchestrator/
│   │   ├── control_panel.tf
│   │   ├── routing_controls.tf
│   │   ├── readiness_checks.tf
│   │   ├── zonal_autoshift.tf
│   │   ├── health_checks.tf
│   │   └── outputs.tf
│   ├── step-functions-dr-failover/
│   │   ├── main.tf
│   │   ├── failover_state_machine.json
│   │   ├── iam_roles.tf
│   │   └── outputs.tf
│   ├── aws-backup-central-vault/
│   │   ├── main.tf
│   │   ├── vault_lock.tf
│   │   ├── cross_account_destination.tf
│   │   ├── backup_plans.tf
│   │   └── outputs.tf
│   ├── cross-region-s3-replication/
│   │   ├── crr_rules.tf
│   │   ├── kms_key_replica.tf
│   │   └── outputs.tf
│   └── chaos-fis-experiments/
│       ├── main.tf
│       ├── az_outage_experiment.json
│       ├── rds_failover_experiment.json
│       └── outputs.tf
├── live/
│   ├── dr-primary-us-east-1/
│   │   ├── terragrunt.hcl
│   │   └── main.tf
│   └── dr-secondary-us-west-2/
│       ├── terragrunt.hcl
│       └── main.tf
├── tests/
│   └── arc_failover_simulation_test.go
├── versions.tf
└── README.md
```

### 2.2 Cross-Module Contracts & Dependencies

#### SSM Parameter Store Exports:
| Parameter Path | Type | Consumer / Scope | Purpose |
| :--- | :--- | :--- | :--- |
| `/enterprise/dr/arc/cluster-endpoints` | StringList | SRE / Automation Pipelines | 5-region ARC cluster endpoint URIs for failover consensus |
| `/enterprise/dr/arc/primary-routing-control-arn` | String | Domain 9 (Route 53 Edge) | ARC Routing Control ARN to route traffic to Primary Region |
| `/enterprise/dr/arc/secondary-routing-control-arn` | String | Domain 9 (Route 53 Edge) | ARC Routing Control ARN to route traffic to DR Region |
| `/enterprise/dr/backup/central-vault-arn` | String | All Workload Accounts | Air-gapped AWS Backup Central Vault ARN |
| `/enterprise/dr/drs/staging-area-subnet-id` | String | DRS Replication Agents | Low-cost staging subnet in target DR region |

#### Remote State & Inter-Module Dependencies:
- **Upstream Dependencies**: Domain 1 (`terraform-aws-landing-zone-network-fabric` for DR VPCs), Domain 3 (`terraform-aws-central-identity-kms-security` for Multi-Region KMS Keys), Domain 6 (Aurora Global DB / DynamoDB Global Tables).
- **Downstream Consumers**: Domain 9 (Edge DNS failover policies), Domain 7 (Standby Compute Runtimes).

---

## 3. Architecture Topology Diagram

```mermaid
flowchart TB
    subgraph Global_Traffic_Control["Global Traffic & Recovery Orchestration Layer"]
        subgraph Route53_ARC_Core["Route 53 Application Recovery Controller (ARC)"]
            ARC_Quorum["5-Region Quorum Control Plane (5 Cluster Endpoints)"]
            RC_Primary["Routing Control: Region US-East-1 (Active = 1)"]
            RC_Secondary["Routing Control: Region US-West-2 (Standby = 0)"]
            Readiness_Check["Readiness Checks (Validates DB/Compute/Quotas)"]
            Zonal_Autoshift["Route 53 ARC Zonal Autoshift"]
        end
        Route53_Edge_DNS["Route 53 Edge DNS (DNS Failover Routing)"]
    end

    subgraph DR_Failover_Orchestrator["Automated Step Functions Failover Engine"]
        SFN_Failover["Atomic DR Failover State Machine"]
    end

    subgraph AWS_Region_Primary["Primary AWS Region: us-east-1"]
        subgraph Primary_Compute_Tier["Primary Active Compute"]
            ALB_Primary["Primary Ingress ALB (Zonal Autoshift Enabled)"]
            EKS_Primary["Active EKS Production Cluster"]
            EC2_Stateful["Stateful App EC2 Instances"]
        end

        subgraph Primary_Data_Tier["Primary Active Data Platform"]
            Aurora_Primary["Aurora Global DB (Primary Writer)"]
            S3_Primary_Vault["S3 Data Buckets (KMS Encrypted + Versioned)"]
            DDB_Primary["DynamoDB Global Table (Primary)"]
        end
    end

    subgraph AWS_Region_Secondary["Disaster Recovery Region: us-west-2"]
        subgraph Secondary_Compute_Tier["Standby Recovery Compute"]
            ALB_Secondary["DR Ingress ALB"]
            EKS_Secondary["Standby EKS Cluster (Autoscaling Ready)"]
            
            subgraph DRS_Target_Staging["AWS Elastic Disaster Recovery (DRS)"]
                DRS_Replication_Server["DRS Lightweight Staging Instances"]
                EBS_Staging_Volumes["Low-Cost Staging EBS Volumes"]
                DRS_Recovered_EC2["Target Recovered EC2 Fleet (On Failover)"]
            end
        end

        subgraph Secondary_Data_Tier["Replicated Data Platform"]
            Aurora_Secondary["Aurora Global DB (Storage Replicated Reader)"]
            S3_Secondary_Vault["S3 Target Replicated Bucket (KMS Decrypted/Re-encrypted)"]
            DDB_Secondary["DynamoDB Global Table (Replica)"]
        end
    end

    subgraph AirGapped_Backup_Account["Air-Gapped Central Backup Account"]
        Backup_Vault_Lock["AWS Backup Central Vault (Object Lock Compliance WORM)"]
    end

    %% Routing Control Flow
    Route53_Edge_DNS --> Route53_ARC_Core
    Route53_ARC_Core -->|Normal Traffic| ALB_Primary
    Route53_ARC_Core -.->|Automated Failover| ALB_Secondary
    Readiness_Check -.->|Continuous Health & Capacity Audit| Secondary_Compute_Tier & Secondary_Data_Tier

    %% Automated Step Functions Orchestration
    SFN_Failover -->|1. Flip Routing Controls| Route53_ARC_Core
    SFN_Failover -->|2. Revoke Primary DB SG (Prevent Split-Brain)| Aurora_Primary
    SFN_Failover -->|3. Verify Lag < 1s & Promote Writer| Aurora_Secondary
    SFN_Failover -->|4. Trigger Karpenter Scaling| EKS_Secondary

    %% Data Replication Flows (Continuous)
    Aurora_Primary -->|Storage-level Dedicated Net Replication (<1s)| Aurora_Secondary
    DDB_Primary <-->|Active-Active Replication| DDB_Secondary
    S3_Primary_Vault -->|S3 Cross-Region Replication (CRR)| S3_Secondary_Vault
    EC2_Stateful -->|Block-Level Asynchronous Replication| DRS_Replication_Server --> EBS_Staging_Volumes
    EBS_Staging_Volumes -.->|On Failover Trigger| DRS_Recovered_EC2

    %% Air-gapped Backups
    Primary_Data_Tier -.->|Scheduled Cross-Account Copy| Backup_Vault_Lock
```

---

## 4. Expert Architectural Review & Trade-off Critique

### 4.1 Well-Architected Assessment
- **Security**:
  - *Air-Gapped Ransomware Vault*: AWS Backup Vault Lock in Compliance Mode enforces WORM retention in a physically separate AWS account.
  - *Multi-Region KMS Parity*: Replicated data is re-encrypted with secondary region KMS CMKs during transit.
- **Reliability**:
  - *ARC 5-Region Cluster Endpoints*: Failover scripts try all 5 regional cluster endpoints to guarantee execution during catastrophic multi-region events.
  - *Split-Brain Prevention*: Step Functions atomically isolates primary database security groups before promoting the secondary Aurora cluster.
  - *ARC Zonal Autoshift*: Automatically shifts traffic away from impaired Availability Zones without human delay.
- **Operational Excellence**:
  - *Non-Disruptive DR Drills with DRS*: AWS DRS allows instant testing in isolated VPC subnets without halting replication.
- **Cost Optimization**:
  - *Pilot Light with DRS & Aurora Global*: Micro-sized staging instances and EBS storage cut standby compute costs by over 80% while preserving sub-15 min RTO.

### 4.2 Critical Architectural Risks & Mitigations

#### Risk 1: Split-Brain Catastrophe During Aurora Global Database Promotion
- **Failure Mechanism**: Secondary Aurora cluster is promoted while primary database is still reachable and accepting writes, corrupting database ledgers.
- **Mitigation Strategy**:
  1. Mandate the use of Route 53 ARC and Step Functions as the single source of truth for failover.
  2. Implement automated state machine steps: Flip ARC Routing Controls $\rightarrow$ Revoke primary DB ingress SG $\rightarrow$ Wait for replication lag drain ($< 1\text{ s}$) $\rightarrow$ Promote secondary cluster.

#### Risk 2: Secondary Region Service Quota Starvation
- **Failure Mechanism**: Primary region fails, and Karpenter / DRS fails to launch EC2 instances in the DR region due to unadjusted vCPU quotas.
- **Mitigation Strategy**:
  1. Implement Route 53 ARC Readiness Checks tracking target region service quotas.
  2. Deploy automated Terraform pipeline syncs requesting matching AWS Service Quotas in all secondary regions.
