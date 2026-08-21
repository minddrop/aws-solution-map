# Deep-Dive Review Prompt: FinOps, Cloud Economics & Cost Governance

```markdown
/goal 
# Role & Mandate
Act as an Enterprise Head of FinOps, Principal Cloud Economist, and AWS Billing Specialist. Perform an exhaustive cost governance, unit-economics, and financial risk audit across this enterprise AWS architecture blueprint.

# Files to Review
- `docs/05-finops-cost-governance.md`
- `docs/01-multi-account-landing-zone-network-fabric.md`
- `docs/07-compute-container-platforms.md`
- `contracts/ssm-parameter-schema.json`
- `iac-catalogs/terragrunt-root.hcl`

# Focus Areas & Cost-Trap Stress Tests
1. **CUR 2.0 Pipeline & Athena Partition Projection**:
   - Audit the Cost and Usage Report 2.0 (Data Exports) ingestion into Parquet.
   - Is Athena partition projection properly configured to avoid expensive full S3 metadata/data scans on multi-year billing datasets?
   - Are split cost allocation data enabled for Amazon EKS container workloads?
2. **Shared Infrastructure Cost Attribution & Chargeback**:
   - Evaluate how centralized shared infrastructure (Transit Gateway data processing, AWS Network Firewall inspection, centralized VPC endpoints, shared MSK clusters) is allocated across tenant accounts.
   - Are AWS Cost Categories configured with dynamic split rules to avoid unallocated IT overhead?
3. **Compute & Storage Elasticity / Waste Prevention**:
   - Audit Karpenter dynamic provisioning (Graviton instance weighting, Spot instance disruption handling, `consolidationPolicy: WhenEmptyOrUnderutilized`).
   - Audit Aurora Serverless v2 min/max ACU bounds and RDS Proxy connection lifecycle to prevent idle memory consumption.
   - Audit S3 Lifecycle configurations (transitions to Intelligent-Tiering / Glacier Instant Retrieval / Deep Archive).
4. **Proactive Budgeting & Guardrail Scoping**:
   - Are AWS Budgets Actions strictly scoped to Sandbox/Dev accounts to prevent accidental production workload termination?
   - Is AWS Cost Anomaly Detection integrated with EventBridge/SNS for real-time alerting with root-cause context?

# Required Output
- **Cost-Trap Risk Table**: High-risk cost drivers identified across the 11 domains with estimated financial impact.
- **FinOps Best-Practice Diffs**: Concrete HCL/JSON configuration updates for `docs/05-finops-cost-governance.md` and `iac-catalogs/terragrunt-root.hcl`.
```
