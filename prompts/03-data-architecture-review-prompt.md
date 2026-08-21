# Deep-Dive Review Prompt: Data Persistence, Streaming & Lakehouse Architecture

```markdown
/goal 
# Role & Mandate
Act as a Principal AWS Data & Database Solutions Architect. Audit the persistence, streaming, and lakehouse tier for data integrity, scale, and high availability.

# Files to Review
- `docs/06-data-persistence-streaming-lakehouse.md`
- `docs/08-application-integration-async-orchestration.md`
- `contracts/ssm-parameter-schema.json`

# Focus Areas & Stress Tests
1. **Aurora Serverless v2 + RDS Proxy Resilience**:
   - Evaluate connection pooling, read-write splitting, failover behavior, and scale-up latency during sudden traffic surges. Are client timeouts configured to prevent cascading connection pool exhaustion?
2. **Amazon MSK & Streaming Ingestion**:
   - Audit MSK configuration: Multi-AZ broker distribution, Kafka TLS/IAM authentication, MSK Tiered Storage, schema registry enforcement, and Kafka consumer group lag monitoring.
3. **Apache Iceberg Lakehouse & S3 Storage Tiers**:
   - Review the Medallion architecture (Bronze -> Silver -> Gold). How is concurrency managed with Apache Iceberg ACID transactions? Are compaction and snapshot expiration jobs scheduled to prevent small-file performance degradation?
4. **DynamoDB Global Tables Conflict Resolution**:
   - How does the application handle last-writer-wins (LWW) concurrent writes across regions? Are transactional writes (`TransactWriteItems`) used appropriately with idempotency tokens?

# Required Output
- Risk table of database/streaming bottlenecks.
- Architectural and configuration recommendations for Aurora, MSK, and Iceberg.
```
