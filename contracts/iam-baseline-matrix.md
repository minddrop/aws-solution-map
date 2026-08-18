# Enterprise IAM Baseline Matrix, Trust Policies & Guardrails

## 1. Multi-Account Role Hierarchy & Trust Boundaries

```
                                  +-----------------------+
                                  |  Entra ID / Okta IdP  |
                                  +-----------+-----------+
                                              | (SAML 2.0 / SCIM)
                                  +-----------v-----------+
                                  |  IAM Identity Center  |
                                  +-----------+-----------+
                                              |
     +----------------------------------------+----------------------------------------+
     |                                        |                                        |
+----v-------------------+               +----v-------------------+               +----v-------------------+
|  AWSAccelerator-       |               |  AWSAccelerator-       |               |  AWSAccelerator-       |
|  SecurityAdminRole     |               |  NetworkAdminRole      |               |  WorkloadAdminRole     |
|  (SecOps & Log Org)    |               |  (Network Hub & TGW)   |               |  (App Spoke Accounts)  |
+------------------------+               +------------------------+               +------------------------+
```

### 1.1 Core IAM Roles Catalog
| Role Name | Trusted Principal | Allowed Actions | Condition Keys Enforced |
| :--- | :--- | :--- | :--- |
| `AWSAccelerator-SecurityAdminRole` | IAM Identity Center / SecOps SSO Group | Full SecOps & Security Hub / KMS Key Admin | `aws:MultiFactorAuthPresent: true`, `aws:PrincipalOrgID` |
| `AWSAccelerator-NetworkAdminRole` | IAM Identity Center / Network SSO Group | TGW, Direct Connect, Cloud WAN, Route 53 Profiles | `aws:PrincipalOrgID`, `aws:RequestedRegion: [us-east-1, us-west-2]` |
| `AWSAccelerator-PipelineOIDC-Role` | GitHub Actions (`token.actions.githubusercontent.com`) | Terraform IaC Plan & Apply | `token.actions.githubusercontent.com:sub: repo:enterprise/*` |
| `EKSPodIdentity-AppRole` | `pods.eks.amazonaws.com` (Pod Identity Agent) | S3, DynamoDB, Bedrock, RDS Connect | `aws:SourceAccount`, `aws:SourceArn: arn:aws:eks:*:*:podidentityassociation/*` |
| `AWSBackup-AirGappedServiceRole` | `backup.amazonaws.com` | Backup cross-account copy, restore | `aws:PrincipalAccount: <BackupVaultAccountID>` |
| `VPCLattice-GatewayAPIControllerRole` | `pods.eks.amazonaws.com` | VPC Lattice Service & Target Group management | `aws:SourceAccount`, `aws:PrincipalOrgID` |

---

## 2. Organization Service Control Policies (SCPs) & Resource Control Policies (RCPs)

### 2.1 SCP 1: Universal Region Restriction & Ingress Lockdown
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyUnapprovedRegions",
      "Effect": "Deny",
      "NotAction": [
        "iam:*",
        "organizations:*",
        "route53:*",
        "route53profiles:*",
        "cloudfront:*",
        "shield:*",
        "wafv2:*",
        "support:*",
        "health:*",
        "aws-portal:*",
        "budgets:*"
      ],
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:RequestedRegion": [
            "us-east-1",
            "us-west-2",
            "eu-west-1"
          ]
        }
      }
    },
    {
      "Sid": "DenyDirectInternetGatewayCreation",
      "Effect": "Deny",
      "Action": [
        "ec2:CreateInternetGateway",
        "ec2:AttachInternetGateway"
      ],
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:PrincipalAccount": [
            "${var.network_hub_account_id}"
          ]
        }
      }
    }
  ]
}
```

### 2.2 SCP 2: Mandatory Data Encryption & KMS Protection
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyUnencryptedS3Puts",
      "Effect": "Deny",
      "Action": "s3:PutObject",
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "s3:x-amz-server-side-encryption": "aws:kms"
        }
      }
    },
    {
      "Sid": "DenyUnencryptedEBSVolumeCreation",
      "Effect": "Deny",
      "Action": "ec2:CreateVolume",
      "Resource": "*",
      "Condition": {
        "Bool": {
          "ec2:Encrypted": "false"
        }
      }
    }
  ]
}
```

### 2.3 SCP 3: Enforce Bedrock Guardrails on Foundation Model Invocations
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyUnguardedBedrockInvocations",
      "Effect": "Deny",
      "Action": [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream"
      ],
      "Resource": "*",
      "Condition": {
        "Null": {
          "bedrock:GuardrailIdentifier": "true"
        }
      }
    }
  ]
}
```

### 2.4 RCP: Organization Data Perimeter Boundary (Resource Control Policy)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EnforceOrgDataPerimeterWithServiceExceptions",
      "Effect": "Deny",
      "Principal": "*",
      "Action": [
        "s3:*",
        "kms:*",
        "secretsmanager:*"
      ],
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:PrincipalOrgID": "o-enterpriseorg123"
        },
        "BoolIfExists": {
          "aws:PrincipalIsAWSService": "false"
        }
      }
    }
  ]
}
```
