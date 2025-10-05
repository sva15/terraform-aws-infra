# Global Monitoring Variables

variable "log_groups" {
  description = "List of CloudWatch log groups to create"
  type        = list(string)
  default     = ["lambda", "ec2", "rds", "application"]
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}
