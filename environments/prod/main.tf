# Staging Environment Configuration
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
  environment = "prod"
  common_tags = {
    Environment = local.environment
    Project     = var.project_name
    Created_by  = "Terraform"
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

# Lambda Module - Lambda Functions and Layers
module "lambda" {
  source = "../../modules/lambda"

  environment              = local.environment
  project_name             = var.project_name
  iam_role_prefix          = var.iam_role_prefix
  project_short_name       = var.project_short_name
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
  common_tags              = local.common_tags
}

# ECR Module for container registries
module "ecr" {
  source = "../../modules/ecr"

  environment  = local.environment
  project_name = var.project_name
  repositories = var.ecr_repositories
  common_tags  = local.common_tags
}

# S3 Module for UI assets (conditional)
module "s3" {
  source = "../../modules/s3"

  environment          = local.environment
  project_name         = var.project_name
  create_ui_bucket     = var.use_local_ui_source
  use_local_ui_source  = var.use_local_ui_source
  ui_assets_local_path = var.ui_assets_local_path
  common_tags          = local.common_tags
}

# EC2 Module for hosting the UI application
module "ec2" {
  source = "../../modules/ec2"

  environment        = local.environment
  project_name       = var.project_name
  iam_role_prefix    = var.iam_role_prefix
  project_short_name = var.project_short_name
  vpc_id             = data.aws_vpc.selected.id
  subnet_id          = length(data.aws_subnets.public.ids) > 0 ? data.aws_subnets.public.ids[0] : null
  security_group_ids = data.aws_security_groups.selected.ids
  instance_type      = var.instance_type
  create_key_pair    = var.create_key_pair
  ecr_repository_url = module.ecr.repository_urls[var.ecr_repositories[0]]

  # UI Configuration
  ui_s3_bucket = var.ui_s3_bucket
  ui_s3_key    = var.ui_s3_key
  ui_path      = var.ui_path
  BASE_URL     = var.BASE_URL
  aws_region   = var.aws_region

  # AMI Configuration
  ami_id           = var.ami_id
  ami_owner        = var.ami_owner
  ami_name_pattern = var.ami_name_pattern

  # Database Configuration
  deploy_database       = var.deploy_database
  postgres_db_name      = var.postgres_db_name
  postgres_password     = var.postgres_password
  pgadmin_email         = var.pgadmin_email
  pgadmin_password      = var.pgadmin_password
  postgres_port         = var.postgres_port
  pgadmin_port         = var.pgadmin_port
  sql_backup_s3_bucket  = var.sql_backup_s3_bucket
  sql_backup_s3_key     = var.sql_backup_s3_key
  sql_backup_local_path = var.sql_backup_local_path

  common_tags = local.common_tags

  depends_on = [module.ecr]
}

# RDS Module for PostgreSQL database
module "rds" {
  source = "../../modules/rds"

  environment        = local.environment
  project_name       = var.project_name
  iam_role_prefix    = var.iam_role_prefix
  project_short_name = var.project_short_name
  vpc_id             = data.aws_vpc.selected.id
  subnet_ids         = data.aws_subnets.selected.ids
  security_group_ids = data.aws_security_groups.selected.ids

  # Database Configuration
  db_name             = var.postgres_db_name
  db_password         = var.postgres_password
  db_port             = var.postgres_port
  use_secrets_manager = var.use_secrets_manager

  # RDS Instance Configuration
  instance_class    = "db.t3.medium"
  allocated_storage = 100
  storage_encrypted = true

  # Backup Configuration
  backup_retention_period = 30
  skip_final_snapshot     = false
  deletion_protection     = true

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
    for name, layer in module.lambda.lambda_layers : name => layer.arn
  }

  common_tags = local.common_tags
}
