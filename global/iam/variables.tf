# Global IAM Variables

variable "trusted_account_ids" {
  description = "List of AWS account IDs that can assume the cross-account role"
  type        = list(string)
  default     = []
}

variable "external_id" {
  description = "External ID for cross-account role assumption"
  type        = string
  default     = "terraform-cross-account-access"
  sensitive   = true
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}
