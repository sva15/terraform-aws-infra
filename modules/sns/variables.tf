# SNS Module Variables

variable "environment" {
  description = "Environment name (dev, int, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging and naming"
  type        = string
}

variable "lambda_prefix" {
  description = "Prefix for Lambda function names (to match with backend module)"
  type        = string
  default     = "insightgen"
}

variable "topic_names" {
  description = "List of SNS topic names to create"
  type        = list(string)
  default     = []
}

variable "enable_encryption" {
  description = "Enable SNS topic encryption"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for SNS topic encryption (optional)"
  type        = string
  default     = ""
}

variable "delivery_policy" {
  description = "SNS topic delivery policy"
  type        = string
  default     = ""
}

variable "lambda_function_arns" {
  description = "Map of Lambda function names to their ARNs for SNS subscriptions"
  type        = map(string)
  default     = {}
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

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
