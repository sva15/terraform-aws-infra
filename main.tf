# Root Module - Terraform configuration
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

locals {
  # Common Tags
  common_tags = {
  Created_by = "Terraform"
  }
}
# Configure AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

# Debug: Get current region and caller identity for troubleshooting
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Debug: List all VPCs in the region to help troubleshoot
data "aws_vpcs" "all" {}

# Data sources for existing AWS resources
data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  filter {
    name   = "tag:Name"
    values = var.subnet_names
  }
  
  lifecycle {
    postcondition {
      condition     = length(self.ids) > 0
      error_message = "No subnets found with names: ${join(", ", var.subnet_names)} in VPC ${data.aws_vpc.selected.id}"
    }
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  filter {
    name   = "tag:Name"
    values = var.public_subnet_names
  }
}

data "aws_security_groups" "selected" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  filter {
    name   = "tag:Name"
    values = var.security_group_names
  }
  
  lifecycle {
    postcondition {
      condition     = length(self.ids) > 0
      error_message = "No security groups found with names: ${join(", ", var.security_group_names)} in VPC ${data.aws_vpc.selected.id}"
    }
  }
}


# Backend Module - Lambda Functions
module "backend" {
  source = "./modules/backend"

  environment              = var.environment
  project_name             = var.project_name
  lambda_prefix            = var.lambda_prefix
  use_local_source         = var.use_local_source
  lambda_code_s3_bucket    = var.lambda_code_s3_bucket
  lambda_layers_s3_bucket  = var.lambda_layers_s3_bucket
  lambda_code_local_path   = var.lambda_code_local_path
  lambda_layers_local_path = var.lambda_layers_local_path
  create_s3_bucket         = var.create_s3_bucket
  s3_bucket_name           = var.s3_bucket_name
  vpc_id                   = data.aws_vpc.selected.id
  subnet_ids               = data.aws_subnets.selected.ids
  security_group_ids       = data.aws_security_groups.selected.ids
  lambda_runtime           = var.lambda_runtime
  lambda_timeout           = var.lambda_timeout
  lambda_memory_size       = var.lambda_memory_size
  lambda_layer_mappings    = var.lambda_layer_mappings
  sns_topic_names          = var.sns_topic_names
  lambda_sns_subscriptions = var.lambda_sns_subscriptions
  enable_sns_encryption    = var.enable_sns_encryption
  # common_tags              = local.common_tags
}

# Frontend Module - UI Application
module "frontend" {
  source = "./modules/frontend"

  environment          = var.environment
  project_name         = var.project_name
  aws_region           = var.aws_region
  vpc_id               = data.aws_vpc.selected.id
  public_subnet_id     = length(data.aws_subnets.public.ids) > 0 ? data.aws_subnets.public.ids[0] : null
  private_subnet_ids   = data.aws_subnets.selected.ids
  security_group_ids   = data.aws_security_groups.selected.ids
  use_local_ui_source  = var.use_local_ui_source
  ui_assets_local_path = var.ui_assets_local_path
  ui_s3_bucket         = var.ui_s3_bucket
  ui_s3_key            = var.ui_s3_key
  ui_path              = var.ui_path
  BASE_URL             = var.BASE_URL
  ecr_repositories     = var.ecr_repositories
  instance_type        = var.instance_type
  create_key_pair      = var.create_key_pair

  # AMI Configuration
  ami_id           = var.ami_id
  ami_owner        = var.ami_owner
  ami_name_pattern = var.ami_name_pattern

  # Database Configuration
  deploy_database       = var.deploy_database
  postgres_db_name      = var.postgres_db_name
  postgres_password     = var.postgres_password
  postgres_port         = var.postgres_port
  use_secrets_manager   = var.use_secrets_manager
  pgadmin_email         = var.pgadmin_email
  pgadmin_password      = var.pgadmin_password
  pgadmin_port         = var.pgadmin_port
  # SQL Backup Configuration
  sql_backup_s3_bucket  = var.sql_backup_s3_bucket
  sql_backup_s3_key     = var.sql_backup_s3_key
  sql_backup_local_path = var.sql_backup_local_path

  # Lambda Configuration
  lambda_runtime        = var.lambda_runtime
  lambda_timeout        = var.lambda_timeout
  lambda_memory_size    = var.lambda_memory_size
  lambda_layer_mappings = var.lambda_layer_mappings
  lambda_layers = {
    for name, layer in module.backend.lambda_layers : name => layer.arn
  }

  #common_tags           = local.common_tags
}

# Debug outputs for Lambda layers
output "debug_lambda_layers" {
  description = "Debug lambda layers from backend"
  value = module.backend.lambda_layers
}

output "debug_layer_mapping" {
  description = "Debug layer ARN mapping"
  value = {
    for name, layer in module.backend.lambda_layers : name => layer.arn
  }
}

# Debug outputs
output "debug_vpc_info" {
  description = "Debug information about VPC lookup"
  value = {
    region_configured = var.aws_region
    region_actual     = data.aws_region.current.name
    account_id        = data.aws_caller_identity.current.account_id
    vpc_name_used     = var.vpc_name
    vpc_found         = length(data.aws_vpc.selected.id) > 0 ? "Yes" : "No"
    vpc_count         = length(data.aws_vpcs.all.ids)
  }
}

output "debug_network_resources" {
  description = "Debug network resources for Lambda"
  value = {
    vpc_id = data.aws_vpc.selected.id
    subnet_names_searched = var.subnet_names
    subnets_found = data.aws_subnets.selected.ids
    subnet_count = length(data.aws_subnets.selected.ids)
    security_group_names_searched = var.security_group_names
    security_groups_found = data.aws_security_groups.selected.ids
    security_group_count = length(data.aws_security_groups.selected.ids)
  }
}
