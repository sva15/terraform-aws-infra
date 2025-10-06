# Development Environment Configuration

# Basic Configuration
aws_region         = "ap-south-1"
project_name       = "IFRS-InsightGen"
iam_role_prefix    = "HCL-User-Role"
project_short_name = "insightgen"

# Network Configuration (Private Subnets Only)
vpc_name               = "ifrs-vpc-vpc"
subnet_names           = ["ifrs-vpc-subnet-private1-ap-south-1a", "ifrs-vpc-subnet-private2-ap-south-1b"]
security_group_names   = ["ifrs-vpc-sg"]

# Lambda Configuration (HYBRID: Local code + Mixed layers)
lambda_prefix            = "dev-ifrs"
use_local_source         = true                                    # Upload Lambda code from local
artifacts_s3_bucket      = "filterrithas"                         # Existing S3 bucket
create_s3_bucket         = false                                   # Don't create new bucket
lambda_code_local_path   = "../../backend/python-aws-lambda-functions"  # Local Lambda code
lambda_layers_local_path = "../../backend/lambda-layers"         # Local layers for db-restore function
lambda_runtime           = "python3.12"
lambda_timeout           = 300
lambda_memory_size       = 512

# Alternative local paths (commented for future use)
# lambda_code_local_path   = "C:/path/to/your/lambda/functions"
# lambda_layers_local_path = "C:/path/to/your/lambda/layers"
# ui_assets_local_path     = "C:/path/to/your/ui/build"

# Lambda Layer Mappings (mixed: S3 layers + local layer for db-restore)
lambda_layer_mappings = {
  "sns-lambda" = ["sns-layer"]          # Use existing layer from S3
  "alb-lambda" = ["alb-layer"]          # Use existing layer from S3
  "db-restore" = ["lambda-deps-layer"]  # Use local layer for db-restore function
}

# SNS Configuration
sns_topic_names = ["dev-ifrs-notifications"]
lambda_sns_subscriptions = {
  "sns-lambda" = ["dev-ifrs-notifications"]
}
enable_sns_encryption = true

# S3 Configuration (using existing bucket)
# Note: artifacts_s3_bucket is set above in Lambda Configuration

# UI Configuration
use_local_ui_source  = true
ui_assets_local_path = "../../ui"
ui_path              = "ui-assets.zip"
BASE_URL             = "http://localhost:8080"

# ECR Configuration
ecr_repositories = ["dev-ifrs-app"]

# EC2 Configuration
instance_type       = "t3.micro"
create_key_pair     = true
ami_owner           = "099720109477"
ami_name_pattern    = "ubuntu/*"

# Database Configuration
postgres_db_name      = "ifrs_dev"
postgres_password     = "SecurePassword123!"
postgres_port         = 5432
use_secrets_manager   = true
deploy_database       = true

# SQL Backup Configuration (S3 path - existing files)
sql_backup_s3_bucket  = "filterrithas"                    # Existing S3 bucket
sql_backup_s3_key     = "postgres/ifrs_backup_20250928_144411.sql"  # Existing SQL file in S3
sql_backup_local_path = ""                                 # Empty = use S3 files, not local

# Alternative local SQL backup path (commented for future use)
# sql_backup_local_path = "../../database/pg_backup"
# sql_backup_local_path = "C:/path/to/your/sql/backups"

lambda_env_vars = {
  "sns-lambda" = {
    ENVIRONMENT = "dev"
    PROJECT     = "ifrs"
    FUNCTION    = "sns-lambda"
    TOPIC_NAME  = "dev-ifrs-notifications"
  }

  "alb-lambda" = {
    ENVIRONMENT = "dev"
    PROJECT     = "ifrs"
    FUNCTION    = "alb-lambda"
    ALB_NAME    = "ifrs-alb"
  }

  "db-restore" = {
    ENVIRONMENT = "dev"
    PROJECT     = "ifrs"
    FUNCTION    = "db-restore"
    DB_NAME     = "ifrs-db"
    DB_USER     = "admin"
  }
}

