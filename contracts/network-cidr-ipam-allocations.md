# Enterprise IPAM CIDR Allocation & Subnet Architecture

## 1. Global IPAM Hierarchy

```
+----------------------------------------------------------------------------------------------------+
|                                    Enterprise IPAM Root Pool                                       |
|                                         10.0.0.0/8                                                 |
+-------------------------------------------------+--------------------------------------------------+
                                                  |
         +----------------------------------------+----------------------------------------+
         |                                                                                 |
+--------v------------------------------------+                   +------------------------v-------------------+
|       Primary Region: us-east-1             |                   |       Secondary Region: us-west-2          |
|             10.100.0.0/12                   |                   |              10.200.0.0/12                 |
+--------+------------------------------------+                   +------------------------+-------------------+
         |                                                                                 |
   +-----+-------------------------------+                                           +-----+--------------------+
   |                                     |                                           |                          |
+--v--------------------+     +----------v----------+                             +--v--------------------+  +--v-------------------+
| Network Hub / Core    |     | Spoke Workloads     |                             | DR Network Hub        |  | DR Spoke Workloads   |
| 10.254.0.0/16         |     | 10.100.0.0/14       |                             | 10.255.0.0/16         |  | 10.200.0.0/14        |
+-----------------------+     +---------------------+                             +-----------------------+  +----------------------+
```

---

## 2. Regional CIDR Breakdown (us-east-1)

### 2.1 Network Hub Account (10.254.0.0/16)
| Subnet / VPC Function | CIDR Block | AZ Distribution | Route Table Association |
| :--- | :--- | :--- | :--- |
| **Inspection VPC (TGW Attachment)** | `10.254.16.0/28` | AZ-A, AZ-B, AZ-C | `rtb-tgw-inspect-attach` |
| **Inspection VPC (NFW Endpoints)** | `10.254.16.16/28` | AZ-A, AZ-B, AZ-C | `rtb-nfw-inspection` |
| **Central Egress VPC (NAT Gateways)** | `10.254.32.0/24` | AZ-A, AZ-B, AZ-C | `rtb-egress-public-igw` |
| **Central Egress VPC (TGW Attachment)** | `10.254.33.0/28` | AZ-A, AZ-B, AZ-C | `rtb-egress-tgw-attach` |
| **Route 53 Inbound Resolver Endpoints** | `10.254.0.0/26` | AZ-A (`10.254.0.4`), AZ-B (`10.254.0.68`) | `rtb-dns-resolver` |
| **Route 53 Outbound Resolver Endpoints**| `10.254.0.64/26`| AZ-A (`10.254.0.132`), AZ-B (`10.254.0.196`)| `rtb-dns-resolver` |

### 2.2 Shared Services Account (10.253.0.0/16)
| Subnet / VPC Function | CIDR Block | AZ Distribution | Purpose |
| :--- | :--- | :--- | :--- |
| **Central Interface VPC Endpoints** | `10.253.1.0/24` | Multi-AZ (3 AZs) | SSM, KMS, ECR, S3 Interface Endpoints |
| **Shared CI/CD Runners & Vault** | `10.253.10.0/23` | Multi-AZ (3 AZs) | Self-hosted GitHub runners, SonarQube |

### 2.3 Production Workload Spoke VPC (10.100.0.0/16)
| Subnet Tier | CIDR Block | AZ Allocation | Purpose / Target Resources |
| :--- | :--- | :--- | :--- |
| **Transit Gateway Attachment Subnets** | `10.100.0.0/28` | AZ-A, AZ-B, AZ-C | Dedicated TGW ENIs (No workloads) |
| **Public / Ingress Load Balancer Subnets** | `10.100.1.0/24` | AZ-A, AZ-B, AZ-C | Application Load Balancers (Ingress from Edge) |
| **Application Compute Subnets (EKS/ECS)** | `10.100.16.0/20` | AZ-A, AZ-B, AZ-C | EKS Worker Nodes, Fargate Tasks, Karpenter Pods |
| **Database & Persistence Subnets** | `10.100.32.0/21` | AZ-A, AZ-B, AZ-C | Aurora Serverless v2, ElastiCache Redis, RDS Proxy |

---

## 3. Transit Gateway Route Table Matrix

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
| Egress-RT         | Egress VPC Attachment                   | None                     | 10.0.0.0/8 -> Inspection VPC  |
+-------------------+-----------------------------------------+--------------------------+-------------------------------+
```
