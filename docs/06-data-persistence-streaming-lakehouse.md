# Domain 6: Data Persistence, Streaming & Lakehouse Foundations

## 1. Capability Scope & Service Taxonomy

### 1.1 Primary Purpose & Domain Boundaries
The Data Persistence, Streaming & Lakehouse Foundations domain establishes the core multi-model database tier, real-time event streaming pipelines, and unified lakehouse architecture. It delivers sub-millisecond key-value caching, relational transactional ACID consistency, petabyte-scale analytical query engines, and centralized data governance.

The domain boundary encapsulates:
- **Relational OLTP & Global Data Stores**: Amazon Aurora Serverless v2 (PostgreSQL / MySQL) with Multi-AZ clusters, Aurora Global Database for cross-region disaster recovery, and regional RDS Proxies (primary and standby DR).
- **Ultra-Low Latency NoSQL & In-Memory Caching**: Amazon DynamoDB with Global Tables (active-active multi-region), Point-In-Time Recovery (PITR), and Amazon ElastiCache for Redis for distributed microservice caching.
- **Real-Time Streaming Ingestion**: Amazon Managed Streaming for Apache Kafka (MSK Serverless / Provisioned with Tiered Storage) with native MSK Multi-VPC PrivateLink connectivity.
- **Lakehouse Foundation & Modern Storage Formats**: Amazon S3 Data Lake structured in Medallion Architecture (Bronze, Silver, Gold) with Apache Iceberg ACID open table format and automated compaction jobs.
- **Data Cataloging & Governance**: AWS Glue Data Catalog, AWS Lake Formation (Tag-Based Access Control LF-TBAC), and Amazon Athena Serverless.

### 1.2 Core AWS Services & Modern Capabilities
- **Amazon Aurora Serverless v2**: Instant scaling in fine-grained ACUs (0.5 to 128 ACU) with zero connection drops.
- **Amazon RDS Proxy**: Connection multiplexing with standby proxy instances pre-configured in DR regions.
- **Amazon DynamoDB (Global Tables & PITR)**: Multi-region active-active replication with sub-second replication latency.
- **Amazon MSK & Multi-VPC PrivateLink**: Managed Kafka with Tiered Storage (S3 backing), IAM authentication, and cross-account PrivateLink access.
- **AWS Lake Formation**: LF-TBAC, dynamic column masking, and centralized cross-account sharing via AWS RAM.
- **Apache Iceberg on AWS S3 & Glue**: ACID transactions, schema evolution, and automated compaction maintenance.

---

## 2. IaC Repository Boundary & Inter-Module Contracts

### 2.1 Dedicated Repository Naming & Layout
- **Repository Name**: `terraform-aws-data-persistence-lakehouse`
- **Engine**: Terraform >= 1.9.0 with AWS Provider >= 5.60.0

```
terraform-aws-data-persistence-lakehouse/
├── .github/
│   └── workflows/
│       ├── lint-validate.yml
│       └── schema-contract-test.yml
├── config/
│   ├── aurora-postgresql.tfvars
│   ├── dynamodb-tables.tfvars
│   ├── msk-streaming.tfvars
│   └── lakehouse-medallion.tfvars
├── modules/
│   ├── aurora-serverless-v2/
│   │   ├── main.tf
│   │   ├── cluster_parameter_groups.tf
│   │   ├── rds_proxy_primary.tf
│   │   ├── rds_proxy_standby_dr.tf
│   │   ├── auto_scaling.tf
│   │   └── outputs.tf
│   ├── dynamodb-global-tables/
│   │   ├── main.tf
│   │   ├── replica_regions.tf
│   │   ├── autoscaling.tf
│   │   └── outputs.tf
│   ├── elasticache-redis-cluster/
│   │   ├── main.tf
│   │   ├── replication_groups.tf
│   │   ├── subnet_groups.tf
│   │   └── outputs.tf
│   ├── msk-kafka-cluster/
│   │   ├── main.tf
│   │   ├── serverless_msk.tf
│   │   ├── privatelink_connectivity.tf
│   │   ├── client_auth.tf
│   │   └── outputs.tf
│   ├── s3-lakehouse-medallion/
│   │   ├── raw_bronze.tf
│   │   ├── cleansed_silver.tf
│   │   ├── analytics_gold.tf
│   │   ├── iceberg_compaction_jobs.tf
│   │   └── outputs.tf
│   └── lakeformation-governance/
│       ├── main.tf
│       ├── lf_tags.tf
│       ├── permissions.tf
│       └── outputs.tf
├── live/
│   ├── data-platform-prod/
│   │   ├── terragrunt.hcl
│   │   └── main.tf
│   └── data-platform-nonprod/
│   │   ├── terragrunt.hcl
│   │   └── main.tf
├── tests/
│   └── rds_proxy_failover_test.go
├── versions.tf
└── README.md
```

### 2.2 Cross-Module Contracts & Dependencies

#### SSM Parameter Store & Secrets Manager Exports:
| Parameter Path | Type | Consumer / Scope | Purpose |
| :--- | :--- | :--- | :--- |
| `/enterprise/data/aurora/proxy-endpoint` | String | Domain 7 (EKS / Lambda Compute) | RDS Proxy read-write connection string |
| `/enterprise/data/aurora/reader-proxy-endpoint` | String | Domain 7 (EKS / Analytics) | RDS Proxy read-only connection string |
| `/enterprise/data/dynamodb/orders-table-arn` | String | Microservice Repositories | Core transactional DynamoDB table ARN |
| `/enterprise/data/msk/bootstrap-brokers-tls` | String | Stream Processing Workloads | Kafka TLS bootstrap broker endpoints |
| `/enterprise/data/lakehouse/silver-iceberg-bucket-arn` | String | Glue ETL / Athena Analytics | Cleansed Silver Lakehouse Iceberg S3 bucket |
| `/enterprise/data/secrets/aurora-app-credentials-arn` | String (Secret) | Compute Services | Secrets Manager ARN for dynamic DB user credentials |

#### Remote State & Inter-Module Dependencies:
- **Upstream Dependencies**: Domain 1 (`terraform-aws-landing-zone-network-fabric` for Spoke Database Subnets), Domain 3 (`terraform-aws-central-identity-kms-security` for Storage CMKs).
- **Downstream Consumers**: Domain 7 (Compute/EKS application workloads), Domain 8 (EventBridge & Step Functions ETL), Domain 10 (SageMaker ML Training/Inference), Domain 11 (Cross-Region DR).

---

## 3. Architecture Topology Diagram

```mermaid
flowchart TB
    subgraph Compute_and_Ingestion["Application Tier (Domain 7 / External)"]
        Microservices["EKS Microservices / Fargate Tasks"]
        Serverless_Lambdas["Event-Driven AWS Lambda Functions"]
        IoT_Clickstream["Streaming Clients / Webhooks"]
    end

    subgraph Data_Platform_Account["Data & Persistence Account (Multi-AZ Encrypted)"]
        
        subgraph Realtime_Cache_and_NoSQL["Low-Latency Data Tier"]
            Redis_Cluster["Amazon ElastiCache Redis (Multi-AZ Auto-Failover)"]
            DDB_Global["DynamoDB Global Tables (PITR + Streams)"]
        end

        subgraph Relational_OLTP_Tier["Relational ACID Tier"]
            RDS_Proxy["Amazon RDS Proxy (Primary Connection Pooler)"]
            RDS_Proxy_DR["Standby RDS Proxy (Pre-provisioned in us-west-2)"]
            Aurora_Writer["Aurora Serverless v2 (Primary Writer - AZ-A)"]
            Aurora_Reader_1["Aurora Serverless v2 (Reader Replica - AZ-B)"]
            Aurora_Reader_2["Aurora Serverless v2 (Reader Replica - AZ-C)"]
        end

        subgraph Realtime_Streaming_Fabric["Event Streaming Backbone"]
            MSK_Kafka["Amazon MSK (Multi-VPC PrivateLink + Tiered Storage)"]
            MSK_Connect["MSK Connect (Iceberg Sink)"]
        end

        subgraph Medallion_Lakehouse_Architecture["Enterprise S3 Lakehouse (Apache Iceberg)"]
            S3_Bronze["Bronze S3: Raw Ingestion"]
            S3_Silver["Silver S3: Cleansed & Partitioned (Iceberg ACID)"]
            S3_Gold["Gold S3: Curated Analytics Data Marts (Iceberg ACID)"]
            Glue_Compaction["Glue Compaction Job (rewrite_data_files)"]
        end

        subgraph Governance_Analytics["Governance & Query Engine"]
            Lake_Formation["AWS Lake Formation (LF-TBAC & Data Filtering)"]
            Glue_Catalog_Lake["AWS Glue Data Catalog"]
            Athena_SQL["Amazon Athena Serverless SQL Engine"]
        end

    end

    %% OLTP & Cache Flows
    Microservices -->|Read/Write Caching| Redis_Cluster
    Microservices & Serverless_Lambdas -->|Sub-10ms Key-Value| DDB_Global
    Microservices & Serverless_Lambdas -->|SQL Connection Pooling| RDS_Proxy
    RDS_Proxy --> Aurora_Writer
    RDS_Proxy -.-> Aurora_Reader_1 & Aurora_Reader_2
    Aurora_Writer -.->|Shared Storage Replication| Aurora_Reader_1 & Aurora_Reader_2

    %% Streaming & ETL Flows
    IoT_Clickstream -->|Real-Time Event Stream via PrivateLink| MSK_Kafka
    MSK_Kafka --> MSK_Connect --> S3_Bronze
    DDB_Global -.->|DynamoDB Streams| S3_Bronze
    
    S3_Bronze --> S3_Silver --> S3_Gold
    Glue_Compaction -.->|Automated 512MB Bin-Packing| S3_Silver & S3_Gold

    %% Governance & Query
    Lake_Formation --- Glue_Catalog_Lake
    Glue_Catalog_Lake --- Athena_SQL
    Athena_SQL --> S3_Silver & S3_Gold
```

---

## 4. Expert Architectural Review & Trade-off Critique

### 4.1 Well-Architected Assessment
- **Security**:
  - *Zero Public Accessibility*: All databases, caches, and MSK brokers reside exclusively in isolated database subnets.
  - *Lake Formation LF-TBAC*: Dynamically masks PII columns based on caller IAM roles.
- **Reliability**:
  - *Aurora Storage Layer Resilience*: 6-way storage replication across 3 AZs; survives loss of an AZ plus a disk.
  - *Standby RDS Proxy Pre-Provisioning*: Eliminates connection surge latency during regional failover in `us-west-2`.
- **Operational Excellence**:
  - *Automated Iceberg Compaction*: Eliminates small-file read degradation via scheduled Glue maintenance routines.
- **Cost Optimization**:
  - *MSK Tiered Storage*: Offloads aged Kafka topic partitions (> 24 hours) to Amazon S3, cutting storage costs by 65%.

### 4.2 Critical Architectural Risks & Mitigations

#### Risk 1: DynamoDB Partition Hotspotting
- **Failure Mechanism**: Poorly chosen partition keys steer write traffic to a single partition, exceeding the 1,000 WCU limit.
- **Mitigation Strategy**:
  1. Implement synthetic partition key salting (`PartitionKey = TenantID + "_" + RandomHash(1..10)`).
  2. Front high-frequency read keys with Amazon ElastiCache Redis.

#### Risk 2: Apache Iceberg Small-File Degradation in Streaming Ingestion
- **Failure Mechanism**: High-frequency streaming writes from MSK create millions of 1MB files, degrading query times.
- **Mitigation Strategy**:
  1. Schedule automated AWS Glue Iceberg compaction jobs (`CALL system.rewrite_data_files()`) to bin-pack small files into 512MB chunks.
  2. Configure snapshot expiration and orphan file removal in Lake Formation.

#### Risk 3: DynamoDB Global Tables Multi-Region Last-Writer-Wins Data Loss
- **Failure Mechanism**: In active-active multi-region deployments, concurrent writes to the same item in `us-east-1` and `us-west-2` result in silent overwrite based on the latest physical timestamp without transactional reconciliation.
- **Mitigation Strategy**:
  1. Enforce optimistic locking in application models using a monotonic `version` attribute with DynamoDB Condition Expressions (`attribute_not_exists(version) OR version = :current_version`).
  2. Implement customer/tenant affinity routing at the Edge (CloudFront / Route 53 ARC) to ensure all writes for a given tenant route to a single designated active region.

