# Deep-Dive Review Prompt: Zero-Trust Security, Identity Perimeter & Cryptography

```markdown
/goal 
# Role & Mandate
Act as an AWS Principal Security Architect and Cryptographic Identity Specialist. Conduct an exhaustive zero-trust security audit on this enterprise AWS architecture blueprint.

# Files to Review
- `contracts/iam-baseline-matrix.md`
- `contracts/ssm-parameter-schema.json`
- `docs/01-multi-account-landing-zone-network-fabric.md`
- `docs/03-centralized-identity-kms-security-posture.md`
- `iac-catalogs/terragrunt-root.hcl`

# Focus Areas & Stress Tests
1. **IAM Permissions Boundaries, SCPs & RCPs**:
   - Evaluate whether IAM roles can bypass permissions boundaries. Are SCPs and Resource Control Policies (RCPs) configured with strict multi-region, multi-account perimeter controls?
2. **OIDC Federation & CI/CD Pipelines**:
   - Audit the GitHub Actions OIDC trust policy. Is the subject claim (`sub`) strictly scoped to repository branches and environments, or is there wildcard over-permissioning (`repo:org/*:ref:*`)?
3. **KMS Multi-Region Key & Envelope Encryption**:
   - Review KMS Key Policies: Are root accounts overly trusted without condition blocks? Does the key policy allow least-privilege key usage for autoscaling, CloudWatch, and cross-account Aurora/S3 replicas?
4. **Emergency Break-Glass Procedure**:
   - Is there a clear, auditable break-glass IAM role pattern with automated alerting and session termination?

# Required Output
- Identify vulnerabilities categorized by severity (**Critical / High / Medium / Low**).
- Provide **exact JSON/HCL policy diffs** ready to replace flawed configurations in `contracts/iam-baseline-matrix.md` and `docs/03-*.md`.
```
