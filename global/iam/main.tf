# Global IAM Resources
# This module contains IAM roles and policies that are shared across environments

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
  common_tags = {
    Module     = "global-iam"
    Created_by = "Terraform"
    Purpose    = "Shared IAM Resources"
  }
}

# Cross-account role for Terraform operations
resource "aws_iam_role" "terraform_cross_account" {
  name = "HCL-User-Role-insightgen-terraform-cross-account"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = var.trusted_account_ids
        }
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.external_id
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "HCL-User-Role-insightgen-terraform-cross-account"
  })
}

# Policy for Terraform operations
resource "aws_iam_policy" "terraform_operations" {
  name        = "TerraformOperationsPolicy"
  description = "Policy for Terraform operations across environments"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "lambda:*",
          "s3:*",
          "rds:*",
          "sns:*",
          "iam:*",
          "ecr:*",
          "secretsmanager:*",
          "kms:*",
          "logs:*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "terraform_operations" {
  role       = aws_iam_role.terraform_cross_account.name
  policy_arn = aws_iam_policy.terraform_operations.arn
}

# Global service roles that can be referenced by environments
resource "aws_iam_role" "global_lambda_execution" {
  name = "HCL-User-Role-insightgen-global-lambda-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name    = "HCL-User-Role-insightgen-global-lambda-execution"
    Service = "lambda"
  })
}

# Attach AWS managed policies to global Lambda role
resource "aws_iam_role_policy_attachment" "global_lambda_basic" {
  role       = aws_iam_role.global_lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "global_lambda_vpc" {
  role       = aws_iam_role.global_lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
