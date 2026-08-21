# Architecture Review Report 03: Data Persistence, Streaming & Lakehouse Architecture

**Review Area**: Relational OLTP, Streaming Ingestion, Lakehouse & NoSQL Data Tier  
**Reviewer Role**: Principal AWS Data & Database Solutions Architect  
**Status**: COMPLETED  
**Date**: 2026-08-21  

---

## 1. Executive Summary & Assessment

An in-depth data architecture review was performed across [`docs/06-data-persistence-streaming-lakehouse.md`](file:///home/joe/src/aws-solution-map/docs/06-data-persistence-streaming-lakehouse.md), [`docs/08-application-integration-async-orchestration.md`](file:///home/joe/src/aws-solution-map/docs/08-application-integration-async-orchestration.md), and [`contracts/ssm-parameter-schema.json`](file:///home/joe/src/aws-solution-map/contracts/ssm-parameter-schema.json).

### Overall Architecture Evaluation: **Grade A**
The data platform incorporates state-of-the-art enterprise patterns: **Aurora Serverless v2** coupled with primary and pre-provisioned standby **RDS Proxies**, **Amazon MSK Tiered Storage** with multi-VPC PrivateLink, **Apache Iceberg Medallion lakehouse** with automated Glue compaction, and **DynamoDB Global Tables** with PITR.

---

## 2. Deep-Dive Stress-Test Evaluations

### 2.1 Aurora Serverless v2 & RDS Proxy Connection Dynamics
- **Surge Resilience**: Aurora Serverless v2 scales dynamically between 0.5 and 128 ACUs (1GB to 256GB RAM). RDS Proxy absorbs sudden connection spikes from thousands of ephemeral EKS pods or Lambda invocations.
- **Failover Behavior**: With RDS Proxy, database failovers drop connection transition times from 30+ seconds to under 3 seconds without application restart. Pre-provisioning standby RDS Proxy endpoints in `us-west-2` guarantees immediate connection readiness during disaster recovery.
- **Client Timeout Governance**: To prevent thread starvation, client-side JDBC/PG connection pools must configure `loginTimeout = 5s` and `socketTimeout = 30s` with exponential backoff and jitter.

### 2.2 Amazon MSK Tiered Storage & Governance
- **Broker Distribution**: 3-AZ symmetric distribution with `min.insync.replicas = 2` and `replication.factor = 3`.
- **Storage Economics**: MSK Tiered Storage offloads cold partition logs (> 24 hours) to S3, reducing provisioned EBS volumes by 65%.
- **Authentication**: Strict AWS IAM Authentication (`SASL_SSL / AWS_MSK_IAM`) with TLS 1.3 encryption in-transit.
- **Consumer Lag Alerting**: Amazon CloudWatch alarms configured on `EstimatedMaxTimeLag > 60s` and `MaxOffsetLag > 5000`.

### 2.3 Apache Iceberg Lakehouse Medallion Architecture
- **Concurrency & ACID**: Apache Iceberg optimistic concurrency control guarantees transaction isolation across parallel Glue streaming writes.
- **Small-File Compaction**: Streaming ingestion generates frequent 1MB parquet files. The architecture incorporates an automated AWS Glue Iceberg compaction workflow (`CALL system.rewrite_data_files(table => 'silver_orders', options => map('target-file-size-bytes','536870912'))`) to maintain 512MB optimal parquet chunks.
- **Snapshot Lifecycle**: Enforces a 7-day snapshot retention window (`CALL system.expire_snapshots()`) to avoid metadata bloat.

### 2.4 DynamoDB Global Tables Active-Active Multi-Region Write Safety
- **Conflict Handling**: DynamoDB Global Tables use Last-Writer-Wins (LWW). Concurrent writes to the same item in `us-east-1` and `us-west-2` can silently overwrite changes.
- **Architectural Mitigation**: Enforce regional tenant affinity at the Edge (Route 53 ARC / CloudFront) combined with optimistic version locking (`ConditionExpression: attribute_not_exists(version) OR version = :v`).

---

## 3. Database & Streaming Bottleneck Risk Table

| Layer / Service | Potential Failure Mode | Impact | Recommended Architectural Safeguard |
| :--- | :--- | :--- | :--- |
| **Aurora PostgreSQL** | Cascading connection pool exhaustion | Application HTTP 500 errors | Mandate RDS Proxy for 100% of compute clients; enforce `idle_in_transaction_session_timeout = 60s`. |
| **Amazon MSK** | Partition skew on single broker | Throttling on single broker CPU | Key partition hashing; partition counts set to multiples of 3 (e.g., 12 or 24 partitions per topic). |
| **Apache Iceberg** | Query scan degradation due to small files | Athena analytics query slow-down | Scheduled Glue Iceberg bin-packing compaction jobs running every 6 hours. |
| **DynamoDB Global** | Multi-region concurrent overwrite | Silent data ledger divergence | Enforce optimistic locking via `version` attribute & Route 53 tenant affinity. |

---

## 4. Architectural Recommendations & SSM Contract Enhancements

1. **SSM Parameter Store Parity**: Ensure RDS Proxy read-write (`/enterprise/data/aurora/proxy-endpoint`) and read-only (`/enterprise/data/aurora/reader-proxy-endpoint`) endpoints are strictly declared and typed in `contracts/ssm-parameter-schema.json`.
2. **Secrets Manager Integration**: Automate Aurora dynamic user credential rotation with AWS Secrets Manager Lambda rotators inside private DB subnets.

---

## 5. Data Architecture Findings Summary

| Finding ID | Severity | Domain | Affected Files | Title |
| :--- | :---: | :--- | :--- | :--- |
| `DAT-001` | **P1** | `06-data-persistence-streaming-lakehouse` | `docs/06-data-persistence-streaming-lakehouse.md` | DynamoDB Global Tables multi-region write conflict resolution specification |
| `DAT-002` | **P1** | `06-data-persistence-streaming-lakehouse` | `docs/06-data-persistence-streaming-lakehouse.md`, `contracts/ssm-parameter-schema.json` | Iceberg automated compaction routine governance and parameter declaration |
