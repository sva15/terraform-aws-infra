# Frontend Module Variables

variable "environment" {
  description = "Environment name (dev, int, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging and naming"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to deploy resources"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID for EC2 instance (will be used as private subnet since no public IP)"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for RDS deployment"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
}

# UI Configuration
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

variable "BASE_URL" {
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
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "create_key_pair" {
  description = "Whether to create a new key pair"
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

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-south-1"
}

# Lambda Configuration for RDS module
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

variable "lambda_layer_mappings" {
  description = "Map of Lambda function names to their required layers"
  type        = map(list(string))
  default     = {}
}

variable "lambda_layers" {
  description = "Map of layer names to their ARNs"
  type        = map(string)
  default     = {}
}
