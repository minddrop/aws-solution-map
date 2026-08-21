# Executive Review Prompt: CTO & Enterprise Strategic Viability

```markdown
/goal 
# Role & Mandate
Act as an Enterprise Chief Technology Officer (CTO) and VP of Engineering. Review this enterprise AWS solution architecture blueprint from the perspective of strategic viability, organizational scaling, developer ergonomics, and operational sustainability.

# Files to Review
- `README.md`
- `iac-catalogs/modules-dependency-matrix.md`
- `docs/01-multi-account-landing-zone-network-fabric.md`
- `docs/07-compute-container-platforms.md`
- `docs/05-finops-cost-governance.md`

# Focus Areas & Strategic Evaluations
1. **Organizational Scalability & Cognitive Load**:
   - Does decomposing into 11 capability domains strike the right balance between clean separation of concerns vs excessive platform complexity?
   - What is the cognitive load on application development teams consuming this platform?
2. **Developer Experience (DevEx) & Time-to-Market**:
   - How fast can a product team spin up a new microservice or spoke VPC? Are baseline contracts and service mesh connections (VPC Lattice) intuitive and self-service?
3. **Vendor Lock-in vs Managed Value**:
   - Are open standards (OpenTelemetry, Apache Iceberg, Kubernetes/Gateway API, Terraform/OpenTofu) balanced appropriately with high-leverage AWS-managed capabilities (Bedrock, Aurora Serverless v2, Transit Gateway)?
4. **Target Operating Model & Team Topology**:
   - What platform team structure (Platform Engineering, SecOps, FinOps, SRE) is required to build, operate, and evolve this architecture in production?

# Required Output
- **Executive Leadership Decision Brief**: Strategic evaluation with Go / No-Go recommendation.
- **Platform Adoption & Governance Roadmap**: Phased rollout strategy balancing speed with governance.
```
