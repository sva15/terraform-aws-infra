# S3 Module Variables - Unified Artifacts Bucket

variable "environment" {
  description = "Environment name (dev, int, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging and naming"
  type        = string
}

# Unified S3 Bucket Configuration
variable "create_artifacts_bucket" {
  description = "Whether to create unified S3 bucket for all artifacts"
  type        = bool
  default     = true
}

variable "artifacts_bucket_name" {
  description = "Name of existing S3 bucket for all artifacts (if empty, will create new bucket)"
  type        = string
  default     = ""
}

variable "use_local_source" {
  description = "Whether to upload artifacts from local directories"
  type        = bool
  default     = true
}

# Local paths for all artifact types
variable "lambda_code_local_path" {
  description = "Local path to Lambda function zip files"
  type        = string
  default     = "../../backend/python-aws-lambda-functions"
}

variable "lambda_layers_local_path" {
  description = "Local path to Lambda layer zip files"
  type        = string
  default     = "../../backend/lambda-layers"
}

variable "sql_backup_local_path" {
  description = "Local path to SQL backup files"
  type        = string
  default     = "../../database/pg_backup"
}

variable "ui_assets_local_path" {
  description = "Local path to UI assets (expecting ui-assets.zip)"
  type        = string
  default     = "../../ui"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
