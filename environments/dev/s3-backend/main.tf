# Global S3 Backend Resources
# This module creates S3 buckets for Terraform state management with native S3 locking

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  environments = ["dev", "staging", "prod"]
  common_tags = {
    Module     = "s3-backend"
    Created_by = "Terraform"
    Purpose    = "Terraform State Management"
  }
}

# S3 buckets for Terraform state (one per environment)
resource "aws_s3_bucket" "terraform_state" {
  for_each = toset(local.environments)
  
  bucket = "terraform-state-ifrs-${each.value}"

  tags = merge(local.common_tags, {
    Name        = "terraform-state-ifrs-${each.value}"
    Environment = each.value
  })
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "terraform_state" {
  for_each = aws_s3_bucket.terraform_state
  
  bucket = each.value.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  for_each = aws_s3_bucket.terraform_state
  
  bucket = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  for_each = aws_s3_bucket.terraform_state
  
  bucket = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Note: DynamoDB tables are no longer needed for state locking
# Modern Terraform versions support S3 native state locking with use_lockfile = true

# KMS key for production state encryption (optional)
resource "aws_kms_key" "terraform_state_prod" {
  count = var.create_kms_key ? 1 : 0
  
  description             = "KMS key for production Terraform state encryption"
  deletion_window_in_days = 7

  tags = merge(local.common_tags, {
    Name        = "terraform-state-prod-key"
    Environment = "prod"
  })
}

resource "aws_kms_alias" "terraform_state_prod" {
  count = var.create_kms_key ? 1 : 0
  
  name          = "alias/terraform-state-prod"
  target_key_id = aws_kms_key.terraform_state_prod[0].key_id
}
