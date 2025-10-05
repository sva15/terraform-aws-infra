# Production Environment Configuration

# Basic Configuration
aws_region         = "us-east-1"
project_name       = "IFRS-InsightGen"
iam_role_prefix    = "HCL-User-Role"
project_short_name = "insightgen"

# Network Configuration (Private Subnets Only)
vpc_name               = "prod-vpc"
subnet_names           = ["prod-private-subnet-1", "prod-private-subnet-2"]
security_group_names   = ["prod-app-sg", "prod-db-sg"]

# Lambda Configuration
lambda_prefix            = "prod-ifrs"
use_local_source         = false
lambda_code_s3_bucket    = "prod-ifrs-lambda-code"
lambda_layers_s3_bucket  = "prod-ifrs-lambda-layers"
lambda_code_local_path   = "../../backend/python-aws-lambda-functions"
lambda_layers_local_path = "../../backend/lambda-layers"
lambda_runtime           = "python3.12"
lambda_timeout           = 900
lambda_memory_size       = 2048

# Lambda Layer Mappings
lambda_layer_mappings = {
  "alb-lambda" = ["alb-layer"]
  "sns-lambda" = ["sns-layer"]
}

# SNS Configuration
sns_topic_names = ["prod-ifrs-notifications", "prod-ifrs-alerts"]
lambda_sns_subscriptions = {
  "prod-ifrs-notifications" = ["sns-lambda"]
  "prod-ifrs-alerts"        = ["sns-lambda"]
}
enable_sns_encryption = true

# S3 Configuration
create_s3_bucket = true
s3_bucket_name   = "prod-ifrs-insightgen-bucket"

# UI Configuration
use_local_ui_source  = false
ui_s3_bucket         = "prod-ifrs-ui-assets"
ui_s3_key            = "ui-assets.zip"
ui_assets_local_path = "../../ui"
ui_path              = "/var/www/html"
BASE_URL             = "https://ifrs-insightgen.com"

# ECR Configuration
ecr_repositories = ["prod-ifrs-app", "prod-ifrs-worker"]

# EC2 Configuration
instance_type       = "t3.large"
create_key_pair     = true
ami_owner           = "099720109477"
ami_name_pattern    = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"

# Database Configuration
deploy_database     = true
postgres_db_name    = "prod_ifrs_db"
postgres_port       = 5432
use_secrets_manager = true
pgadmin_email       = "admin@ifrs-insightgen.com"
pgadmin_port        = 8080

# SQL Backup Configuration
sql_backup_s3_bucket  = "prod-ifrs-db-backups"
sql_backup_s3_key     = "backups/prod_backup.sql"
sql_backup_local_path = "../../database/pg_backup"
