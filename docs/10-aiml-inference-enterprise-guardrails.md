# Domain 10: AI/ML Inference & Enterprise Guardrails

## 1. Capability Scope & Service Taxonomy

### 1.1 Primary Purpose & Domain Boundaries
The AI/ML Inference & Enterprise Guardrails domain establishes a secure, enterprise-grade foundation for Generative AI, Large Language Model (LLM) orchestration, fine-tuning, retrieval-augmented generation (RAG), and traditional machine learning inference. It enforces strict data privacy, prompt injection defenses, automated PII redaction, content filtering, and zero data leakage over public networks.

The domain boundary encapsulates:
- **Foundation Model Orchestration & Guardrails (Amazon Bedrock)**: Serverless access to state-of-the-art foundation models (Claude 3.5 Sonnet/Haiku, Titan, Llama 3) via Amazon Bedrock, protected by Amazon Bedrock Guardrails (toxic content filtering, topic blocking, contextual grounding, PII anonymization, and prompt injection defense).
- **Retrieval-Augmented Generation (Bedrock Knowledge Bases)**: Managed vector ingestion, chunking, and embedding pipelines connecting to Amazon OpenSearch Serverless (vector engine), Amazon Aurora pgvector, or Pinecone, with granular S3 data source synchronization.
- **Enterprise ML Training & Inference (Amazon SageMaker)**: SageMaker Studio, distributed multi-GPU training clusters (EC2 P5/G5 instances), and SageMaker Real-Time / Asynchronous Inference Endpoints with automated scaling policies.
- **Zero-Public Ingress/Egress AI Networking (AWS PrivateLink)**: Dedicated Interface VPC Endpoints for Bedrock Runtime, SageMaker API, and Model Registry, ensuring all prompts, embeddings, and inference payloads traverse exclusively within private VPC endpoints and customer KMS encryption boundaries.
- **GenAI Auditability & Model Evaluation**: Bedrock Model Invocation Logging to central S3 buckets and CloudWatch Log Groups, paired with automated model evaluation benchmarks.

### 1.2 Core AWS Services & Modern Capabilities
- **Amazon Bedrock & Bedrock Agents**: Serverless multi-model APIs, multi-step agentic workflows with OpenAPI action group integrations.
- **Amazon Bedrock Guardrails**: Deterministic and ML-based safety filters, PII masking/redaction, and contextual grounding checks (detecting hallucinations and irrelevance).
- **Amazon OpenSearch Serverless (Vector Engine)**: Billion-scale vector embeddings storage with cosine and euclidean similarity search.
- **Amazon SageMaker JumpStart & Endpoints**: Dedicated deployment of open-source and proprietary models with custom inference containers (Triton / vLLM).
- **AWS PrivateLink for Bedrock**: Strict private network path for GenAI inference with zero public internet routing.
- **KMS Customer Managed Keys for GenAI**: Enforced customer key encryption for Bedrock custom models, knowledge base vector indexes, and invocation logs.

---

## 2. IaC Repository Boundary & Inter-Module Contracts

### 2.1 Dedicated Repository Naming & Layout
- **Repository Name**: `terraform-aws-aiml-inference-guardrails`
- **Engine**: Terraform >= 1.9.0 with AWS Provider >= 5.60.0

```
terraform-aws-aiml-inference-guardrails/
├── .github/
│   └── workflows/
│       ├── lint-validate.yml
│       └── guardrail-eval-test.yml
├── config/
│   ├── bedrock-guardrails-prod.tfvars
│   ├── knowledge-base-rag.tfvars
│   └── sagemaker-endpoints.tfvars
├── modules/
│   ├── bedrock-guardrails/
│   │   ├── main.tf
│   │   ├── content_filters.tf
│   │   ├── pii_entities.tf
│   │   ├── topic_denials.tf
│   │   ├── contextual_grounding.tf
│   │   └── outputs.tf
│   ├── bedrock-knowledge-bases/
│   │   ├── main.tf
│   │   ├── opensearch_serverless_vector.tf
│   │   ├── s3_data_source.tf
│   │   ├── chunking_strategy.tf
│   │   └── outputs.tf
│   ├── sagemaker-inference-endpoint/
│   │   ├── main.tf
│   │   ├── model.tf
│   │   ├── endpoint_config.tf
│   │   ├── autoscaling.tf
│   │   └── outputs.tf
│   ├── genai-privatelink-vpc/
│   │   ├── vpc_endpoints.tf
│   │   ├── security_groups.tf
│   │   └── outputs.tf
│   └── bedrock-invocation-logging/
│       ├── logging_config.tf
│       ├── s3_audit_bucket.tf
│       └── outputs.tf
├── live/
│   ├── aiml-prod-us-east-1/
│   │   ├── terragrunt.hcl
│   │   └── main.tf
│   └── aiml-nonprod-us-east-1/
│       ├── terragrunt.hcl
│       └── main.tf
├── tests/
│   └── guardrail_pii_redaction_test.go
├── versions.tf
└── README.md
```

### 2.2 Cross-Module Contracts & Dependencies

#### SSM Parameter Store Exports:
| Parameter Path | Type | Consumer / Scope | Purpose |
| :--- | :--- | :--- | :--- |
| `/enterprise/ai/bedrock/guardrail-id` | String | Application Services / Agents | Bedrock Guardrail ID enforcing enterprise safety policies |
| `/enterprise/ai/bedrock/guardrail-version` | String | Application Services | Production version of the Bedrock Guardrail (`DRAFT` vs `1`) |
| `/enterprise/ai/rag/knowledge-base-id` | String | GenAI Chatbot Services | Central Knowledge Base ID for enterprise document RAG |
| `/enterprise/ai/sagemaker/fraud-endpoint-name` | String | Domain 8 (Fraud Detection Workflows) | Real-time SageMaker fraud inference endpoint name |
| `/enterprise/ai/privatelink/bedrock-vpce-id` | String | Compute Workload VPCs | PrivateLink VPC Endpoint ID for Bedrock runtime |

#### Remote State & Inter-Module Dependencies:
- **Upstream Dependencies**: Domain 1 (`terraform-aws-landing-zone-network-fabric` for App Subnets), Domain 3 (`terraform-aws-central-identity-kms-security` for AI KMS CMKs), Domain 4 (Central CloudWatch & S3 Log Archive for invocation logs).
- **Downstream Consumers**: Domain 7 (Compute/EKS GenAI microservices invoking Bedrock), Domain 8 (Event-driven asynchronous AI pipelines).

#### IAM Baseline Assumptions:
- IAM Workload Roles require `bedrock:InvokeModel` and `bedrock:ApplyGuardrail` permissions restricted via resource ARNs.
- Bedrock invocation is strictly conditioned on `bedrock:GuardrailIdentifier` in IAM policies to prevent un-guardrailed model calls.

---

## 3. Architecture Topology Diagram

```mermaid
flowchart TB
    subgraph Enterprise_Workload_VPC["Enterprise Compute VPC (Domain 7: EKS / Lambda)"]
        GenAI_Microservice["GenAI Chat / Agent Microservice (EKS)"]
        Async_Batch_Worker["Document Extraction Worker (ECS / Lambda)"]
        
        subgraph PrivateLink_AI_Endpoints["AWS PrivateLink Interface Endpoints"]
            VPCE_Bedrock["Bedrock Runtime VPCE"]
            VPCE_SageMaker["SageMaker Runtime VPCE"]
            VPCE_AOSS["OpenSearch Serverless VPCE"]
        end
    end

    subgraph AWS_Bedrock_Managed_Platform["Amazon Bedrock & GenAI Platform (AWS Managed Boundary)"]
        
        subgraph Guardrail_Defense_Layer["Bedrock Enterprise Guardrail Engine"]
            Guardrail_PII["PII Redaction & Masking (SSN, Phone, CC)"]
            Guardrail_Injection["Prompt Injection & Jailbreak Defense"]
            Guardrail_Topics["Topic Denial & Sensitive IP Policies"]
            Guardrail_Grounding["Contextual Grounding (Anti-Hallucination)"]
        end

        subgraph Bedrock_Foundation_Models["Managed Foundation Models"]
            Claude_Model["Anthropic Claude 3.5 Sonnet / Haiku"]
            Titan_Model["Amazon Titan Embeddings V2"]
            Llama_Model["Meta Llama 3 70B"]
        end

        subgraph Bedrock_RAG_Platform["Managed Knowledge Bases (RAG Engine)"]
            KB_Ingestion["Knowledge Base Ingestion & Chunking"]
            AOSS_Vector_DB["OpenSearch Serverless Vector Index (KMS Encrypted)"]
            S3_RAG_Docs["S3 Document Vault (KMS Encrypted)"]
        end

        subgraph SageMaker_Dedicated_Tier["SageMaker Custom Dedicated Endpoints"]
            SM_Endpoint["SageMaker Real-Time Endpoint (GPU P5 / Trn1)"]
            SM_Model_Registry["SageMaker Model Registry"]
        end

    end

    subgraph Central_Audit_and_SOC["Central Log Archive & Monitoring (Domain 4)"]
        Bedrock_Invocation_Logs["Bedrock Invocation S3 Audit Logs (Prompts & Completions)"]
        CloudWatch_AI_Alarms["CloudWatch Guardrail Intervention Metrics"]
    end

    %% Network & Request Flows
    GenAI_Microservice -->|Private Prompts (HTTPS)| VPCE_Bedrock
    Async_Batch_Worker -->|Private Features| VPCE_SageMaker

    VPCE_Bedrock --> Guardrail_Defense_Layer
    Guardrail_Defense_Layer -->|Sanitized Prompt| Claude_Model & Llama_Model

    %% RAG Retrieval Flow
    GenAI_Microservice -->|Vector Query| VPCE_AOSS
    VPCE_AOSS --> AOSS_Vector_DB
    KB_Ingestion --> Titan_Model --> AOSS_Vector_DB
    S3_RAG_Docs --> KB_Ingestion

    %% Dedicated SageMaker Flow
    VPCE_SageMaker --> SM_Endpoint
    SM_Model_Registry --> SM_Endpoint

    %% Telemetry & Compliance
    Guardrail_Defense_Layer -.->|Blocked Prompts / PII Audit| CloudWatch_AI_Alarms
    Bedrock_Foundation_Models -.->|Invocation Logs| Bedrock_Invocation_Logs
```

---

## 4. Expert Architectural Review & Trade-off Critique

### 4.1 Well-Architected Assessment
- **Security**:
  - *Comprehensive Data Privacy*: Bedrock guarantees zero customer prompt/completion data is used to train base models. Customer data is encrypted in transit (TLS 1.3) and at rest with Customer Managed KMS Keys.
  - *Automated Prompt Injection & PII Scrubbing*: Bedrock Guardrails intercepts malicious adversarial prompts (jailbreaks) and automatically masks sensitive PII before text is processed by foundation models.
- **Reliability**:
  - *Multi-Model Fallback Pattern*: Application clients configure automated circuit breakers; if primary LLM (Claude 3.5 Sonnet) experiences latency or service quota limits, traffic falls back transparently to secondary models (Llama 3 / Claude Haiku).
  - *Cross-Region Bedrock Inference Profiles*: Routes requests across multiple AWS regions dynamically to balance capacity and mitigate regional quota exhaustion.
- **Operational Excellence**:
  - *Centralized Invocation Audit Logging*: Logs 100% of prompts, model responses, and guardrail evaluation metadata to the dedicated Log Archive S3 bucket for compliance auditing (EU AI Act, HIPAA).
  - *Contextual Grounding Evaluation*: Scores model outputs against source retrieved RAG documents, automatically dropping hallucinated responses before they reach end users.
- **Cost Optimization**:
  - *Intelligent Model Routing*: Routes simple classification and summarization tasks to low-cost models (Claude Haiku / Titan) and complex reasoning tasks to Claude Sonnet, reducing inference token spend by over 70%.
  - *Provisioned Throughput vs On-Demand*: On-Demand pricing for variable development workloads; Provisioned Throughput (Commitment Model Units) for sustained production traffic.

### 4.2 Critical Architectural Risks & Mitigations

#### Risk 1: Knowledge Base Vector Index Poisoning & Unauthorized Cross-Tenant RAG Retrieval
- **Failure Mechanism**: Documents belonging to Tenant A are indexed into the shared OpenSearch Serverless vector store without tenant isolation metadata. Tenant B performs a search query and the RAG pipeline injects Tenant A's private financial data into Tenant B's LLM context window.
- **Mitigation Strategy**:
  1. Enforce strict document metadata tagging (`tenant_id`, `department_id`) at S3 ingestion time.
  2. Implement OpenSearch Serverless vector search pre-filtering: Bedrock Knowledge Base queries must include explicit metadata filters (`tenant_id == current_session_tenant_id`).

#### Risk 2: Bedrock Account-Level Token Quota Exhaustion Causing Global Application Outages
- **Failure Mechanism**: An asynchronous document processing batch job consumes the entire account-level Tokens Per Minute (TPM) quota on Claude 3.5 Sonnet, starving customer-facing live chatbots and returning HTTP 429 Too Many Requests.
- **Mitigation Strategy**:
  1. Utilize Amazon Bedrock Cross-Region Inference Profiles to automatically distribute token loads across `us-east-1`, `us-west-2`, and `eu-west-1`.
  2. Implement rate limiting and token bucket buffering in upstream SQS / EventBridge queues for asynchronous batch jobs.
