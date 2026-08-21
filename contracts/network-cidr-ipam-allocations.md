# Enterprise IPAM CIDR Allocation & Subnet Architecture

## 1. Global IPAM Hierarchy (IPv4 & IPv6 Dual-Stack)

```
+----------------------------------------------------------------------------------------------------+
|                                    Enterprise IPAM Root Pool                                       |
|                                     10.0.0.0/8 | 2001:db8:1000::/40                                |
+-------------------------------------------------+--------------------------------------------------+
                                                  |
         +----------------------------------------+----------------------------------------+
         |                                                                                 |
+--------v------------------------------------+                   +------------------------v-------------------+
|       Primary Region: us-east-1             |                   |       Secondary Region: us-west-2          |
|       10.100.0.0/12 | 2001:db8:1100::/44    |                   |       10.200.0.0/12 | 2001:db8:1200::/44   |
+--------+------------------------------------+                   +------------------------+-------------------+
         |                                                                                 |
   +-----+-------------------------------+                                           +-----+--------------------+
   |                                     |                                           |                          |
+--v--------------------+     +----------v----------+                             +--v--------------------+  +--v-------------------+
| Network Hub / Core    |     | Spoke Workloads     |                             | DR Network Hub        |  | DR Spoke Workloads   |
| 10.254.0.0/16         |     | 10.100.0.0/14       |                             | 10.255.0.0/16         |  | 10.200.0.0/14        |
| 2001:db8:11fe::/48    |     | 2001:db8:1100::/48  |                             | 2001:db8:12fe::/48    |  | 2001:db8:1200::/48   |
+-----------------------+     +---------------------+                             +-----------------------+  +----------------------+
```

---

## 2. Regional CIDR Breakdown (us-east-1)

### 2.1 Network Hub Account (10.254.0.0/16)
| Subnet / VPC Function | IPv4 CIDR Allocation by AZ | IPv6 Block | AZ Distribution | Route Table Association |
| :--- | :--- | :--- | :--- | :--- |
| **Inspection VPC (TGW Attachment)** | AZ-A: `10.254.16.0/28`<br/>AZ-B: `10.254.16.16/28`<br/>AZ-C: `10.254.16.32/28` | `/64` per AZ | Multi-AZ (3 AZs) | `rtb-tgw-inspect-attach` *(Appliance Mode Enabled)* |
| **Inspection VPC (NFW Endpoints)** | AZ-A: `10.254.16.48/28`<br/>AZ-B: `10.254.16.64/28`<br/>AZ-C: `10.254.16.80/28` | `/64` per AZ | Multi-AZ (3 AZs) | `rtb-nfw-inspection` |
| **Central Egress VPC (NAT Gateways)** | AZ-A: `10.254.32.0/26`<br/>AZ-B: `10.254.32.64/26`<br/>AZ-C: `10.254.32.128/26` | `/64` per AZ | Multi-AZ (3 AZs) | `rtb-egress-public-igw` |
| **Central Egress VPC (TGW Attachment)** | AZ-A: `10.254.33.0/28`<br/>AZ-B: `10.254.33.16/28`<br/>AZ-C: `10.254.33.32/28` | `/64` per AZ | Multi-AZ (3 AZs) | `rtb-egress-tgw-attach` |
| **Route 53 Inbound Resolver Endpoints** | AZ-A: `10.254.0.0/28` (`10.254.0.4`)<br/>AZ-B: `10.254.0.16/28` (`10.254.0.20`)<br/>AZ-C: `10.254.0.32/28` (`10.254.0.36`) | `/64` per AZ | Multi-AZ (3 AZs) | `rtb-dns-resolver` |
| **Route 53 Outbound Resolver Endpoints**| AZ-A: `10.254.0.64/28` (`10.254.0.68`)<br/>AZ-B: `10.254.0.80/28` (`10.254.0.84`)<br/>AZ-C: `10.254.0.96/28` (`10.254.0.100`)| `/64` per AZ | Multi-AZ (3 AZs) | `rtb-dns-resolver` |

### 2.2 Shared Services Account (10.253.0.0/16)
| Subnet / VPC Function | IPv4 CIDR Allocation by AZ | IPv6 Block | AZ Distribution | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| **Central Interface VPC Endpoints** | AZ-A: `10.253.1.0/26`<br/>AZ-B: `10.253.1.64/26`<br/>AZ-C: `10.253.1.128/26` | `/64` per AZ | Multi-AZ (3 AZs) | SSM, KMS, ECR, S3 Interface (Hybrid only) |
| **Shared CI/CD Runners & Vault** | AZ-A: `10.253.10.0/24`<br/>AZ-B: `10.253.11.0/24`<br/>AZ-C: `10.253.12.0/24` | `/64` per AZ | Multi-AZ (3 AZs) | Self-hosted GitHub runners, SonarQube |

### 2.3 Production Workload Spoke VPC (10.100.0.0/16)
| Subnet Tier | IPv4 CIDR Allocation by AZ | IPv6 Block | AZ Allocation | Purpose / Target Resources |
| :--- | :--- | :--- | :--- | :--- |
| **Transit Gateway Attachment Subnets** | AZ-A: `10.100.0.0/28`<br/>AZ-B: `10.100.0.16/28`<br/>AZ-C: `10.100.0.32/28` | `/64` per AZ | Multi-AZ (3 AZs) | Dedicated TGW ENIs (No workloads) |
| **Public / Ingress Load Balancer Subnets** | AZ-A: `10.100.1.0/26`<br/>AZ-B: `10.100.1.64/26`<br/>AZ-C: `10.100.1.128/26` | `/64` per AZ | Multi-AZ (3 AZs) | Application Load Balancers (Ingress from Edge) |
| **Application Compute Subnets (EKS/ECS)** | AZ-A: `10.100.16.0/22`<br/>AZ-B: `10.100.20.0/22`<br/>AZ-C: `10.100.24.0/22` | `/64` per AZ | Multi-AZ (3 AZs) | EKS Worker Nodes, Fargate Tasks, Karpenter Pods |
| **Database & Persistence Subnets** | AZ-A: `10.100.32.0/24`<br/>AZ-B: `10.100.33.0/24`<br/>AZ-C: `10.100.34.0/24` | `/64` per AZ | Multi-AZ (3 AZs) | Aurora Serverless v2, ElastiCache Redis, RDS Proxy |

*Note: All Spoke VPCs configure free local **S3 and DynamoDB Gateway VPC Endpoints** in their local subnet route tables. High-throughput lakehouse and object storage traffic never crosses the Transit Gateway.*

---

## 3. Transit Gateway & VPC Lattice Routing Topology

```
+-----------------------------------------------------------------------------------------------------------------+
| Transit Mechanism | Scope & Target Traffic                  | Security Inspection Mechanism | Routing Protocol / Path |
+-------------------+-----------------------------------------+-------------------------------+-------------------------+
| AWS Transit       | North-South Internet Egress,            | Centralized AWS Network       | BGP Dynamic Routing &   |
| Gateway (TGW)     | Hybrid DX/Cloud WAN, Legacy Subnets     | Firewall (DPI + TLS Proxy)    | Static Appliance Route  |
+-------------------+-----------------------------------------+-------------------------------+-------------------------+
| Amazon VPC        | East-West Microservice-to-Microservice  | SigV4 IAM Auth Policies +     | Layer 7 HTTP/2 & gRPC   |
| Lattice Mesh      | Cross-Account Communication (EKS/ECS)   | AWS WAF Association           | Private DNS Resolution  |
+-------------------+-----------------------------------------+-------------------------------+-------------------------+
```

### 3.1 Transit Gateway Route Table Matrix
```
+-----------------------------------------------------------------------------------------------------------------+
| TGW Route Table   | Associated Attachments                  | Propagated Attachments   | Static Blackhole / Routes     |
+-------------------+-----------------------------------------+--------------------------+-------------------------------+
| Spoke-RT          | Prod Spoke VPC, NonProd Spoke VPC       | None                     | 0.0.0.0/0 -> Inspection VPC   |
|                   |                                         |                          | 10.0.0.0/8 -> Inspection VPC  |
+-------------------+-----------------------------------------+--------------------------+-------------------------------+
| Inspection-RT     | Inspection VPC Attachment               | None                     | Return to Post-Inspection-RT  |
+-------------------+-----------------------------------------+--------------------------+-------------------------------+
| Post-Inspection-RT| NFW Egress Return                       | Spoke VPCs, Shared Svcs  | 0.0.0.0/0 -> Egress VPC       |
|                   |                                         | DX Gateway, Cloud WAN    |                               |
+-------------------+-----------------------------------------+--------------------------+-------------------------------+
| Egress-RT         | Egress VPC Attachment                   | Spoke VPCs, Shared Svcs  | None (Direct Return to Spokes)|
+-------------------+-----------------------------------------+--------------------------+-------------------------------+
```
*Note: Return internet traffic from the Central Egress VPC is propagated directly to Spoke VPC attachments via `Egress-RT`, preventing circular re-inspection in NFW and eliminating asymmetric state drops.*

