# Architecture Review Report 02: Zero-Trust Security, Identity Perimeter & Cryptography

**Review Area**: Zero-Trust Identity, Workload Federation, KMS Cryptography, SCPs & RCPs  
**Reviewer Role**: AWS Principal Security Architect & Cryptographic Identity Specialist  
**Status**: COMPLETED  
**Date**: 2026-08-21  

---

## 1. Executive Summary & Assessment

An exhaustive security, IAM trust boundary, and cryptographic key hierarchy audit was conducted across [`contracts/iam-baseline-matrix.md`](file:///home/joe/src/aws-solution-map/contracts/iam-baseline-matrix.md), [`contracts/ssm-parameter-schema.json`](file:///home/joe/src/aws-solution-map/contracts/ssm-parameter-schema.json), [`docs/01-multi-account-landing-zone-network-fabric.md`](file:///home/joe/src/aws-solution-map/docs/01-multi-account-landing-zone-network-fabric.md), [`docs/03-centralized-identity-kms-security-posture.md`](file:///home/joe/src/aws-solution-map/docs/03-centralized-identity-kms-security-posture.md), and [`iac-catalogs/terragrunt-root.hcl`](file:///home/joe/src/aws-solution-map/iac-catalogs/terragrunt-root.hcl).

### Overall Architecture Evaluation: **Grade A**
The zero-trust posture is exemplary, establishing zero long-lived credentials (IAM Identity Center for humans, OIDC / EKS Pod Identity / Roles Anywhere for machines), Resource Control Policies (RCPs) with service exceptions, and WORM-locked S3/Backup vaults. However, two critical vulnerabilities and policy refinements were uncovered:

---

## 2. Vulnerability & Risk Analysis

### 2.1 SEC-001: Overly Broad GitHub Actions OIDC Subject (`sub`) Claim (Severity: P0 / Critical)
- **Vulnerability**: In [`contracts/iam-baseline-matrix.md`](file:///home/joe/src/aws-solution-map/contracts/iam-baseline-matrix.md) Line 28, the trust condition for `AWSAccelerator-PipelineOIDC-Role` specifies:
  `token.actions.githubusercontent.com:sub: repo:enterprise/*`
- **Architectural Impact**: This allows **any GitHub repository** under the `enterprise` organization, including untrusted or sandbox repositories, feature branches, and fork pull-requests, to authenticate and assume administrative deployment roles across member accounts.
- **Root Cause**: Wildcard regex over-permissioning across repositories and Git refs.
- **Exact Remediation**: Constrain the condition to exact deployment repositories and protected environment/branch claims:
  ```json
  "Condition": {
    "StringEquals": {
      "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
    },
    "StringLike": {
      "token.actions.githubusercontent.com:sub": [
        "repo:enterprise/terraform-aws-*:ref:refs/heads/main",
        "repo:enterprise/terraform-aws-*:environment:production"
      ]
    }
  }
  ```

---

### 2.2 SEC-002: Hardcoded / Placeholder String in AWS Backup Role Trust (Severity: P1 / High)
- **Vulnerability**: Line 30 of `contracts/iam-baseline-matrix.md` contains placeholder `<BackupVaultAccountID>` instead of parameterized account reference.
- **Architectural Impact**: Breaks automated IAM policy synthesis or leaves role assumption unconstrained if not interpolated dynamically.
- **Exact Remediation**: Replace with standard parameterized declaration `aws:PrincipalAccount: "${local.backup_vault_account_id}"` or Organizations OrgID condition.

---

### 2.3 SEC-003: Bedrock Guardrail SCP Cross-Region Inference Profile Scope (Severity: P1 / High)
- **Vulnerability**: SCP 3 (`DenyUnguardedGenerativeModelInvocations`) matches `arn:aws:bedrock:*::foundation-model/*` but does not explicitly capture `arn:aws:bedrock:*:*:inference-profile/*`.
- **Architectural Impact**: Microservices invoking Claude 3.5 Sonnet via Bedrock Cross-Region Inference Profiles (`us.anthropic.claude-3-5-sonnet-20241022-v2:0`) could bypass guardrail checks if the SCP condition evaluates resource ARNs strictly against `foundation-model`.
- **Exact Remediation**: Add `arn:aws:bedrock:*:*:inference-profile/*` to the `Resource` list of SCP 3.

---

## 3. Cryptographic Key Management & Emergency Break-Glass Review

### 3.1 KMS Multi-Region CMK Parity
The key policy design ensures complete synchronization between primary keys in `us-east-1` and replica keys in `us-west-2`. The KMS key policy correctly incorporates:
1. Root account delegation to authorized SecOps administrators.
2. Least privilege grants to AWS services (`kms:ViaService = "s3.us-east-1.amazonaws.com"`, `kms:CallerAccount`).
3. Cross-account grant delegation for Aurora Global Database and S3 Cross-Region Replication (CRR).

### 3.2 Auditable Break-Glass Role Pattern
The break-glass workflow requires:
1. Dedicated `AWSAccelerator-BreakGlass-Admin` role with mandatory MFA and external Ticket ID tag (`aws:RequestTag/IncidentTicketID`).
2. Immediate Amazon EventBridge rule on `sts:AssumeRole` triggering high-priority SOC alerts to PagerDuty and Slack.
3. Maximum session duration constrained to 1 hour with automatic session revocation SSM document `AWS-RevokeOlderURLSessions`.

---

## 4. Policy Diffs & Remediations

### 4.1 Remediation Diff: GitHub Actions OIDC Trust Policy
```diff
--- a/contracts/iam-baseline-matrix.md
+++ b/contracts/iam-baseline-matrix.md
@@ -28,1 +28,1 @@
-| `AWSAccelerator-PipelineOIDC-Role` | GitHub Actions (`token.actions.githubusercontent.com`) | Terraform IaC Plan & Apply | `token.actions.githubusercontent.com:sub: repo:enterprise/*` |
+| `AWSAccelerator-PipelineOIDC-Role` | GitHub Actions (`token.actions.githubusercontent.com`) | Terraform IaC Plan & Apply | `token.actions.githubusercontent.com:sub: repo:enterprise/terraform-aws-*:ref:refs/heads/main` |
```

### 4.2 Remediation Diff: Bedrock Guardrails SCP Cross-Region Profile
```diff
--- a/contracts/iam-baseline-matrix.md
+++ b/contracts/iam-baseline-matrix.md
@@ -144,3 +144,5 @@
         "arn:aws:bedrock:*::foundation-model/amazon.titan-text-*"
+        "arn:aws:bedrock:*:*:inference-profile/us.anthropic.*",
+        "arn:aws:bedrock:*:*:inference-profile/us.meta.*"
       ],
```

---

## 5. Security Findings Summary

| Finding ID | Severity | Domain | Affected Files | Title |
| :--- | :---: | :--- | :--- | :--- |
| `SEC-001` | **P0** | `03-centralized-identity-kms-security-posture` | `contracts/iam-baseline-matrix.md` | Overly broad GitHub Actions OIDC sub claim wildcard |
| `SEC-002` | **P1** | `03-centralized-identity-kms-security-posture` | `contracts/iam-baseline-matrix.md` | Uninterpolated placeholder in AWS Backup trust policy |
| `SEC-003` | **P1** | `03-centralized-identity-kms-security-posture` | `contracts/iam-baseline-matrix.md`, `docs/03-*.md` | Bedrock Guardrail SCP missing cross-region inference profile ARNs |
