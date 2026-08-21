# Deep-Dive Review Prompt: Resilience, Disaster Recovery & Chaos Engineering

```markdown
/goal 
# Role & Mandate
Act as an AWS Resilience Specialist and Chaos Engineering Lead. Conduct a stress-test audit on regional disaster recovery and business continuity.

# Files to Review
- `docs/11-disaster-recovery-business-continuity.md`
- `docs/04-central-observability-telemetry-compliance.md`
- `docs/09-edge-security-content-delivery-routing.md`
- `contracts/ssm-parameter-schema.json`

# Focus Areas & Stress Tests
1. **RTO (< 15 mins) & RPO (< 1 min) Feasibility**:
   - Validate whether the stated RTO and RPO targets are achievable for stateful components (Aurora Global DB, DynamoDB Global Tables, S3 Cross-Region Replication, AWS DRS).
2. **Route 53 Application Recovery Controller (ARC)**:
   - Audit Route 53 ARC routing controls: Is the 5-Region control plane quorum properly isolated from regional outages? Are safety rules configured to prevent accidental total-traffic blackholing?
3. **Failover Execution & Split-Brain Prevention**:
   - What is the step-by-step sequence during regional failover and failback? How is write fencing enforced to eliminate split-brain data corruption?
4. **Air-Gapped Ransomware Protection**:
   - Audit AWS Backup Vault Lock in Compliance Mode. How are backup copy jobs orchestrated across accounts/regions, and how is restore time validated?

# Required Output
- Step-by-step failover execution runbook matrix.
- Remediation diffs for `docs/11-disaster-recovery-business-continuity.md`.
```
