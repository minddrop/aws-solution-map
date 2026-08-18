# Domain 4: Central Observability, Telemetry & Compliance

## 1. Capability Scope & Service Taxonomy

### 1.1 Primary Purpose & Domain Boundaries
The Central Observability, Telemetry & Compliance domain provides unified, organization-wide visibility across logs, metrics, distributed traces, and audit events. It enforces immutable compliance retention, near-real-time streaming analytics, and automated alerting pipelines for Site Reliability Engineering (SRE) and Security Operations Center (SOC) teams.

The domain boundary encapsulates:
- **Audit & Forensic Logging**: AWS CloudTrail Organization Trail with multi-region delivery, immutable S3 Object Lock in Log Archive account, CloudTrail Lake event data stores, and AWS Config Organization Aggregators.
- **Cross-Account Telemetry Aggregation**: Amazon CloudWatch Cross-Account Observability (sink account configuration in Log/Monitoring account), enabling unified search, dashboarding, and composite alarms across hundreds of member accounts without data replication overhead.
- **Central Log Streaming & Search Fabric**: Amazon Kinesis Data Firehose pipelines ingesting VPC Flow Logs, Route 53 Resolver query logs, WAF access logs, and container logs into Amazon OpenSearch Service (or Datadog / Splunk HTTP Event Collector).
- **Distributed Tracing & APM**: AWS X-Ray and OpenTelemetry (ADOT - AWS Distro for OpenTelemetry) instrumentation for containerized and serverless workloads, forwarding traces to centralized X-Ray trace stores.
- **Compliance & Configuration Drift Auditing**: AWS Config rules (conformance packs for CIS Benchmark, SOC 2, HIPAA) with automated remediation triggers.

### 1.2 Core AWS Services & Modern Capabilities
- **AWS CloudTrail Lake**: SQL-queryable audit log store across all accounts with fine-grained retention and multi-region data capture.
- **CloudWatch Cross-Account Observability**: CloudWatch Logs, Metrics, and X-Ray traces queried centrally in a designated Monitoring account via CloudWatch Observability Access Manager (OAM).
- **Amazon OpenSearch Service & OpenSearch Serverless**: Scalable vector and text log indexing with UltraWarm and Cold storage tiering for petabyte-scale search.
- **AWS Distro for OpenTelemetry (ADOT)**: Standardized CNCF OpenTelemetry collectors deployed as EKS DaemonSets and ECS Sidecars for uniform trace/metric collection.
- **AWS Config Organization Aggregator & Conformance Packs**: Continuous configuration tracking, compliance scoring, and drift detection.
- **S3 Object Lock (Compliance Mode)**: WORM (Write Once, Read Many) storage enforcing legal hold and non-erasable audit logs for 7+ years.

---

## 2. IaC Repository Boundary & Inter-Module Contracts

### 2.1 Dedicated Repository Naming & Layout
- **Repository Name**: `terraform-aws-central-observability-compliance`
- **Engine**: Terraform >= 1.9.0 with AWS Provider >= 5.60.0

```
terraform-aws-central-observability-compliance/
├── .github/
│   └── workflows/
│       ├── lint-validate.yml
│       └── dashboards-test.yml
├── config/
│   ├── log-archive-retention.tfvars
│   ├── opensearch-cluster.tfvars
│   └── config-conformance-packs.tfvars
├── modules/
│   ├── cloudtrail-lake-org/
│   │   ├── main.tf
│   │   ├── event_data_stores.tf
│   │   ├── queries.tf
│   │   └── outputs.tf
│   ├── cloudwatch-cross-account-oam/
│   │   ├── oam_sink.tf
│   │   ├── oam_links.tf
│   │   ├── composite_alarms.tf
│   │   └── outputs.tf
│   ├── opensearch-log-analytics/
│   │   ├── main.tf
│   │   ├── vpc_endpoints.tf
│   │   ├── index_state_management.tf
│   │   ├── dashboards.tf
│   │   └── outputs.tf
│   ├── kinesis-firehose-ingestion/
│   │   ├── firehose_streams.tf
│   │   ├── data_transformation_lambda.tf
│   │   └── outputs.tf
│   ├── aws-config-org-aggregator/
│   │   ├── main.tf
│   │   ├── conformance_packs.tf
│   │   └── remediation_rules.tf
│   └── adot-collector-baseline/
│       ├── collectors_config.yaml
│       ├── iam_roles.tf
│       └── outputs.tf
├── live/
│   ├── log-archive-account/
│   │   ├── terragrunt.hcl
│   │   └── main.tf
│   ├── monitoring-shared-account/
│   │   ├── terragrunt.hcl
│   │   └── main.tf
│   └── member-account-links/
│       ├── terragrunt.hcl
│       └── main.tf
├── tests/
│   └── oam_link_verification_test.go
├── versions.tf
└── README.md
```

### 2.2 Cross-Module Contracts & Dependencies

#### SSM Parameter Store Exports:
| Parameter Path | Type | Consumer / Scope | Purpose |
| :--- | :--- | :--- | :--- |
| `/enterprise/observability/oam/sink-arn` | String | All Member Accounts | CloudWatch OAM Sink ARN to link member telemetry to central monitoring |
| `/enterprise/observability/s3/log-archive-bucket-arn` | String | All Workload Accounts | WORM S3 Bucket ARN for centralized CloudTrail, VPC Flow, and access log archiving |
| `/enterprise/observability/opensearch/endpoint-url` | String | Workload / Platform Ingestion | OpenSearch HTTPS endpoint for log streaming pipelines |
| `/enterprise/observability/kinesis/waf-logs-stream-arn` | String | Domain 9 (Edge Security & WAF) | Kinesis Firehose ARN for WAF traffic log ingestion |
| `/enterprise/compliance/config/aggregator-name` | String | Security / Audit Teams | Name of AWS Config Organization Aggregator |

#### Remote State & Inter-Module Dependencies:
- **Upstream Dependencies**: Domain 1 (`terraform-aws-landing-zone-network-fabric` for Log Archive & Shared Services VPCs), Domain 3 (`terraform-aws-central-identity-kms-security` for KMS CMKs).
- **Downstream Consumers**: Domain 7 (Compute/EKS container logging), Domain 8 (EventBridge audit tracing), Domain 9 (WAF/CloudFront access logs), Domain 10 (Bedrock model invocation logs).

#### IAM Baseline Assumptions:
- CloudWatch Logs Cross-Account Subscription filters permitted to assume `arn:aws:iam::<LogArchiveAccount>:role/CWLogsCentralFirehoseRole`.
- S3 Bucket Policy in Log Archive strictly enforces `s3:PutObject` with KMS encryption and denies `s3:DeleteObject` or `s3:PutBucketPolicy` (governed by S3 Object Lock Compliance Mode).

---

## 3. Architecture Topology Diagram

```mermaid
flowchart TB
    subgraph Workload_Accounts["Spoke Workload Accounts (Prod / Non-Prod / Shared)"]
        subgraph Workload_Compute["Workload Tier"]
            EKS_Pods["EKS Pods (FluentBit / ADOT Collector)"]
            Lambda_Apps["Lambda Functions / ECS Tasks"]
            RDS_DB["Aurora / RDS DB Engines"]
        end

        subgraph Local_Observability["Local CloudWatch Telemetry"]
            CW_Logs_Local["Local CloudWatch Log Groups"]
            CW_Metrics_Local["Local CloudWatch Metrics"]
            XRay_Traces_Local["AWS X-Ray Local Traces"]
            CW_OAM_Link["CloudWatch OAM Link (Observability Link)"]
        end

        Workload_Compute --> CW_Logs_Local & CW_Metrics_Local & XRay_Traces_Local
        CW_Logs_Local & CW_Metrics_Local & XRay_Traces_Local --> CW_OAM_Link
    end

    subgraph Monitoring_Central_Account["Central Monitoring & Observability Account"]
        CW_OAM_Sink["CloudWatch OAM Central Sink"]
        CW_Central_Dashboards["Centralized Unified Dashboards"]
        CW_Composite_Alarms["Cross-Account Composite Alarms"]
        
        subgraph Log_Analytics_Platform["Log Analytics & Search Engine"]
            Kinesis_Firehose["Amazon Kinesis Data Firehose (Batch/Compress)"]
            OpenSearch_Cluster["Amazon OpenSearch Service (VPC Managed)"]
            OpenSearch_Dashboards["OpenSearch Dashboards / SIEM"]
        end

        CW_OAM_Link -->|Cross-Account Telemetry Query (No Data Duplication)| CW_OAM_Sink
        CW_OAM_Sink --> CW_Central_Dashboards & CW_Composite_Alarms
        Kinesis_Firehose -->|Parquet / JSON Indexing| OpenSearch_Cluster --> OpenSearch_Dashboards
    end

    subgraph Log_Archive_Compliance_Account["Log Archive Account (Strict Compliance WORM)"]
        CloudTrail_Lake["AWS CloudTrail Lake (Org Event Data Store)"]
        
        subgraph S3_Compliance_Vault["Immutable S3 Data Vault (Object Lock Compliance Mode)"]
            S3_CloudTrail_Logs["CloudTrail Org Trail (Global Multi-Region)"]
            S3_VPC_Flow_Logs["VPC Flow Logs (Aggregated Parquet)"]
            S3_WAF_DNS_Logs["WAF & Route 53 Resolver Logs"]
            S3_Archival_Glacier["Glacier Deep Archive (7+ Year Retention)"]
        end

        Config_Aggregator["AWS Config Org Aggregator & Conformance Packs"]
    end

    %% Audit ingestion
    Workload_Accounts -.->|Audit Data Events| CloudTrail_Lake
    Workload_Accounts -.->|Direct Flow Log Export| S3_VPC_Flow_Logs
    CW_Logs_Local -->|Subscription Filter| Kinesis_Firehose
    S3_Compliance_Vault -->|Lifecycle Policy (180 Days)| S3_Archival_Glacier
```

---

## 4. Expert Architectural Review & Trade-off Critique

### 4.1 Well-Architected Assessment
- **Security**:
  - *Immutability & Forensic Integrity*: CloudTrail logs and audit trails are delivered directly to the dedicated Log Archive account with S3 Object Lock in Compliance Mode (cannot be overwritten or deleted even by the root AWS account).
  - *Data Encryption*: Dedicated KMS CMK with cross-account grants encrypts all CloudTrail, Firehose, and OpenSearch stores.
- **Reliability**:
  - *Resilient Query Architecture*: CloudWatch Cross-Account Observability (OAM) decouples telemetry queries from streaming ingestion pipelines; if streaming infrastructure undergoes maintenance, SREs still maintain full real-time metric/log visibility via the AWS native plane.
  - *OpenSearch Multi-AZ with Standby*: OpenSearch domain configured with 3 Master nodes and 3 Data nodes across 3 AZs with automated index state management (ISM).
- **Operational Excellence**:
  - *CloudTrail Lake SQL Analytics*: Eliminates Athena ETL pipeline setup for ad-hoc SOC queries; provides sub-minute SQL queries across years of enterprise CloudTrail event history.
  - *Composite Alarms*: Aggregates infrastructure and application metrics to prevent alarm fatigue (e.g., alert fires only if CPU > 85% AND HTTP 5xx Error Rate > 2% simultaneously).
- **Cost Optimization**:
  - *CloudWatch Cross-Account OAM vs Log Copying*: OAM queries data in-place without duplicating log storage across accounts, saving tens of thousands of dollars monthly in cross-account data transfer and redundant ingestion fees.
  - *OpenSearch UltraWarm & Cold Storage*: Moves aged indices (> 7 days) to UltraWarm (backed by S3) and > 30 days to Cold storage, slashing OpenSearch compute/EBS storage costs by over 70%.

### 4.2 Critical Architectural Risks & Mitigations

#### Risk 1: CloudWatch Logs Ingestion Throttling & Silent Data Loss
- **Failure Mechanism**: A sudden traffic spike or runaway debug logging event triggers severe rate-limiting on CloudWatch Logs ingestion APIs (`PutLogEvents` throttled at the account/region level), leading to buffer overflows and lost application telemetry in FluentBit / ADOT collectors.
- **Mitigation Strategy**:
  1. Implement Kinesis Data Firehose with client-side buffer persistence (e.g., FluentBit disk buffering with `storage.type filesystem`).
  2. Configure CloudWatch Logs dynamic retention and rate-limit alarms (`IncomingBytesExceeded`), with backpressure handling in the ADOT collector.

#### Risk 2: OpenSearch Cluster Storage Exhaustion and Index Locking (Read-Only Lock)
- **Failure Mechanism**: Rapid surge in uncompressed VPC flow or application logs exceeds 85% of OpenSearch EBS disk capacity. OpenSearch automatically flips the cluster into `read_only_allow_delete` mode, dropping incoming Firehose log streams and halting SOC visibility.
- **Mitigation Strategy**:
  1. Implement OpenSearch Index State Management (ISM) policies that rollover indices by size (e.g., 50GB per primary shard) and migrate to UltraWarm when disk reaches 70%.
  2. Configure Kinesis Firehose S3 backup delivery stream: If OpenSearch indexing fails or throttles, Firehose automatically diverts failed payloads to an S3 error recovery bucket for replay.
