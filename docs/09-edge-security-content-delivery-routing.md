# Domain 9: Edge Security, Content Delivery & Routing

## 1. Capability Scope & Service Taxonomy

### 1.1 Primary Purpose & Domain Boundaries
The Edge Security, Content Delivery & Routing domain establishes the global perimeter defense, ultra-low latency static and dynamic content delivery, DDoS mitigation, and multi-region traffic routing. It inspects all ingress traffic at AWS edge locations worldwide before requests ever reach origin infrastructure in regional VPCs.

The domain boundary encapsulates:
- **Global Content Delivery & Edge Compute**: Amazon CloudFront distributions with Origin Shield, CloudFront Functions (sub-millisecond header sanitization and URL rewriting), and Lambda@Edge.
- **Layer 7 Application Security (AWS WAF)**: Web ACLs with AWS Managed Rules (Core Rule Set, SQL Injection, Known Bad Inputs, Bot Control, Account Takeover Prevention [ATP]), custom rate-limiting rules, and staged Count-to-Block deployment lifecycles.
- **Layer 3/4 Distributed DDoS Protection**: AWS Shield Advanced with automatic application layer DDoS mitigation, proactive engagement by the AWS Shield Response Team (SRT), and cost protection against DDoS-induced scaling spikes.
- **Global DNS & Intelligent Traffic Steering**: Amazon Route 53 Public Hosted Zones with Geolocation, Latency-Based, and Multi-Region Health-Checked Failover Routing policies, paired with DNSSEC for origin validation.
- **Origin Access Control (OAC) & Prefix List Cloaking**: Enforced cryptographic SigV4 signing and AWS CloudFront Managed Prefix List (`pl-cloudfront-origin`) security group enforcement on Application Load Balancers.

### 1.2 Core AWS Services & Modern Capabilities
- **Amazon CloudFront & Origin Shield**: Global caching tier with centralized regional mid-tier caching to maximize origin offload (> 95%).
- **AWS WAF (Bot Control & ATP)**: ML-driven bot classification, CAPTCHA challenges, and token-based rate limiting with managed WCU allocation.
- **AWS Shield Advanced**: DDoS protection covering CloudFront, Route 53, ALB, and Global Accelerator with 24/7 SRT support.
- **CloudFront Functions**: Sub-millisecond serverless compute at 600+ PoPs worldwide for cache key normalization and security header enforcement.
- **Amazon Route 53 Latency / Failover Routing**: Dynamic DNS routing steering users to the nearest healthy AWS region.
- **CloudFront Origin Access Control (OAC)**: SigV4-based authentication for S3 and ALB origins.

---

## 2. IaC Repository Boundary & Inter-Module Contracts

### 2.1 Dedicated Repository Naming & Layout
- **Repository Name**: `terraform-aws-edge-security-routing`
- **Engine**: Terraform >= 1.9.0 with AWS Provider >= 5.60.0

```
terraform-aws-edge-security-routing/
├── .github/
│   └── workflows/
│       ├── lint-validate.yml
│       └── waf-rule-syntax-test.yml
├── config/
│   ├── public-edge-waf.tfvars
│   ├── cloudfront-distribution.tfvars
│   └── route53-global-routing.tfvars
├── modules/
│   ├── waf-global-webacl/
│   │   ├── main.tf
│   │   ├── managed_rule_groups.tf
│   │   ├── rate_limiting_rules.tf
│   │   ├── staging_count_mode.tf
│   │   ├── logging.tf
│   │   └── outputs.tf
│   ├── cloudfront-edge-distribution/
│   │   ├── main.tf
│   │   ├── cache_policies.tf
│   │   ├── oac_signing.tf
│   │   ├── cloudfront_functions.tf
│   │   ├── origins.tf
│   │   └── outputs.tf
│   ├── shield-advanced-protection/
│   │   ├── protections.tf
│   │   ├── srt_access.tf
│   │   └── outputs.tf
│   ├── route53-global-dns/
│   │   ├── public_zones.tf
│   │   ├── latency_records.tf
│   │   ├── failover_health_checks.tf
│   │   ├── dnssec.tf
│   │   └── outputs.tf
│   └── edge-tls-certificates/
│       ├── acm_global.tf
│       ├── acm_regional.tf
│       └── outputs.tf
├── live/
│   ├── edge-global-us-east-1/
│   │   ├── terragrunt.hcl
│   │   └── main.tf
│   └── edge-prod-workloads/
│       ├── terragrunt.hcl
│       └── main.tf
├── tests/
│   └── waf_simulation_test.go
├── versions.tf
└── README.md
```

### 2.2 Cross-Module Contracts & Dependencies

#### SSM Parameter Store Exports:
| Parameter Path | Type | Consumer / Scope | Purpose |
| :--- | :--- | :--- | :--- |
| `/enterprise/edge/waf/global-webacl-arn` | String | CloudFront Modules | Global AWS WAF Web ACL ARN (must be in `us-east-1`) |
| `/enterprise/edge/cloudfront/distribution-id` | String | DNS / Route 53 Modules | Primary public CloudFront Distribution ID |
| `/enterprise/edge/route53/public-zone-id` | String | Workload App Deployments | Authoritative Route 53 Public Hosted Zone ID |
| `/enterprise/edge/acm/global-wildcard-cert-arn` | String | CloudFront Distributions | ACM SSL/TLS Certificate ARN (`us-east-1`) |

#### Remote State & Inter-Module Dependencies:
- **Upstream Dependencies**: Domain 1 (`terraform-aws-landing-zone-network-fabric` for Ingress ALB endpoints), Domain 4 (Kinesis Firehose for WAF log streaming).
- **Downstream Consumers**: Domain 7 (Compute ALBs as backend origins), Domain 10 (Public AI Assistant Endpoints), Domain 11 (Route 53 ARC failover coordination).

#### IAM Baseline Assumptions:
- WAF logging configured to stream directly to Kinesis Firehose in Log Archive account.
- ALB Origin Security Groups restrict ingress solely to AWS CloudFront managed prefix lists (`aws:ec2:prefix-list/pl-cloudfront-origin`).

---

## 3. Architecture Topology Diagram

```mermaid
flowchart TB
    subgraph Global_Internet_Users["Global Client & Internet Layer"]
        End_Users["Global Users & Mobile Clients"]
        Malicious_Actors["DDoS / Bot Traffic / Scrapers"]
    end

    subgraph AWS_Edge_Infrastructure["AWS Global Edge Infrastructure (600+ PoPs Worldwide)"]
        
        subgraph DNS_and_DDoS_Shield["Edge Routing & DDoS Shield"]
            Route53_DNS["Amazon Route 53 (Latency & Health-Checked DNS + DNSSEC)"]
            Shield_Advanced["AWS Shield Advanced (L3/L4 Automatic DDoS Mitigation)"]
        end

        subgraph CloudFront_WAF_Edge["CloudFront & Layer 7 Edge Security"]
            WAF_Edge["AWS WAF (Bot Control, Rate Limiting, OWASP Top 10)"]
            CF_Functions["CloudFront Functions (Header Injection & Cache Normalization)"]
            CloudFront_Dist["Amazon CloudFront CDN (Global Edge Caching)"]
            Origin_Shield["CloudFront Origin Shield (Regional Aggregator)"]
            OAC_Signer["Origin Access Control (OAC SigV4 Signing)"]
        end

    end

    subgraph AWS_Region_Primary["AWS Region: us-east-1 (Primary Workload Origin)"]
        subgraph Primary_Ingress_Tier["Primary Regional Origin"]
            ALB_Primary["Application Load Balancer (SG: pl-cloudfront-origin)"]
            EKS_Primary_Ingress["EKS Ingress Gateway / Pods"]
            S3_Static_Origin["S3 Bucket: Static Web Assets (Encrypted OAC)"]
        end
    end

    subgraph AWS_Region_Secondary["AWS Region: us-west-2 (Standby DR Origin)"]
        subgraph Secondary_Ingress_Tier["Standby Regional Origin"]
            ALB_Secondary["Application Load Balancer (Standby - SG: pl-cloudfront-origin)"]
            EKS_Secondary_Ingress["EKS Ingress Standby Pods"]
        end
    end

    %% Edge Traffic Flows
    End_Users & Malicious_Actors -->|DNS Resolution Query| Route53_DNS
    End_Users & Malicious_Actors -->|HTTPS Request| CloudFront_Dist
    
    CloudFront_Dist --- Shield_Advanced
    CloudFront_Dist --> WAF_Edge
    WAF_Edge -->|Allow Valid Requests| CF_Functions
    WAF_Edge -.->|Block Malicious / Rate-Exceeded| Malicious_Actors
    
    CF_Functions --> CloudFront_Dist
    CloudFront_Dist --> Origin_Shield
    Origin_Shield --> OAC_Signer

    %% Origin Routing Flows
    OAC_Signer -->|SigV4 Signed Origin Request| ALB_Primary
    OAC_Signer -->|Secure Bucket GetObject| S3_Static_Origin
    ALB_Primary --> EKS_Primary_Ingress

    %% Failover origin routing
    Route53_DNS -.->|On Primary Region Failure (Sub-10s)| ALB_Secondary
    Origin_Shield -.->|CloudFront Origin Group Failover (5xx Codes)| ALB_Secondary
    ALB_Secondary --> EKS_Secondary_Ingress
```

---

## 4. Expert Architectural Review & Trade-off Critique

### 4.1 Well-Architected Assessment
- **Security**:
  - *Origin Cloaking via Prefix Lists & OAC*: Origin Load Balancers accept connections exclusively from the AWS CloudFront Managed Prefix List (`pl-cloudfront-origin`). OAC signs requests with SigV4, entirely blocking direct IP bypass attacks.
  - *Intelligent Bot Control*: WAF Bot Control detects automated scrapers and credential stuffing at the edge.
- **Reliability**:
  - *Origin Group High-Availability Failover*: CloudFront Origin Groups automatically switch to the secondary DR region origin on `5xx` error codes.
  - *Shield Advanced Automatic Mitigation*: Identifies L7 flood patterns and generates real-time WAF rate-limiting rules without manual intervention.
- **Operational Excellence**:
  - *Staged WAF Rule Pipeline*: Deploys new custom WAF rules in `Count` mode for 7 days before automated transition to `Block`.
- **Cost Optimization**:
  - *Origin Shield Cache Aggregation*: Origin Shield consolidates multi-PoP cache misses, reducing origin requests by over 90%.

### 4.2 Critical Architectural Risks & Mitigations

#### Risk 1: Aggressive WAF Rule Misconfiguration Causing Legitimate Customer Outage
- **Failure Mechanism**: A newly deployed WAF rate-limiting rule drops valid B2B API traffic globally with HTTP 403.
- **Mitigation Strategy**:
  1. Mandate that all new WAF rules deploy in `Count` mode for at least 7 days before switching to `Block`.
  2. Implement CI/CD synthetic testing validating representative API payloads against WAF staging.

#### Risk 2: CloudFront Cache Poisoning via Unkeyed Headers
- **Failure Mechanism**: Origin application uses unkeyed headers (`X-Forwarded-Host`) to render scripts; attackers poison the global cache.
- **Mitigation Strategy**:
  1. Enforce strict CloudFront Cache Policies forwarding only explicitly allowed headers to the cache key.
  2. Strip untrusted client headers at the edge using CloudFront Functions.
