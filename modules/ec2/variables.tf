# EC2 Module Variables

variable "environment" {
  description = "Environment name (dev, int, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging and naming"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to deploy EC2 instance"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for EC2 instance (should be public for UI hosting)"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs for EC2 instance"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami_name_pattern" {
  description = "AMI name pattern to search for"
  type        = string
  default     = "ubuntu-*"
}

variable "ami_owner" {
  description = "AMI owner (account ID for shared AMIs)"
  type        = string
  default     = "self"
}

variable "ami_id" {
  description = "Specific AMI ID to use (overrides ami_name_pattern if provided)"
  type        = string
  default     = ""
}

variable "key_pair_name" {
  description = "Name for the EC2 key pair"
  type        = string
  default     = ""
}

variable "create_key_pair" {
  description = "Whether to create a new key pair"
  type        = bool
  default     = true
}

variable "ecr_repository_url" {
  description = "ECR repository URL for the UI application"
  type        = string
}

variable "ui_container_port" {
  description = "Port on which the UI container runs"
  type        = number
  default     = 80
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

variable "postgres_password" {
  description = "PostgreSQL password"
  type        = string
  default     = "ifrs123"
  sensitive   = true
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
