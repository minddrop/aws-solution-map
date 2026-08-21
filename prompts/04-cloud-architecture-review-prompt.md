# Comprehensive Review Prompt: Enterprise Cloud Architecture & Well-Architected Alignment

```markdown
/goal 
# Role & Context
Act as a panel of Tier-1 Enterprise Cloud Leaders consisting of:
1. **Principal AWS Solutions Architect** (Deep expertise in AWS Well-Architected Framework & modern cloud topologies)
2. **Chief Information Security Officer (CISO) & Cloud Security Architect** (Expert in Zero-Trust, IAM perimeters, SCPs/RCPs, KMS, compliance)
3. **Principal Platform & SRE Engineer** (Expert in Terraform/Terragrunt IaC design, CI/CD, Day-2 operations, blast-radius containment, DR)
4. **Director of Cloud FinOps** (Expert in AWS billing optimization, data transfer economics, serverless cost-efficiency)

# Target Repository
You are reviewing an Enterprise AWS Architecture Blueprint repository containing:
- **Core Blueprint**: `README.md`
- **11 Domain Specifications**:
  - `docs/01-multi-account-landing-zone-network-fabric.md`
  - `docs/02-hybrid-multi-cloud-connectivity.md`
  - `docs/03-centralized-identity-kms-security-posture.md`
  - `docs/04-central-observability-telemetry-compliance.md`
  - `docs/05-finops-cost-governance.md`
  - `docs/06-data-persistence-streaming-lakehouse.md`
  - `docs/07-compute-container-platforms.md`
  - `docs/08-application-integration-async-orchestration.md`
  - `docs/09-edge-security-content-delivery-routing.md`
  - `docs/10-aiml-inference-enterprise-guardrails.md`
  - `docs/11-disaster-recovery-business-continuity.md`
- **Contracts & Baseline Specs**:
  - `contracts/ssm-parameter-schema.json`
  - `contracts/iam-baseline-matrix.md`
  - `contracts/network-cidr-ipam-allocations.md`
- **IaC Catalogs**:
  - `iac-catalogs/modules-dependency-matrix.md`
  - `iac-catalogs/terragrunt-root.hcl`

---

# Review Objectives & Dimensions
Evaluate this blueprint against Tier-1 enterprise standards across the following 7 dimensions:

### 1. AWS Well-Architected Alignment (All 6 Pillars)
- **Security**: Zero-trust enforcement, SCP/RCP boundaries, least-privilege IAM, KMS key hierarchy, network isolation, and encryption in-transit/at-rest.
- **Reliability**: Multi-AZ/Multi-Region topologies, automated failover (Route 53 ARC), RTO/RPO definitions, backup immutability (WORM / Object Lock), and circuit breaker patterns.
- **Performance Efficiency**: Network latency optimization (VPC Lattice, Transit Gateway vs PrivateLink vs VPC Peering), compute selection (Graviton/Bottlerocket/Karpenter), database read/write scaling.
- **Cost Optimization (FinOps)**: Identification of hidden cost drivers (cross-AZ/cross-region data transfer, NAT Gateways vs VPC Endpoints, TGW processing fees, idle standby compute).
- **Operational Excellence**: Observability aggregation (CloudWatch OAM sinks, OpenSearch), telemetry contracts, automated runbooks, IaC drift management, and chaos testing readiness.
- **Sustainability**: Compute efficiency, resource rightsizing, auto-scaling elasticity, and lifecycle management.

### 2. Enterprise Governance & Landing Zone Topology
- Multi-account structure (AWS Organizations OU hierarchy, delegated administration accounts).
- Separation of duties (SecOps vs Network Hub vs Log Archive vs Workload accounts).
- Control Tower & Account Factory for Terraform (AFT) compatibility.

### 3. Networking, Hybrid Transit & Edge Security
- RFC 1918 CIDR allocation & IPAM hierarchy: Check for overlapping subnet risks or AZ capacity bottlenecks.
- Inspection & Ingress/Egress routing: Evaluate asymmetric routing risks across TGW and Network Firewall.
- Edge perimeter: CloudFront Origin Access Control (OAC), AWS WAF rulesets, Shield Advanced integration.

### 4. Inter-Module Contracts & Coupling
- Evaluate `contracts/ssm-parameter-schema.json` for completeness, naming consistency, schema strictness, and circular dependency risks.
- Check cross-account parameter resolution patterns (cross-account IAM assume vs SSM sharing).

### 5. Infrastructure-as-Code (IaC) & Implementation Viability
- Review `iac-catalogs/terragrunt-root.hcl` and `iac-catalogs/modules-dependency-matrix.md`.
- Evaluate module boundaries, state locking, blast radius, provider versions, and pipeline orchestration order.

### 6. Modern Cloud-Native & AI/ML Capabilities
- Review the inclusion of modern AWS services (e.g., Amazon Bedrock Guardrails, OpenSearch Serverless Vector DB, VPC Lattice, Route 53 ARC, Resource Control Policies).
- Are there emerging best practices or newer service alternatives that should be adopted?

### 7. Completeness, Edge Cases & Anti-Patterns
- Identify architectural gaps, single points of failure (SPOFs), missing error-handling/dead-letter queues, unaddressed compliance requirements (e.g., SOC 2, HIPAA, PCI-DSS).

---

# Required Output Structure
Format your review into the following sections:

1. **Executive Scorecard**:
   - Overall Architectural Maturity Grade (A+ to F).
   - Pillar-by-Pillar Scores (1–10) with 1-sentence justifications.
   - Top 3 Strengths & Top 3 Critical Vulnerabilities / Gaps.

2. **Critical Findings & High-Priority Risks (Ranked by Severity: Critical, High, Medium, Low)**:
   - For each finding:
     - **Issue Title & Affected Files/Domains**
     - **Architectural Risk / Impact**
     - **Technical Root Cause / Anti-Pattern**
     - **Concrete Recommendation & Remediation Snippet (HCL/JSON/Config)**

3. **Domain-by-Domain Detailed Critique**:
   - Specific comments, edge-case evaluations, and missing best practices for each of the 11 domains and 3 contract files.

4. **FinOps & Cost-Trap Analysis**:
   - Specific areas where this design might inadvertently incur massive AWS bills, with mitigation strategies.

5. **Actionable Roadmap for Implementation**:
   - Phased rollout recommendations (Phase 1: Foundation -> Phase 2: Core Platform -> Phase 3: Workloads -> Phase 4: Day-2 Ops).
```
