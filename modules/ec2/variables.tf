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
  default     = "amzn2-ami-hvm-*-x86_64-gp2"
}

variable "ami_owner" {
  description = "AMI owner"
  type        = string
  default     = "amazon"
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

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
