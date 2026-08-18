# Domain 3: Centralized Identity, KMS & Security Posture

## 1. Capability Scope & Service Taxonomy

### 1.1 Primary Purpose & Domain Boundaries
The Centralized Identity, KMS & Security Posture domain establishes enterprise cryptographic controls, human/machine access boundaries, posture management, automated threat detection, and secrets orchestration across all AWS accounts in the Organization.

The domain boundary encapsulates:
- **Workforce Identity & Access Management**: AWS IAM Identity Center (SSO) integrated with enterprise Identity Providers (Entra ID / Okta) via SAML 2.0 and SCIM automated provisioning; Permission Sets mapped to granular ABAC tags.
- **Machine Identity & Workload Federation**: IAM Roles Anywhere for on-premises workloads using X.509 PKI certificates, and OpenID Connect (OIDC) federation for CI/CD pipelines (GitHub Actions, GitLab CI).
- **Cryptographic Key Management**: Multi-Region Customer Managed Keys (CMKs) in AWS KMS with automated annual rotation, synchronized replica key policies in DR regions, alias taxonomy, envelope encryption standards, and strict cross-account key policies.
- **Central Secrets & Credential Rotation**: AWS Secrets Manager with automated Lambda rotation in VPC subnets, cross-region replication for DR, and dynamic database credentials.
- **Continuous Posture & Threat Detection**: Centralized delegated administration in the SecOps account for AWS Security Hub (CSPM), AWS GuardDuty (Threat Intelligence with EKS runtime, S3, Malware, and RDS protection), AWS Inspector (vulnerability scanning), and AWS Macie (PII discovery).

### 1.2 Core AWS Services & Modern Capabilities
- **AWS IAM Identity Center (SAML/SCIM)**: Centralized SSO, session duration policies, and multi-factor authentication (MFA/FIDO2 WebAuthn).
- **IAM Roles Anywhere & Workload OIDC**: Zero long-lived AWS IAM access keys for on-premises servers and automated pipelines.
- **AWS Key Management Service (KMS)**: Multi-Region Symmetric/Asymmetric CMKs with unified, synchronized policy management across primary and secondary regions.
- **AWS Secrets Manager**: Automated secret rotation, cross-account resource policies, and dynamic RDS/Aurora credentials.
- **AWS Security Hub & CSPM**: Centralized posture aggregation (CIS AWS Foundations Benchmark, NIST 800-53, PCI-DSS v4.0), automated remediation via EventBridge & Systems Manager Automation.
- **Amazon GuardDuty**: Threat detection across CloudTrail management/data events, VPC Flow Logs, DNS logs, EKS audit/runtime logs, and Lambda execution logs.
- **AWS IAM Access Analyzer**: External access findings, unused access tracking, and policy validation against mathematical provable security algorithms.

---

## 2. IaC Repository Boundary & Inter-Module Contracts

### 2.1 Dedicated Repository Naming & Layout
- **Repository Name**: `terraform-aws-central-identity-kms-security`
- **Engine**: Terraform >= 1.9.0 with AWS Provider >= 5.60.0

```
terraform-aws-central-identity-kms-security/
├── .github/
│   └── workflows/
│       ├── lint-validate.yml
│       └── security-policy-test.yml
├── config/
│   ├── identity-center-permissions.tfvars
│   ├── kms-key-policies.tfvars
│   └── security-hub-controls.tfvars
├── modules/
│   ├── iam-identity-center/
│   │   ├── main.tf
│   │   ├── permission_sets.tf
│   │   ├── account_assignments.tf
│   │   └── outputs.tf
│   ├── oidc-workload-providers/
│   │   ├── github_actions.tf
│   │   ├── gitlab_ci.tf
│   │   ├── iam_roles_anywhere.tf
│   │   └── outputs.tf
│   ├── kms-cmk-catalog/
│   │   ├── main.tf
│   │   ├── multi_region_keys.tf
│   │   ├── key_policies.tf
│   │   ├── aliases.tf
│   │   └── outputs.tf
│   ├── secrets-manager-baseline/
│   │   ├── main.tf
│   │   ├── rotation_lambdas.tf
│   │   └── outputs.tf
│   ├── security-hub-org/
│   │   ├── main.tf
│   │   ├── standards.tf
│   │   ├── auto_remediations.tf
│   │   └── outputs.tf
│   ├── guardduty-org/
│   │   ├── main.tf
│   │   ├── detectors.tf
│   │   ├── malware_protection.tf
│   │   └── outputs.tf
│   └── iam-access-analyzer/
│       ├── main.tf
│       ├── analyzers.tf
│       └── outputs.tf
├── live/
│   ├── secops-delegated-admin/
│   │   ├── terragrunt.hcl
│   │   └── main.tf
│   └── root-identity-org/
│       ├── terragrunt.hcl
│       └── main.tf
├── tests/
│   └── kms_policy_eval_test.go
├── versions.tf
└── README.md
```

### 2.2 Cross-Module Contracts & Dependencies

#### SSM Parameter Store & Secrets Manager Exports:
| Parameter Path | Type | Consumer / Scope | Purpose |
| :--- | :--- | :--- | :--- |
| `/enterprise/security/kms/general-data-key-arn` | String | All Workload Accounts | CMK ARN for general storage encryption (EBS, S3, RDS) |
| `/enterprise/security/kms/cross-region-dr-key-arn` | String | Domain 11 (DR Replication) | Primary multi-region CMK ARN for cross-region replication |
| `/enterprise/security/kms/cross-region-dr-key-replica-arn` | String | Domain 11 (DR Replication) | Replica multi-region CMK ARN in secondary DR region |
| `/enterprise/security/oidc/github-actions-role-arn` | String | CI/CD Repositories | Workload pipeline IAM Role ARN for OIDC token assumption |
| `/enterprise/security/guardduty/detector-id` | String | Domain 4 (Central Telemetry) | Central SecOps GuardDuty Detector ID |
| `/enterprise/security/secrets/db-rotation-lambda-arn` | String | Domain 6 (Database Platforms) | Lambda ARN used to rotate database master credentials |

#### Remote State & Inter-Module Dependencies:
- **Upstream Dependencies**: Domain 1 (`terraform-aws-landing-zone-network-fabric` for Org Root ID and SecOps Account ID).
- **Downstream Consumers**: All Workload Domains (4 through 11) for KMS CMKs, OIDC pipeline roles, and Secret rotation engines.

---

## 3. Architecture Topology Diagram

```mermaid
flowchart TB
    subgraph Identity_Providers["Enterprise IdP & Federation Layer"]
        Entra_ID["Entra ID / Okta (SAML 2.0 & SCIM)"]
        GitHub_OIDC["GitHub Actions / CI/CD (OIDC JWT)"]
        OnPrem_PKI["Enterprise On-Prem CA (X.509 PKI)"]
    end

    subgraph Org_Management_Account["AWS Organizations Root Account"]
        IAM_Identity_Center["AWS IAM Identity Center"]
        SCIM_Sync["SCIM User / Group Sync"]
        IAM_IdP_Config["SAML 2.0 IdP Configuration"]
    end

    subgraph SecOps_Admin_Account["SecOps Delegated Admin Account (333333333333)"]
        subgraph CSPM_Threat["Continuous Threat Detection & Posture"]
            SecHub_Admin["AWS Security Hub Delegated Admin"]
            GuardDuty_Admin["AWS GuardDuty Master Detector"]
            Inspector_Admin["AWS Inspector V2 Org Admin"]
            Access_Analyzer["IAM Access Analyzer (Org-wide)"]
        end

        subgraph Automated_Remediation["Automated Remediation Engine"]
            EB_Security_Events["Amazon EventBridge (SecOps Rules)"]
            SSM_Automation["AWS SSM Automation Runbooks"]
            SOC_Alerting["SOC PagerDuty / SIEM Forwarder"]
        end

        subgraph Central_Secrets_KMS["Security Artifacts & Master KMS"]
            KMS_MultiRegion["KMS Multi-Region CMKs (Primary: us-east-1)"]
            KMS_Replica["KMS Replica CMKs (Secondary: us-west-2)"]
            Secrets_Catalog["Secrets Manager (Central Vault)"]
            IAM_Roles_Anywhere["IAM Roles Anywhere Trust Anchor"]
        end
    end

    subgraph Workload_Accounts["Workload Member Accounts (Prod / Non-Prod)"]
        subgraph Workload_A["Workload Account (EKS / Aurora)"]
            IAM_Workload_Role["IAM Workload Role (EKS Pod Identity)"]
            EBS_RDS_S3["EBS / RDS / S3 Data Stores"]
            GD_Member["GuardDuty Member Agent"]
            SecHub_Member["Security Hub Member"]
        end
    end

    %% Identity flows
    Entra_ID -->|SCIM Sync| SCIM_Sync
    Entra_ID -->|SAML 2.0 Auth| IAM_IdP_Config
    IAM_IdP_Config --> IAM_Identity_Center
    IAM_Identity_Center -->|Assume Role with Short-lived Token| Workload_Accounts

    GitHub_OIDC -->|OIDC Token Exchange (sts:AssumeRoleWithWebIdentity)| IAM_Workload_Role
    OnPrem_PKI -->|X.509 Certificate Validation| IAM_Roles_Anywhere

    %% Security Findings & Remediation Flow
    GD_Member -.->|Security Findings| GuardDuty_Admin
    SecHub_Member -.->|Compliance Findings| SecHub_Admin
    GuardDuty_Admin & SecHub_Admin --> EB_Security_Events
    EB_Security_Events --> SSM_Automation & SOC_Alerting
    SSM_Automation -->|Remediate Open SG / Public S3| Workload_Accounts

    %% Cryptographic flow
    EBS_RDS_S3 -->|Envelope Encryption (kms:GenerateDataKey)| KMS_MultiRegion
    KMS_MultiRegion -.->|Synchronized Key Policy| KMS_Replica
```

---

## 4. Expert Architectural Review & Trade-off Critique

### 4.1 Well-Architected Assessment
- **Security**:
  - *Zero Static Credentials*: Completely eliminates long-lived IAM user access keys via IAM Identity Center for humans and OIDC / IAM Roles Anywhere for machines.
  - *Envelope Encryption Standard*: KMS CMKs with enforced key policies restrict decryption rights to authorized application execution roles only (`aws:PrincipalArn` + `kms:CallerAccount`).
- **Reliability**:
  - *Multi-Region KMS Synchronized Key Policies*: Primary and replica KMS keys maintain 100% policy parity via unified IaC declarations, preventing permission drift during regional DR failovers.
  - *Automated Secret Failover*: Secrets Manager secrets replicate synchronously to the secondary DR region with automated replica secret decryption policies.
- **Operational Excellence**:
  - *Automated GuardDuty / Security Hub Remediation*: EventBridge rules detect high-severity findings and invoke SSM Automation runbooks to isolate compromised resources in under 15 seconds.
  - *Continuous Access Analysis*: IAM Access Analyzer continuously verifies resource policies against mathematical proofs to detect unintentional public exposure.
- **Cost Optimization**:
  - *KMS Key Architecture*: Workload-tier CMKs provisioned locally per account avoid cross-account KMS grant API limits, while global Multi-Region CMKs protect cross-region replicated storage.

### 4.2 Critical Architectural Risks & Mitigations

#### Risk 1: KMS Replica Key Policy Desynchronization on DR Failover
- **Failure Mechanism**: The primary KMS CMK policy in `us-east-1` is updated with new application roles, but the replica key in `us-west-2` is not synchronized. During regional failover, application pods fail to decrypt database storage.
- **Mitigation Strategy**:
  1. Manage primary and replica key policies centrally within a unified Terraform module using identical parameterized JSON policy documents.
  2. Implement CI/CD integration tests verifying identical decryption permissions across both primary and replica KMS key ARNs.

#### Risk 2: Secrets Manager Automated Rotation Database Connection Exhaustion
- **Failure Mechanism**: The Lambda rotation function executes credential rotation on Aurora instances. Applications continue using old credentials or initiate concurrent reconnects, exhausting `max_connections`.
- **Mitigation Strategy**:
  1. Deploy AWS Secrets Manager RDS Proxy integration to manage connection pooling and absorb secret transitions.
  2. Implement the standard 4-step rotation protocol (`createSecret`, `setSecret`, `testSecret`, `finishSecret`) with exponential backoff.
