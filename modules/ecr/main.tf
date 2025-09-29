locals {
  # Environment prefix for naming
  env_prefix = var.environment == "prod" ? "" : "${var.environment}-"
}

# ECR Repositories
resource "aws_ecr_repository" "repositories" {
  for_each = toset(var.repositories)

  name                 = "${local.env_prefix}${var.project_name}-${each.value}"
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(var.common_tags, {
    Name       = "${local.env_prefix}${var.project_name}-${each.value}"
    Repository = each.value
    Module     = "ecr"
  })
}

# ECR Lifecycle Policy
resource "aws_ecr_lifecycle_policy" "policy" {
  for_each = toset(var.repositories)

  repository = aws_ecr_repository.repositories[each.value].name

  policy = var.lifecycle_policy != "" ? var.lifecycle_policy : jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images older than 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ECR Repository Policy (for cross-account access if needed)
resource "aws_ecr_repository_policy" "policy" {
  for_each = toset(var.repositories)

  repository = aws_ecr_repository.repositories[each.value].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPushPull"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
      }
    ]
  })
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}
