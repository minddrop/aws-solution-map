# Deep-Dive Review Prompt: AI/ML Inference, Model Governance & Enterprise Guardrails

```markdown
/goal 
# Role & Mandate
Act as a Principal Enterprise AI/ML Solutions Architect and Generative AI Governance Specialist. Audit the AI/ML inference platform, foundation model guardrails, and secure data access patterns.

# Files to Review
- `docs/10-aiml-inference-enterprise-guardrails.md`
- `docs/06-data-persistence-streaming-lakehouse.md`
- `contracts/ssm-parameter-schema.json`
- `contracts/iam-baseline-matrix.md`

# Focus Areas & Stress Tests
1. **Amazon Bedrock Governance & Guardrail Policies**:
   - Audit Amazon Bedrock Guardrail configurations: PII redacting/masking, toxic content filters, prompt injection defenses, and custom enterprise ground rules.
   - Are Bedrock Model Invocation logs encrypted with customer-managed KMS keys and shipped directly to the central S3 Log Archive?
2. **Private Inference & Network Isolation**:
   - Is model inference traffic fully isolated within the AWS network using AWS PrivateLink / Bedrock VPC Endpoints without traversing the public internet?
   - How are vector database queries (e.g., OpenSearch Serverless / Aurora pgvector) isolated and secured within private subnets?
3. **IAM Pod Identity & Model Access Control**:
   - Verify that microservices accessing Foundation Models use fine-grained EKS Pod Identity association roles restricted to specific Bedrock model ARNs (`anthropic.claude-3-5-sonnet-*`, `amazon.titan-*`).
4. **Latency, Rate Limiting & Provisioned Throughput (PTU)**:
   - How does the architecture handle model throttling (HTTP 429), quota limits, and burst traffic? Are Provisioned Throughput (PTU) units or fallback model cascades specified for mission-critical workflows?

# Required Output
- Architectural risk assessment for Enterprise Generative AI deployment.
- Concrete configuration updates for `docs/10-aiml-inference-enterprise-guardrails.md` and `contracts/ssm-parameter-schema.json`.
```
