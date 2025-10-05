# Staging Environment Provider Configuration

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "staging"
      Project     = var.project_name
      Created_by  = "Terraform"
      ManagedBy   = "Terraform"
    }
  }
}

# Get current AWS region and caller identity for reference
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
