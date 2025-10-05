# Development Environment Variables

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "IFRS-InsightGen"
}

variable "iam_role_prefix" {
  description = "Prefix for IAM role names"
  type        = string
  default     = "HCL-User-Role"
}

variable "project_short_name" {
  description = "Short project name for IAM role naming"
  type        = string
  default     = "insightgen"
}

variable "vpc_name" {
  description = "Name of the VPC to use"
  type        = string
  default     = "default"
}

variable "subnet_names" {
  description = "List of subnet names to use"
  type        = list(string)
  default     = ["default-subnet-1", "default-subnet-2"]
}

# Public subnets removed - using private subnets only for security

variable "security_group_names" {
  description = "List of security group names"
  type        = list(string)
  default     = ["default"]
}

variable "lambda_prefix" {
  description = "Prefix for Lambda function names"
  type        = string
  default     = "dev-ifrs"
}

variable "use_local_source" {
  description = "Whether to use local source for Lambda functions"
  type        = bool
  default     = true
}

variable "artifacts_s3_bucket" {
  description = "S3 bucket name for all artifacts (Lambda code, layers, UI). If empty, a bucket will be created"
  type        = string
  default     = ""
}

variable "lambda_code_local_path" {
  description = "Local path to Lambda code"
  type        = string
  default     = "../../backend/python-aws-lambda-functions"
}

variable "lambda_layers_local_path" {
  description = "Local path to Lambda layers"
  type        = string
  default     = "../../backend/lambda-layers"
}

variable "create_s3_bucket" {
  description = "Whether to create S3 bucket"
  type        = bool
  default     = true
}

variable "s3_bucket_name" {
  description = "Name of S3 bucket"
  type        = string
  default     = "dev-ifrs-insightgen-bucket"
}

variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.12"
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 300
}

variable "lambda_memory_size" {
  description = "Lambda memory size in MB"
  type        = number
  default     = 512
}

variable "lambda_layer_mappings" {
  description = "Mapping of Lambda functions to layers"
  type        = map(list(string))
  default = {
    "alb-lambda" = ["alb-layer"]
    "sns-lambda" = ["sns-layer"]
  }
}

variable "sns_topic_names" {
  description = "List of SNS topic names"
  type        = list(string)
  default     = ["dev-ifrs-notifications"]
}

variable "lambda_sns_subscriptions" {
  description = "Lambda SNS subscriptions"
  type        = map(list(string))
  default = {
    "dev-ifrs-notifications" = ["sns-lambda"]
  }
}

variable "enable_sns_encryption" {
  description = "Enable SNS encryption"
  type        = bool
  default     = true
}

variable "use_local_ui_source" {
  description = "Whether to use local UI source"
  type        = bool
  default     = true
}

variable "ui_assets_local_path" {
  description = "Local path to UI assets"
  type        = string
  default     = "../../ui"
}

variable "ui_s3_bucket" {
  description = "S3 bucket for UI assets"
  type        = string
  default     = ""
}

variable "ui_s3_key" {
  description = "S3 key for UI assets"
  type        = string
  default     = ""
}

variable "ui_path" {
  description = "Path to UI files"
  type        = string
  default     = "/var/www/html"
}

variable "BASE_URL" {
  description = "Base URL for the application"
  type        = string
  default     = "http://localhost:8080"
}

variable "ecr_repositories" {
  description = "List of ECR repositories"
  type        = list(string)
  default     = ["dev-ifrs-app"]
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "create_key_pair" {
  description = "Whether to create key pair"
  type        = bool
  default     = true
}

variable "ami_id" {
  description = "AMI ID to use"
  type        = string
  default     = ""
}

variable "ami_owner" {
  description = "AMI owner"
  type        = string
  default     = "099720109477"
}

variable "ami_name_pattern" {
  description = "AMI name pattern"
  type        = string
  default     = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
}

variable "deploy_database" {
  description = "Whether to deploy database"
  type        = bool
  default     = true
}

variable "postgres_db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "dev_ifrs_db"
}

variable "postgres_password" {
  description = "PostgreSQL password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "postgres_port" {
  description = "PostgreSQL port"
  type        = number
  default     = 5432
}

variable "use_secrets_manager" {
  description = "Whether to use AWS Secrets Manager"
  type        = bool
  default     = true
}

variable "pgadmin_email" {
  description = "PgAdmin email"
  type        = string
  default     = "admin@dev.local"
}

variable "pgadmin_password" {
  description = "PgAdmin password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "pgadmin_port" {
  description = "PgAdmin port"
  type        = number
  default     = 8080
}

variable "sql_backup_s3_bucket" {
  description = "S3 bucket for SQL backup"
  type        = string
  default     = ""
}

variable "sql_backup_s3_key" {
  description = "S3 key for SQL backup"
  type        = string
  default     = ""
}

variable "sql_backup_local_path" {
  description = "Local path to SQL backup files directory"
  type        = string
  default     = "../../database/pg_backup"
