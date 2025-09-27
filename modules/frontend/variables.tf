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
  description = "Public subnet ID for EC2 instance"
  type        = string
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

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
