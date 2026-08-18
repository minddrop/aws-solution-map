# Domain 8: Application Integration & Asynchronous Orchestration

## 1. Capability Scope & Service Taxonomy

### 1.1 Primary Purpose & Domain Boundaries
The Application Integration & Asynchronous Orchestration domain provides decoupled, event-driven messaging, enterprise workflow orchestration, and resilient publish-subscribe backbones across distributed microservices. It eliminates point-to-point synchronous coupling, absorbs traffic volatility via buffering, and guarantees transactional state machine execution.

The domain boundary encapsulates:
- **Centralized & Mesh Event Streaming (Amazon EventBridge)**: Custom Organization Event Buses, Schema Registry with automated schema discovery, content-based rule filtering, archive & replay capabilities, and cross-account event routing.
- **Enterprise Messaging & Buffering (Amazon SQS & SNS)**: Standard and FIFO Queues with Dead Letter Queues (DLQs), server-side KMS encryption, SNS Topic Fan-Out patterns, and message filtering policies.
- **Distributed Workflow State Machines (AWS Step Functions)**: Express and Standard State Machines orchestrating long-running transactional business workflows (Saga pattern), automated error handling, retries with exponential backoff, and human-in-the-loop task tokens.
- **API & Event Ingestion Gateways (Amazon API Gateway & AppSync)**: REST/HTTP API Gateways and GraphQL APIs integrating directly with EventBridge and SQS without compute intermediaries.

### 1.2 Core AWS Services & Modern Capabilities
- **Amazon EventBridge (Pipes & Schema Registry)**: Point-to-point integrations between sources (SQS, DynamoDB Streams, Kinesis) and targets with built-in filtering and transformation.
- **EventBridge Event Replay & Archive**: Ability to replay historical event streams back to event buses for disaster recovery or bug backfilling.
- **AWS Step Functions (Distributed Map & Saga Pattern)**: High-concurrency workflow orchestration executing millions of parallel tasks with state persistence.
- **Amazon SQS FIFO & High-Throughput Mode**: Exactly-once message processing with deduplication IDs and up to 70,000 messages per second per FIFO queue with batching.
- **Amazon SNS Message Data Protection**: Real-time inspection and redaction of PII (credit cards, tax IDs) in transit across SNS notification topics.

---

## 2. IaC Repository Boundary & Inter-Module Contracts

### 2.1 Dedicated Repository Naming & Layout
- **Repository Name**: `terraform-aws-application-integration-orchestration`
- **Engine**: Terraform >= 1.9.0 with AWS Provider >= 5.60.0

```
terraform-aws-application-integration-orchestration/
├── .github/
│   └── workflows/
│       ├── lint-validate.yml
│       └── step-functions-test.yml
├── config/
│   ├── central-event-bus.tfvars
│   ├── order-processing-workflow.tfvars
│   └── sqs-dlq-policies.tfvars
├── modules/
│   ├── eventbridge-central-bus/
│   │   ├── main.tf
│   │   ├── bus_policies.tf
│   │   ├── schema_registry.tf
│   │   ├── archives.tf
│   │   └── outputs.tf
│   ├── eventbridge-cross-account-router/
│   │   ├── rules.tf
│   │   ├── targets.tf
│   │   ├── dead_letter_queues.tf
│   │   └── outputs.tf
│   ├── sqs-sns-fanout/
│   │   ├── sns_topics.tf
│   │   ├── sqs_queues.tf
│   │   ├── subscriptions.tf
│   │   ├── data_protection_policy.tf
│   │   └── outputs.tf
│   ├── step-functions-saga/
│   │   ├── main.tf
│   │   ├── state_machine.json
│   │   ├── iam_roles.tf
│   │   ├── logging.tf
│   │   └── outputs.tf
│   └── eventbridge-pipes-integration/
│       ├── main.tf
│       ├── transformations.tf
│       └── outputs.tf
├── live/
│   ├── integration-hub-prod/
│   │   ├── terragrunt.hcl
│   │   └── main.tf
│   └── integration-hub-nonprod/
│       ├── terragrunt.hcl
│       └── main.tf
├── tests/
│   └── event_routing_test.go
├── versions.tf
└── README.md
```

### 2.2 Cross-Module Contracts & Dependencies

#### SSM Parameter Store Exports:
| Parameter Path | Type | Consumer / Scope | Purpose |
| :--- | :--- | :--- | :--- |
| `/enterprise/integration/eventbridge/central-bus-arn` | String | All Microservices | Central Enterprise EventBus ARN for publishing domain events |
| `/enterprise/integration/sqs/orders-dlq-arn` | String | Order Processing Module | Shared Dead Letter Queue ARN for poisoned message capture |
| `/enterprise/integration/stepfunctions/order-saga-arn` | String | API Gateway / Compute Services | Step Functions Saga State Machine ARN |
| `/enterprise/integration/sns/billing-fanout-topic-arn` | String | Invoicing & Payment Microservices | SNS Fan-Out Topic ARN for billing event broadcast |

#### Remote State & Inter-Module Dependencies:
- **Upstream Dependencies**: Domain 3 (`terraform-aws-central-identity-kms-security` for KMS CMKs for SQS/SNS encryption), Domain 4 (Central CloudWatch Logs & X-Ray Tracing).
- **Downstream Consumers**: Domain 7 (Compute/Lambda/EKS microservice subscribers), Domain 10 (AI Pipeline Orchestration), Domain 11 (DR Event Replays).

#### IAM Baseline Assumptions:
- EventBridge Bus Policy allows `events:PutEvents` restricted to principals with `aws:PrincipalOrgID` matching the corporate Organization ID.
- SQS Queue Policies require `aws:SecureTransport` (HTTPS) and enforce KMS key decryption permissions.

---

## 3. Architecture Topology Diagram

```mermaid
flowchart TB
    subgraph Publisher_Services["Upstream Event Producers (Domain 7)"]
        Order_Microservice["Order API Service (EKS)"]
        Payment_Webhook["Payment Webhook (API Gateway)"]
        Inventory_Service["Inventory Microservice (ECS)"]
    end

    subgraph Central_Integration_Platform["Asynchronous Integration Fabric (Shared Services)"]
        
        subgraph EventBridge_Core["Amazon EventBridge Architecture"]
            Central_Bus["Enterprise Central Event Bus"]
            Schema_Discovery["Schema Registry & Code Bindings"]
            Event_Archive["Event Archive & Replay Vault (30 Days)"]
            
            Rule_Order_Placed["Rule: OrderPlaced Filter"]
            Rule_Payment_Processed["Rule: PaymentCaptured Filter"]
        end

        subgraph Fanout_and_Buffering["SNS Fan-Out & SQS Queues"]
            SNS_Order_Events["Amazon SNS: Order Events Topic (Data Protection PII Redaction)"]
            
            SQS_Fulfillment["SQS Queue: Fulfillment Processing (FIFO + DLQ)"]
            SQS_Billing["SQS Queue: Billing & Invoicing (FIFO + DLQ)"]
            SQS_Fraud["SQS Queue: Real-time Fraud Detection (Standard)"]
            
            Central_DLQ["Central Dead Letter Queue (SQS Dead-Letter Store)"]
        end

        subgraph Saga_Workflow_Engine["Distributed Saga State Machine (AWS Step Functions)"]
            SFN_Order_Saga["Order Fulfillment Saga State Machine"]
            
            subgraph Saga_Steps["Saga Compensation Logic"]
                Step_Reserve_Stock["1. Reserve Stock"]
                Step_Process_Card["2. Charge Payment"]
                Step_Compensate_Stock["* Compensation: Release Stock"]
                Step_Notify_Ship["3. Dispatch Shipment"]
            end
        end

    end

    subgraph Downstream_Consumers["Downstream Workload Consumers (Domain 7 / External)"]
        Fulfillment_Worker["Fulfillment Worker Fleet (EKS)"]
        Billing_Worker["Invoicing Lambda Function"]
        Fraud_ML_Pipeline["Fraud AI Inference Pipeline (Domain 10)"]
    end

    %% Event Ingestion
    Order_Microservice & Payment_Webhook -->|PutEvents| Central_Bus
    Central_Bus --> Event_Archive
    Central_Bus --- Schema_Discovery

    %% Routing to Rules
    Central_Bus --> Rule_Order_Placed & Rule_Payment_Processed
    Rule_Order_Placed --> SNS_Order_Events
    Rule_Order_Placed --> SFN_Order_Saga

    %% Fanout to Queues
    SNS_Order_Events --> SQS_Fulfillment & SQS_Billing & SQS_Fraud

    %% Consumer Processing
    SQS_Fulfillment --> Fulfillment_Worker
    SQS_Billing --> Billing_Worker
    SQS_Fraud --> Fraud_ML_Pipeline

    %% DLQ Handling
    SQS_Fulfillment -.->|MaxReceiveCount=3 Exceeded| Central_DLQ
    SQS_Billing -.->|MaxReceiveCount=3 Exceeded| Central_DLQ

    %% Step Functions Saga flow
    SFN_Order_Saga --> Step_Reserve_Stock --> Step_Process_Card
    Step_Process_Card -->|On Payment Failure| Step_Compensate_Stock
    Step_Process_Card -->|On Payment Success| Step_Notify_Ship
```

---

## 4. Expert Architectural Review & Trade-off Critique

### 4.1 Well-Architected Assessment
- **Security**:
  - *SNS Message Data Protection*: Built-in pattern-matching identifiers detect and redact sensitive payment card numbers (PCI-DSS) and social security numbers before message delivery to subscriber queues.
  - *Strict SigV4 Org Bus Policies*: EventBridge buses only accept events from verified accounts within the organization, mitigating unauthorized event injection.
- **Reliability**:
  - *Saga Pattern Distributed Compensation*: Step Functions state machines coordinate distributed microservices with automated rollback and compensation actions (e.g., releasing inventory if payment authorization fails).
  - *Automated Dead Letter Queueing & Alerting*: All SQS queues and EventBridge rules are paired with DLQs; CloudWatch alarms trigger automated runbooks when DLQ depth exceeds zero.
- **Operational Excellence**:
  - *EventBridge Replay Capabilities*: Enables instant replay of past events during bug fixes or data lake backfills without disturbing live operational systems.
  - *Schema Registry Integration*: Auto-generates strongly-typed TypeScript and Java models directly from event streams into developer CI/CD pipelines.
- **Cost Optimization**:
  - *EventBridge Content-Based Filtering*: Discards irrelevant events at the event bus layer before invoking expensive downstream compute, saving millions of unnecessary Lambda invocations.
  - *SQS Long Polling (WaitTimeSeconds = 20)*: Minimizes empty receive requests, cutting SQS API billing by up to 90% compared to short polling.

### 4.2 Critical Architectural Risks & Mitigations

#### Risk 1: Poison Pill Messages Inducing Infinite Lambda Retry Storms
- **Failure Mechanism**: A malformed message with invalid JSON schema enters an SQS queue driving a Lambda consumer. The Lambda crashes repeatedly, retrying indefinitely and exhausting concurrency pools while locking the queue.
- **Mitigation Strategy**:
  1. Enforce strict `maxReceiveCount = 3` on all SQS queues, routing failed payloads to a dedicated Dead Letter Queue (DLQ).
  2. Implement SQS Redrive Policy paired with EventBridge Pipes to safely inspect and redrive corrected messages from DLQs back into the source queue.

#### Risk 2: Out-of-Order Message Processing in High-Throughput FIFO Queues
- **Failure Mechanism**: Microservices publishing to SQS FIFO use generic `MessageGroupId` values (e.g., static region strings instead of granular `CustomerID`), causing sequential serialization of all messages across the entire enterprise, creating massive queue latency backlogs.
- **Mitigation Strategy**:
  1. Enforce high-cardinality `MessageGroupId` attributes (e.g., `TenantID_EntityID`) in producer validation contracts.
  2. Enable SQS FIFO High-Throughput mode to scale partitioning dynamically up to 70,000 TPS.
