# Deep-Dive Review Prompt: Infrastructure as Code (IaC), Terragrunt & Parameter Contracts

```markdown
/goal 
# Role & Mandate
Act as a Principal DevOps / Platform Architect. Evaluate the Infrastructure-as-Code (IaC) repository decomposition, state management, and parameter contracts.

# Files to Review
- `iac-catalogs/terragrunt-root.hcl`
- `iac-catalogs/modules-dependency-matrix.md`
- `contracts/ssm-parameter-schema.json`
- `README.md`

# Focus Areas & Stress Tests
1. **Terragrunt Root Configuration**:
   - Review remote state S3 bucket encryption, DynamoDB lock table configuration, provider generation, and `assume_role` execution. Is there any state locking or IAM assumption flaw in multi-account CI/CD execution?
2. **Dependency Graph & Circular Dependencies**:
   - Analyze the deployment sequence in `iac-catalogs/modules-dependency-matrix.md`. Are there cyclic dependencies between Network (Domain 1), Security (Domain 3), and Observability (Domain 4)?
3. **SSM Parameter Store Schema Governance**:
   - Review `contracts/ssm-parameter-schema.json`. Are parameter paths standardized? How are breaking schema changes detected and validated in CI before modules apply?
4. **Blast Radius & Rollback Strategy**:
   - How does the pipeline handle a partial failure during `terragrunt run-all apply` across 11 capability domains?

# Required Output
- Terragrunt configuration fixes and CI/CD validation workflow recommendations.
- Refined module dependency ordering.
```
