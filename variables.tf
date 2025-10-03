# Environment and workspace variables
variable "environment" {
  description = "Environment name (dev, int, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "int", "prod"], var.environment)
    error_message = "Environment must be one of: dev, int, prod."
  }
}

variable "project_name" {
  description = "Project name for tagging and naming"
  type        = string
  default     = "IFRS-InsightGen"
}

variable "lambda_prefix" {
  description = "Prefix for Lambda function names"
  type        = string
  default     = "insightgen"
}

# Source configuration
variable "use_local_source" {
  description = "Whether to use local files or S3 for Lambda code and layers"
  type        = bool
  default     = true
}

variable "lambda_code_s3_bucket" {
  description = "S3 bucket name for Lambda code (when not using local)"
  type        = string
  default     = ""
}

variable "lambda_layers_s3_bucket" {
  description = "S3 bucket name for Lambda layers (when not using local)"
  type        = string
  default     = ""
}

# Local paths
variable "lambda_code_local_path" {
  description = "Local path to Lambda function zip files"
  type        = string
  default     = "./backend/python-aws-lambda-functions"
}

variable "lambda_layers_local_path" {
  description = "Local path to Lambda layer zip files"
  type        = string
  default     = "./backend/lambda-layers"
}

# S3 bucket configuration (for uploading local files)
variable "create_s3_bucket" {
  description = "Whether to create S3 bucket for storing Lambda code and layers"
  type        = bool
  default     = true
}

variable "s3_bucket_name" {
  description = "Name of S3 bucket to create (if create_s3_bucket is true)"
  type        = string
  default     = ""
}

# VPC Configuration
variable "vpc_name" {
  description = "Name tag of the VPC to use"
  type        = string
}

variable "subnet_names" {
  description = "List of subnet name tags to use for Lambda functions"
  type        = list(string)
}

variable "security_group_names" {
  description = "List of security group name tags to use for Lambda functions"
  type        = list(string)
}

variable "public_subnet_names" {
  description = "List of public subnet name tags for EC2 instance"
  type        = list(string)
}

# Lambda Configuration
variable "lambda_runtime" {
  description = "Runtime for Lambda functions"
  type        = string
  default     = "python3.12"
}

variable "lambda_timeout" {
  description = "Timeout for Lambda functions in seconds"
  type        = number
  default     = 300
}

variable "lambda_memory_size" {
  description = "Memory size for Lambda functions in MB"
  type        = number
  default     = 512
}

# Layer configuration mapping
variable "lambda_layer_mappings" {
  description = "Map of Lambda function names to their required layers"
  type        = map(list(string))
  default     = {}
  # Example:
  # {
  #   "data-processor" = ["pandas-layer", "numpy-layer"]
  #   "api-handler" = ["requests-layer"]
  #   "ml-inference" = ["sklearn-layer", "pandas-layer"]
  # }
}

# Additional tags
variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# AWS Region
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

# Frontend/UI Configuration
variable "use_local_ui_source" {
  description = "Whether to use local UI assets or S3"
  type        = bool
  default     = true
}

variable "ui_assets_local_path" {
  description = "Local path to UI assets directory"
  type        = string
  default     = "./ui/dist"
}

variable "ui_s3_bucket" {
  description = "S3 bucket name for UI assets (when not using local)"
  type        = string
  default     = ""
}

variable "ui_s3_key" {
  description = "S3 key for UI build zip file"
  type        = string
  default     = "ifrs-ui-build.zip"
}

variable "ui_path" {
  description = "UI path for nginx routing (e.g., 'ui', 'app', 'dashboard')"
  type        = string
  default     = "ui"
}

variable "base_url" {
  description = "Base URL for the UI application (runtime environment variable)"
  type        = string
  default     = ""
}

# ECR Configuration
variable "ecr_repositories" {
  description = "List of ECR repository names to create"
  type        = list(string)
  default     = ["angular-ui", "nginx-alpine"]
}

# EC2 Configuration
variable "instance_type" {
  description = "EC2 instance type for UI server"
  type        = string
  default     = "t3.micro"
}

variable "create_key_pair" {
  description = "Whether to create a new key pair for EC2 instance"
  type        = bool
  default     = true
}

# SNS Configuration
variable "sns_topic_names" {
  description = "List of SNS topic names to create"
  type        = list(string)
  default     = []
}

variable "lambda_sns_subscriptions" {
  description = "Map of Lambda function names to their SNS topic subscriptions"
  type        = map(list(string))
  default     = {}
  # Example:
  # {
  #   "data-processor" = ["data-events", "file-upload"]
  #   "notification-handler" = ["user-notifications", "system-alerts"]
  # }
}

variable "enable_sns_encryption" {
  description = "Enable SNS topic encryption"
  type        = bool
  default     = true
}

# AMI Configuration
variable "ami_id" {
  description = "Specific AMI ID to use (overrides ami_name_pattern if provided)"
  type        = string
  default     = ""
}

variable "ami_owner" {
  description = "AMI owner (account ID for shared AMIs)"
  type        = string
  default     = "self"
}

variable "ami_name_pattern" {
  description = "AMI name pattern to search for"
  type        = string
  default     = "ubuntu-*"
}

# Database Configuration
variable "deploy_database" {
  description = "Whether to deploy PostgreSQL and pgAdmin"
  type        = bool
  default     = true
}

variable "postgres_db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "ifrs_dev"
}

variable "postgres_user" {
  description = "PostgreSQL username"
  type        = string
  default     = "ifrs_user"
}

variable "use_secrets_manager" {
  description = "Whether to use AWS Secrets Manager for RDS password management"
  type        = bool
  default     = true
}

variable "postgres_password" {
  description = "PostgreSQL password (only used if use_secrets_manager is false)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "pgadmin_email" {
  description = "pgAdmin default email"
  type        = string
  default     = "admin@example.com"
}

variable "pgadmin_password" {
  description = "pgAdmin default password"
  type        = string
  default     = "admin123"
  sensitive   = true
}

variable "postgres_port" {
  description = "PostgreSQL port"
  type        = number
  default     = 5432
}

variable "pgadmin_port" {
  description = "pgAdmin port"
  type        = number
  default     = 8080
}

variable "sql_backup_s3_bucket" {
  description = "S3 bucket containing SQL backup file"
  type        = string
  default     = ""
}

variable "sql_backup_s3_key" {
  description = "S3 key for SQL backup file"
  type        = string
  default     = ""
}

variable "sql_backup_local_path" {
  description = "Local path to SQL backup file"
  type        = string
  default     = ""
}
