# Architecture Review Reports Index

This directory holds the generated review reports produced by specialized Sub-Agents executing the prompt suite in [`prompts/`](../../prompts).

## Generated Reports

| Report | Source Prompt | Status | Executive Summary |
| :--- | :--- | :---: | :--- |
| [`01-network-report.md`](01-network-report.md) | [`01-network-review-prompt.md`](../../prompts/01-network-review-prompt.md) | **Completed** | Deep-dive packet flow routing, TGW segmentation, Route 53 Profiles, and IPAM subnet breakdown. |
| [`02-security-report.md`](02-security-report.md) | [`02-zero-trust-security-review-prompt.md`](../../prompts/02-zero-trust-security-review-prompt.md) | **Completed** | Zero-trust identity, OIDC sub claim scoping fix, multi-region KMS key policies, and SCPs/RCPs. |
| [`03-data-report.md`](03-data-report.md) | [`03-data-architecture-review-prompt.md`](../../prompts/03-data-architecture-review-prompt.md) | **Completed** | Aurora Serverless v2 + RDS Proxy, MSK Tiered Storage, Iceberg compaction, and DynamoDB Global Tables. |
| [`04-master-cloud-report.md`](04-master-cloud-report.md) | [`04-cloud-architecture-review-prompt.md`](../../prompts/04-cloud-architecture-review-prompt.md) | **Completed** | 360° Well-Architected Framework review (Grade: A / 94), pillar scores, cross-domain synthesis. |
| [`05-resilience-report.md`](05-resilience-report.md) | [`05-resilience-disaster-recovery-review-prompt.md`](../../prompts/05-resilience-disaster-recovery-review-prompt.md) | **Completed** | Route 53 ARC 5-region quorum, sub-15 min RTO / sub-1 min RPO validation, split-brain write fencing. |
| [`06-iac-sre-report.md`](06-iac-sre-report.md) | [`06-iac-terragrunt-review-prompt.md`](../../prompts/06-iac-terragrunt-review-prompt.md) | **Completed** | Terragrunt root config, remote state locking, acyclic DAG dependency sequencing, and SSM schema. |
| [`07-finops-report.md`](07-finops-report.md) | [`07-finops-cloud-economics-review-prompt.md`](../../prompts/07-finops-cloud-economics-review-prompt.md) | **Completed** | CUR 2.0 Athena partition projection, shared infrastructure chargeback, Karpenter Graviton elasticity. |
| [`08-aiml-report.md`](08-aiml-report.md) | [`08-aiml-workload-governance-review-prompt.md`](../../prompts/08-aiml-workload-governance-review-prompt.md) | **Completed** | Amazon Bedrock Guardrails, Cross-Region Inference Profiles, PrivateLink AI networking, and RAG. |
| [`09-cto-report.md`](09-cto-report.md) | [`09-executive-cto-strategic-review-prompt.md`](../../prompts/09-executive-cto-strategic-review-prompt.md) | **Completed** | Executive decision brief (Unanimous Go), DevEx, open standards balance, and Target Operating Model. |
