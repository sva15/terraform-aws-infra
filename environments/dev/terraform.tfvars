# Development Environment Configuration

# Basic Configuration
aws_region         = "us-east-1"
project_name       = "IFRS-InsightGen"
iam_role_prefix    = "HCL-User-Role"
project_short_name = "insightgen"

# Network Configuration
vpc_name               = "default"
subnet_names           = ["default-subnet-1", "default-subnet-2"]
public_subnet_names    = ["default-public-subnet-1"]
security_group_names   = ["default"]

# Lambda Configuration
lambda_prefix            = "dev-ifrs"
use_local_source         = true
artifacts_s3_bucket      = ""  # Leave empty to create new bucket
create_s3_bucket         = true
lambda_code_local_path   = "../../backend/python-aws-lambda-functions"
lambda_layers_local_path = "../../backend/lambda-layers"
ui_assets_local_path     = "../../ui"
lambda_runtime           = "python3.12"
lambda_timeout           = 300
lambda_memory_size       = 512

# Lambda Layer Mappings
lambda_layer_mappings = {
  "sns-lambda" = ["sns-layer"]
}

# SNS Configuration
sns_topic_names = ["dev-ifrs-notifications"]
lambda_sns_subscriptions = {
  "dev-ifrs-notifications" = ["sns-lambda"]
}
enable_sns_encryption = true

# S3 Configuration
create_s3_bucket = true
s3_bucket_name   = "dev-ifrs-insightgen-bucket"

# UI Configuration
use_local_ui_source  = true
ui_assets_local_path = "../../ui"
ui_path              = "/var/www/html"
BASE_URL             = "http://localhost:8080"

# ECR Configuration
ecr_repositories = ["dev-ifrs-app"]

# EC2 Configuration
instance_type       = "t3.micro"
create_key_pair     = true
ami_owner           = "099720109477"
ami_name_pattern    = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"

# Database Configuration
postgres_db_name      = "ifrs_db"
postgres_password     = "SecurePassword123!"
postgres_port         = 5432
use_secrets_manager   = true
deploy_database       = true

# SQL Backup Configuration (unified S3 bucket)
sql_backup_s3_bucket  = ""  # Will use unified artifacts bucket
sql_backup_s3_key     = ""  # Will use database/ folder structure
sql_backup_local_path = "../../database/pg_backup"
