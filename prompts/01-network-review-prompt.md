# Deep-Dive Review Prompt: Network Architecture & Routing Topology

```markdown
/goal 
# Role & Mandate
Act as an AWS Principal Network Architect (CCIE/AWS Advanced Networking). Perform an in-depth packet flow and routing topology audit.

# Files to Review
- `contracts/network-cidr-ipam-allocations.md`
- `contracts/ssm-parameter-schema.json`
- `docs/01-multi-account-landing-zone-network-fabric.md`
- `docs/02-hybrid-multi-cloud-connectivity.md`
- `docs/09-edge-security-content-delivery-routing.md`

# Focus Areas & Stress Tests
1. **TGW Route Table Segmentation & Asymmetric Routing**:
   - Trace east-west (spoke-to-spoke), north-south (internet ingress/egress), and hybrid (on-prem to spoke) packet flows through Transit Gateway and AWS Network Firewall.
   - Are there asymmetric routing failure modes where SYN and ACK packets traverse different firewall endpoints across AZs?
2. **VPC Endpoints & DNS Split-Horizon Resolution**:
   - Evaluate centralized VPC Endpoints vs distributed VPC Endpoints. How are Route 53 Resolver Private Hosted Zones shared across member accounts without DNS loopbacks or cross-AZ latency penalties?
3. **Amazon VPC Lattice & Zero-Trust Service Mesh**:
   - How does VPC Lattice interoperate with Transit Gateway routing? Is SigV4 authentication enforced at the Lattice Service Network boundary?
4. **CIDR Allocation & IPAM Exhaustion**:
   - Verify subnet sizing in `contracts/network-cidr-ipam-allocations.md` across 3 AZs. Are EKS pod subnets, Karpenter dynamic node pools, and TGW attachment ENIs properly sized without exhaustion risks?

# Required Output
- Detailed packet-flow walkthroughs (with ASCII or Mermaid diagrams).
- Concrete routing table corrections (TGW route tables, VPC route tables, and Resolver rules).
```
