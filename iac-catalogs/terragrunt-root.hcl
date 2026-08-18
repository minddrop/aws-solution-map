# Root Terragrunt Configuration for Enterprise AWS Solution Map

locals {
  # Parse account and region variables dynamically from path hierarchy
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl", "fallback_account.hcl"))
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl", "fallback_region.hcl"))

  account_id   = local.account_vars.locals.aws_account_id
  account_name = local.account_vars.locals.account_name
  aws_region   = local.region_vars.locals.aws_region

  organization_id = "o-enterpriseorg123"
  terraform_state_bucket = "enterprise-tfstate-${local.account_id}-${local.aws_region}"
}

# Generate central S3 remote state backend with DynamoDB locking and KMS encryption
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = local.terraform_state_bucket
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.aws_region
    encrypt        = true
    dynamodb_table = "enterprise-tf-locks"
    s3_bucket_tags = {
      Owner       = "PlatformEngineering"
      Environment = "Management"
      ManagedBy   = "Terragrunt"
    }
  }
}

# Generate AWS provider configurations with automated cross-account assume-role
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.9.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.14.0"
    }
  }
}

provider "aws" {
  region = "${local.aws_region}"

  assume_role {
    role_arn     = "arn:aws:iam::${local.account_id}:role/AWSAccelerator-PipelineOIDC-Role"
    session_name = "terragrunt-pipeline-${local.account_name}"
  }

  default_tags {
    tags = {
      ApplicationID   = "EnterprisePlatform"
      Environment     = "${local.account_name}"
      Owner           = "PlatformEngineering"
      ManagedBy       = "Terraform/Terragrunt"
      OrganizationID  = "${local.organization_id}"
    }
  }
}
EOF
}
