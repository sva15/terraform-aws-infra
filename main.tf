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

# Configure AWS Provider
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = local.common_tags
  }
}

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
  
  dynamic "filter" {
    for_each = var.subnet_names
    content {
      name   = "tag:Name"
      values = [filter.value]
    }
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
  
  dynamic "filter" {
    for_each = var.public_subnet_names
    content {
      name   = "tag:Name"
      values = [filter.value]
    }
  }
}

data "aws_security_groups" "selected" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
  
  dynamic "filter" {
    for_each = var.security_group_names
    content {
      name   = "tag:Name"
      values = [filter.value]
    }
  }
}

# Backend Module - Lambda Functions
module "backend" {
  source = "./modules/backend"
  
  environment                = var.environment
  project_name              = var.project_name
  lambda_prefix             = var.lambda_prefix
  use_local_source          = var.use_local_source
  lambda_code_s3_bucket     = var.lambda_code_s3_bucket
  lambda_layers_s3_bucket   = var.lambda_layers_s3_bucket
  lambda_code_local_path    = var.lambda_code_local_path
  lambda_layers_local_path  = var.lambda_layers_local_path
  create_s3_bucket          = var.create_s3_bucket
  s3_bucket_name           = var.s3_bucket_name
  vpc_id                   = data.aws_vpc.selected.id
  subnet_ids               = data.aws_subnets.selected.ids
  security_group_ids       = data.aws_security_groups.selected.ids
  lambda_runtime           = var.lambda_runtime
  lambda_timeout           = var.lambda_timeout
  lambda_memory_size       = var.lambda_memory_size
  lambda_layer_mappings    = var.lambda_layer_mappings
  common_tags              = local.common_tags
}

# Frontend Module - UI Application
module "frontend" {
  source = "./modules/frontend"
  
  environment           = var.environment
  project_name         = var.project_name
  vpc_id               = data.aws_vpc.selected.id
  public_subnet_id     = data.aws_subnets.public.ids[0]
  security_group_ids   = data.aws_security_groups.selected.ids
  use_local_ui_source  = var.use_local_ui_source
  ui_assets_local_path = var.ui_assets_local_path
  ui_s3_bucket        = var.ui_s3_bucket
  ecr_repositories    = var.ecr_repositories
  instance_type       = var.instance_type
  create_key_pair     = var.create_key_pair
  common_tags         = local.common_tags
}
