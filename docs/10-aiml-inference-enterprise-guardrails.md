# Domain 10: AI/ML Inference & Enterprise Guardrails

## 1. Capability Scope & Service Taxonomy

### 1.1 Primary Purpose & Domain Boundaries
The AI/ML Inference & Enterprise Guardrails domain establishes a secure, enterprise-grade foundation for Generative AI, Large Language Model (LLM) orchestration, fine-tuning, retrieval-augmented generation (RAG), and traditional machine learning inference. It enforces strict data privacy, prompt injection defenses, automated PII redaction, content filtering, and zero data leakage over public networks.

The domain boundary encapsulates:
- **Foundation Model Orchestration & Cross-Region Routing (Amazon Bedrock)**: Serverless access to state-of-the-art foundation models (Claude 3.5 Sonnet/Haiku, Titan, Llama 3) via Amazon Bedrock, dynamically load-balanced across regions using Cross-Region Inference Profiles (`us.anthropic.claude-3-5-sonnet-20241022-v2:0`) to eliminate regional token throttling.
- **Enterprise Guardrails & Anti-Jailbreak (Bedrock Guardrails)**: Deterministic and ML safety filters enforcing topic denial, PII anonymization, prompt injection defense, and contextual grounding (anti-hallucination) with mandatory IAM policy enforcement (`bedrock:GuardrailIdentifier`).
- **Retrieval-Augmented Generation (Bedrock Knowledge Bases)**: Managed vector ingestion connecting to Amazon OpenSearch Serverless (vector engine) with granular tenant metadata filtering and S3 data synchronization.
- **Enterprise ML Training & Inference (Amazon SageMaker)**: SageMaker Studio, distributed multi-GPU training clusters, and Real-Time / Asynchronous Endpoints.
- **Zero-Public Ingress/Egress AI Networking (AWS PrivateLink)**: Dedicated Interface VPC Endpoints for Bedrock Runtime, SageMaker API, and Model Registry.
- **GenAI Auditability & Invocation Logging**: 100% prompt, completion, and guardrail evaluation logging to central S3 audit buckets in the Log Archive account.

### 1.2 Core AWS Services & Modern Capabilities
- **Amazon Bedrock & Cross-Region Inference Profiles**: High-throughput foundation model invocation dynamically balanced across US/EU regions.
- **Amazon Bedrock Guardrails**: PII masking/redaction, anti-jailbreak, and contextual grounding scoring against source RAG documents.
- **Amazon OpenSearch Serverless (Vector Engine)**: Billion-scale vector embeddings storage with cosine similarity search.
- **Amazon SageMaker Endpoints**: Dedicated GPU inference with custom Triton/vLLM containers.
- **AWS PrivateLink for Bedrock**: Strict private network path with zero public internet routing.
- **KMS CMKs for GenAI**: Enforced customer key encryption for custom models, vector indexes, and invocation logs.

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
│   ├── cross-region-inference.tfvars
│   ├── knowledge-base-rag.tfvars
│   └── sagemaker-endpoints.tfvars
├── modules/
│   ├── bedrock-guardrails/
│   │   ├── main.tf
│   │   ├── content_filters.tf
│   │   ├── pii_entities.tf
│   │   ├── topic_denials.tf
│   │   ├── contextual_grounding.tf
│   │   ├── invocation_iam_policy.tf
│   │   └── outputs.tf
│   ├── bedrock-cross-region-profiles/
│   │   ├── main.tf
│   │   ├── routing_profiles.tf
│   │   └── outputs.tf
│   ├── bedrock-knowledge-bases/
│   │   ├── main.tf
│   │   ├── opensearch_serverless_vector.tf
│   │   ├── s3_data_source.tf
│   │   ├── tenant_filtering.tf
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
| `/enterprise/ai/bedrock/guardrail-version` | String | Application Services | Production version of the Bedrock Guardrail (`1` vs `DRAFT`) |
| `/enterprise/ai/bedrock/inference-profile-sonnet-arn` | String | Application Services | Cross-Region Inference Profile ARN for Claude 3.5 Sonnet |
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

        subgraph Bedrock_Cross_Region_Router["Cross-Region Inference Profile Router"]
            CR_Profile_Sonnet["Profile: us.anthropic.claude-3-5-sonnet-20241022-v2:0"]
            CR_Profile_Haiku["Profile: us.anthropic.claude-3-5-haiku-20241022-v1:0"]
        end

        subgraph Bedrock_Foundation_Models["Managed Foundation Models (Multi-Region Quorum)"]
            Claude_East["Claude 3.5 Sonnet (us-east-1)"]
            Claude_West["Claude 3.5 Sonnet (us-west-2)"]
            Claude_Central["Claude 3.5 Sonnet (us-east-2)"]
        end

        subgraph Bedrock_RAG_Platform["Managed Knowledge Bases (RAG Engine)"]
            KB_Ingestion["Knowledge Base Ingestion & Chunking"]
            AOSS_Vector_DB["OpenSearch Serverless Vector Index (Tenant Filtered)"]
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
    Guardrail_Defense_Layer -->|Sanitized Prompt| Bedrock_Cross_Region_Router
    CR_Profile_Sonnet --> Claude_East & Claude_West & Claude_Central

    %% RAG Retrieval Flow
    GenAI_Microservice -->|Vector Query with Tenant Filter| VPCE_AOSS
    VPCE_AOSS --> AOSS_Vector_DB
    KB_Ingestion --> AOSS_Vector_DB
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
  - *Automated Prompt Injection & PII Scrubbing*: Bedrock Guardrails intercepts malicious prompts and masks PII before LLM processing.
  - *Targeted IAM & SCP Condition Key Enforcement*: Mandates `bedrock:GuardrailIdentifier` for all generative LLMs (Claude, Llama, Titan Text) via SCP, while exempting text embedding models (`amazon.titan-embed-*`) to ensure continuous RAG Knowledge Base indexing.
- **Reliability**:
  - *Cross-Region Inference Profiles*: Dynamically balances token loads across `us-east-1`, `us-west-2`, and `us-east-2`, mitigating regional quota exhaustion (HTTP 429).
- **Operational Excellence**:
  - *Centralized Invocation Audit Logging*: Logs 100% of prompts, model responses, and guardrail evaluations to Log Archive S3 buckets.
  - *Contextual Grounding Evaluation*: Evaluates model outputs against retrieved RAG chunks, dropping hallucinated responses.
- **Cost Optimization**:
  - *Intelligent Model Routing*: Routes simple tasks to Claude Haiku / Titan and complex reasoning to Claude Sonnet.

### 4.2 Critical Architectural Risks & Mitigations

#### Risk 1: Knowledge Base Cross-Tenant Data Leakage
- **Failure Mechanism**: Shared vector embeddings return documents across tenant boundaries.
- **Mitigation Strategy**:
  1. Enforce strict document metadata tagging (`tenant_id`) at S3 ingestion time.
  2. Implement OpenSearch Serverless vector search pre-filtering requiring `tenant_id == current_session_tenant_id`.

#### Risk 2: Bedrock Single-Region Token Quota Exhaustion
- **Failure Mechanism**: Batch document processing exhausts account-level TPM quotas in `us-east-1`, starving live chatbots.
- **Mitigation Strategy**:
  1. Utilize Amazon Bedrock Cross-Region Inference Profiles (`us.anthropic.claude-3-5-sonnet-20241022-v2:0`).
  2. Implement rate-limiting token bucket queues in SQS for asynchronous batch tasks.

#### Risk 3: OpenSearch Serverless (AOSS) Idle OCU Cost Proliferation
- **Failure Mechanism**: Creating separate OpenSearch Serverless vector collections per small microservice incurs a baseline charge of 4 OCUs ($700/mo minimum per collection) even with zero query traffic.
- **Mitigation Strategy**:
  1. Consolidate enterprise vector embeddings into a shared, centralized Vector Collection in Domain 10 partitioned by tenant index aliases.
  2. Configure automatic OCU scale-down caps via `aws_opensearchserverless_lifecycle_policy`.

