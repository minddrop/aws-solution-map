# Enterprise IaC Repository Dependency & Orchestration Matrix

## 1. End-to-End Dependency Pipeline Graph

```mermaid
graph TD
    D01["Domain 1: Landing Zone & Network Fabric<br/>(terraform-aws-landing-zone-network-fabric)"]
    D02["Domain 2: Hybrid & Multi-Cloud<br/>(terraform-aws-hybrid-multicloud-connectivity)"]
    D03["Domain 3: Identity, KMS & Security<br/>(terraform-aws-central-identity-kms-security)"]
    D04["Domain 4: Observability & Telemetry<br/>(terraform-aws-central-observability-compliance)"]
    D05["Domain 5: FinOps & Cost Governance<br/>(terraform-aws-finops-cost-governance)"]
    D06["Domain 6: Data Persistence & Lakehouse<br/>(terraform-aws-data-persistence-lakehouse)"]
    D07["Domain 7: Compute & Container Platforms<br/>(terraform-aws-compute-container-platforms)"]
    D08["Domain 8: App Integration & Orchestration<br/>(terraform-aws-application-integration-orchestration)"]
    D09["Domain 9: Edge Security & Routing<br/>(terraform-aws-edge-security-routing)"]
    D10["Domain 10: AI/ML Inference & Guardrails<br/>(terraform-aws-aiml-inference-guardrails)"]
    D11["Domain 11: Disaster Recovery & Resilience<br/>(terraform-aws-disaster-recovery-resilience)"]

    %% Core Foundation Tier
    D01 --> D02
    D01 --> D03
    D03 --> D04
    D01 --> D04
    D03 --> D05

    %% Data & Platform Tier
    D01 --> D06
    D03 --> D06
    D01 --> D07
    D03 --> D07
    D04 --> D07
    D06 --> D07

    %% Integration & Edge Tier
    D03 --> D08
    D07 --> D08
    D01 --> D09
    D04 --> D09
    D07 --> D09

    %% AI & DR Resilience Tier
    D01 --> D10
    D03 --> D10
    D06 --> D10
    D07 --> D10
    D08 --> D10

    D01 --> D11
    D03 --> D11
    D06 --> D11
    D07 --> D11
    D09 --> D11
```

---

## 2. IaC Execution Order & Inter-Module Dependency Table

| Execution Order | Capability Domain | IaC Repository Identifier | Direct Upstream Dependencies | Published Contract Exports |
| :---: | :--- | :--- | :--- | :--- |
| **01** | Multi-Account Landing Zone & Core Network Fabric | `terraform-aws-landing-zone-network-fabric` | AWS Organizations Root | TGW ID, Spoke RT, Inbound DNS IPs, Route 53 Profile ARN, IPAM Pools |
| **02** | Hybrid & Multi-Cloud Connectivity | `terraform-aws-hybrid-multicloud-connectivity` | Domain 01 | DXGW ID, Cloud WAN Core ID, BGP ASNs, Allowed Prefixes |
| **03** | Centralized Identity, KMS & Security Posture | `terraform-aws-central-identity-kms-security` | Domain 01 | Multi-Region KMS CMK ARNs (Primary & Replica), OIDC Roles, GuardDuty Master |
| **04** | Central Observability, Telemetry & Compliance | `terraform-aws-central-observability-compliance` | Domain 01, Domain 03 | CloudWatch OAM Sink ARN, Log Archive WORM S3 ARN, OpenSearch URL |
| **05** | FinOps & Cost Governance | `terraform-aws-finops-cost-governance` | Domain 01, Domain 03 | CUR 2.0 S3 ARN, Athena WorkGroup, Mandatory Tag Keys |
| **06** | Data Persistence, Streaming & Lakehouse | `terraform-aws-data-persistence-lakehouse` | Domain 01, Domain 03 | RDS Proxy Endpoints (RW & RO), DynamoDB ARNs, MSK Brokers, Iceberg S3 ARNs |
| **07** | Compute & Container Platforms | `terraform-aws-compute-container-platforms` | Domain 01, Domain 03, Domain 04, Domain 06 | EKS API Endpoints, VPC Lattice Service Network ARN, Gateway API Role ARN |
| **08** | Application Integration & Orchestration | `terraform-aws-application-integration-orchestration` | Domain 03, Domain 04, Domain 07 | Central EventBus ARN, SQS DLQ ARNs, Step Functions ARNs |
| **09** | Edge Security, Content Delivery & Routing | `terraform-aws-edge-security-routing` | Domain 01, Domain 04, Domain 07 | Global WAF WebACL ARN, CloudFront Distribution ID, Route 53 Zone ID |
| **10** | AI/ML Inference & Enterprise Guardrails | `terraform-aws-aiml-inference-guardrails` | Domain 01, Domain 03, Domain 06, Domain 07 | Bedrock Guardrail ID/Version, Cross-Region Inference Profile ARN, RAG KB ID |
| **11** | Disaster Recovery & Business Continuity | `terraform-aws-disaster-recovery-resilience` | Domain 01, Domain 03, Domain 06, Domain 07, Domain 09 | ARC 5-Region Cluster Endpoints, ARC Routing Control ARNs, Central Backup Vault ARN |
