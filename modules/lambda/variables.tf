# Backend Module Variables

variable "environment" {
  description = "Environment name (dev, int, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging and naming"
  type        = string
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

variable "artifacts_s3_bucket" {
  description = "S3 bucket name for all artifacts (Lambda code, layers, UI). If empty and use_local_source=true, a bucket will be created"
  type        = string
  default     = ""
}

variable "create_s3_bucket" {
  description = "Whether to create S3 bucket for artifacts (only when use_local_source=true and artifacts_s3_bucket is empty)"
  type        = bool
  default     = true
}

# Local paths
variable "lambda_code_local_path" {
  description = "Local path to Lambda function zip files"
  type        = string
  default     = "./python-aws-lambda-functions"
}

variable "lambda_layers_local_path" {
  description = "Local path to Lambda layer zip files"
  type        = string
  default     = "./lambda-layers"
}

# UI Assets configuration (for unified S3 bucket)
variable "ui_assets_local_path" {
  description = "Local path to UI assets zip file"
  type        = string
  default     = "./ui"
}

# VPC Configuration
variable "vpc_id" {
  description = "VPC ID to deploy Lambda functions"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for Lambda functions"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for Lambda functions"
  type        = list(string)
}

# Lambda Configuration
variable "lambda_runtime" {
  description = "Runtime for Lambda functions"
  type        = string
  default     = "python3.9"
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
}

variable "enable_sns_encryption" {
  description = "Enable SNS topic encryption"
  type        = bool
  default     = true
}

# Common tags
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
