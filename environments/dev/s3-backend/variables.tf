# Global S3 Backend Variables

variable "create_kms_key" {
  description = "Whether to create a KMS key for production state encryption"
  type        = bool
  default     = false
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}
