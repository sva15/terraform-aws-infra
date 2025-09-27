# Backend Module Variables

variable "environment" {
  description = "Environment name (dev, int, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging and naming"
  type        = string
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
  default     = "./python-aws-lambda-functions"
}

variable "lambda_layers_local_path" {
  description = "Local path to Lambda layer zip files"
  type        = string
  default     = "./lambda-layers"
}

# S3 bucket configuration
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

# Common tags
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
