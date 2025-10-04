# Environment Configuration
environment = "dev"  # Options: dev, int, prod
aws_region = "ap-south-1"
# Project Configuration
project_name = "IFRS-InsightGen"
lambda_prefix = "insightgen"

# Source Configuration
use_local_source = true  # Set to false to use S3 sources
create_s3_bucket = false  # Create S3 bucket for uploading local files

# S3 Configuration (when use_local_source = false)
lambda_code_s3_bucket = "filterrithas"     # S3 bucket containing Lambda code
lambda_layers_s3_bucket = "filterrithas"   # S3 bucket containing Lambda layers

# Local Paths (when use_local_source = true)
lambda_code_local_path = "./backend/python-aws-lambda-functions"
lambda_layers_local_path = "./backend/lambda-layers"

# S3 Bucket Name (optional - will be auto-generated if not provided)
#s3_bucket_name = "filterrithas"

# VPC Configuration
vpc_name = "ifrs-vpc-vpc"
subnet_names = [
  "ifrs-vpc-subnet-private2-ap-south-1b",
  "ifrs-vpc-subnet-private1-ap-south-1a"
]
security_group_names = [
  "ifrs-vpc-sg"
]
public_subnet_names = [
  "ifrs-vpc-subnet-public2-ap-south-1b",
  "ifrs-vpc-subnet-public1-ap-south-1a"
]
# Lambda Configuration
lambda_runtime = "python3.12"
lambda_timeout = 300
lambda_memory_size = 512

# Lambda Layer Mappings (which layers each function should use)
lambda_layer_mappings = {
  "alb-lambda" = ["alb-layer"]
  "sns-lambda" = ["sns-layer"]
  "db-restore" = ["lambda-deps-layer"]

  # Add more mappings as needed
  # "function_name" = ["layer1", "layer2"]
}
sns_topic_names = [
  "sns-lambda-topic"
]

# SNS Subscriptions - Define which Lambda functions subscribe to which topics
lambda_sns_subscriptions = {
  "sns-lambda" = ["sns-lambda-topic"]
  # Add more subscriptions as needed
  # "function_name" = ["topic1", "topic2"]
}

enable_sns_encryption = true

# Additional Tags
additional_tags = {
  Owner       = "IFRS"
  CostCenter  = "Engineering"
  Application = "InsightGen"
}


# Frontend/UI Configuration
#use_local_ui_source = true  # Set to false to use existing S3 bucket

# ECR Configuration
ecr_repositories = ["angular-ui", "nginx-alpine"]

# Frontend Configuration
instance_type = "t3.micro"
create_key_pair = true

# UI Build Configuration
use_local_ui_source = false  # Set to true to use local UI build
ui_s3_bucket = "filterrithas"  # S3 bucket containing UI build
ui_s3_key = "ui-build"  # S3 key prefix for UI build files
ui_assets_local_path = ""  # Local path to UI build (leave empty when using S3)
ui_path = "ui"  # UI routing path
BASE_URL = "https://api.yourdomain.com"  # Base URL for API calls

# AMI Configuration (for shared custom AMIs)
ami_id = "ami-02d26659fd82cf299"  # Specific AMI ID (leave empty to use ami_name_pattern)
ami_owner = "099720109477"  # replace with the account ID that shared the AMI
ami_name_pattern = "ubuntu-*"  # Pattern to search for Ubuntu-based AMIs

# Database Configuration (RDS PostgreSQL)
deploy_database = true
postgres_db_name = "ifrs_dev"
postgres_user = "ifrs_user"
postgres_port = 5432

# Password Management
use_secrets_manager = true  # Recommended: Use AWS Secrets Manager for password
postgres_password = ""      # Only required if use_secrets_manager = false

# Note: When use_secrets_manager = true, RDS will automatically generate and store
# the password in AWS Secrets Manager. This is the recommended approach for security.

# SQL Backup Configuration (choose one method)
# Option 1: S3 backup (recommended for production)
sql_backup_s3_bucket = "filterrithas"  # S3 bucket containing backup file
sql_backup_s3_key = "postgres/ifrs_backup_20250928_144411.sql"     # S3 key for backup file

# Option 2: Local backup (for development only)
sql_backup_local_path = ""  # Local path to SQL backup file (leave empty when using S3)
