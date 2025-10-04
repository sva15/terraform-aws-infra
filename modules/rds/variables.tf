# RDS Module Variables

variable "environment" {
  description = "Environment name (dev, int, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging and naming"
  type        = string
}

variable "lambda_prefix" {
  description = "Prefix for resource naming (to match with other modules)"
  type        = string
  default     = "insightgen"
}

variable "vpc_id" {
  description = "VPC ID where RDS will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for RDS subnet group"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for RDS instance"
  type        = list(string)
}

# Database Configuration
variable "db_name" {
  description = "Name of the database to create"
  type        = string
  default     = "ifrs_dev"
}

variable "db_username" {
  description = "Username for the master DB user"
  type        = string
  default     = "ifrs_user"
}

variable "db_password" {
  description = "Password for the RDS instance (only used if use_secrets_manager is false)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "use_secrets_manager" {
  description = "Whether to use AWS Secrets Manager for RDS password management"
  type        = bool
  default     = true
}

variable "db_port" {
  description = "The port on which the DB accepts connections"
  type        = number
  default     = 5432
}

# RDS Instance Configuration
variable "engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "17.4"
}

variable "instance_class" {
  description = "The instance type of the RDS instance"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "The allocated storage in gigabytes"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "The upper limit to which Amazon RDS can automatically scale the storage"
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "One of standard (magnetic), gp2 (general purpose SSD), or io1 (provisioned IOPS SSD)"
  type        = string
  default     = "gp2"
}

variable "storage_encrypted" {
  description = "Specifies whether the DB instance is encrypted"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "The ARN for the KMS encryption key"
  type        = string
  default     = ""
}

# Backup and Maintenance
variable "backup_retention_period" {
  description = "The days to retain backups for"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "The daily time range during which automated backups are created"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "The window to perform maintenance in"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before the DB instance is deleted"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "If the DB instance should have deletion protection enabled"
  type        = bool
  default     = false
}

# Monitoring and Performance
variable "monitoring_interval" {
  description = "The interval for collecting enhanced monitoring metrics"
  type        = number
  default     = 60
}

variable "performance_insights_enabled" {
  description = "Specifies whether Performance Insights are enabled"
  type        = bool
  default     = true
}

variable "performance_insights_retention_period" {
  description = "The amount of time in days to retain Performance Insights data"
  type        = number
  default     = 7
}

# Multi-AZ and Read Replicas
variable "multi_az" {
  description = "Specifies if the RDS instance is multi-AZ"
  type        = bool
  default     = false
}

# SQL Backup Configuration
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

# Lambda Configuration (to match backend module)
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

# Lambda Layer Configuration
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
