# Global Networking Variables

variable "vpc_name" {
  description = "Name of the existing VPC to use"
  type        = string
  default     = "default"
}

variable "private_subnet_names" {
  description = "List of existing private subnet names to use"
  type        = list(string)
  default     = ["default-subnet-1", "default-subnet-2"]
}

variable "public_subnet_names" {
  description = "List of existing public subnet names to use"
  type        = list(string)
  default     = ["default-public-subnet-1", "default-public-subnet-2"]
}

variable "security_group_names" {
  description = "List of existing security group names to use"
  type        = list(string)
  default     = ["default"]
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}
