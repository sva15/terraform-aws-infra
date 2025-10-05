# Global Networking Data Sources
# This module contains only data sources for existing VPC and networking resources

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
    Module     = "global-networking"
    Created_by = "Terraform"
    Purpose    = "Networking Data Sources"
  }
}

# Data source for VPC by name
data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

# Data source for private subnets
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  filter {
    name   = "tag:Name"
    values = var.private_subnet_names
  }
}

# Public subnets removed - using private subnets only for security

# Data source for security groups
data "aws_security_groups" "selected" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  filter {
    name   = "tag:Name"
    values = var.security_group_names
  }
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}
