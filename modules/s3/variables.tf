# S3 Module Variables

variable "environment" {
  description = "Environment name (dev, int, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging and naming"
  type        = string
}

variable "create_ui_bucket" {
  description = "Whether to create S3 bucket for UI assets"
  type        = bool
  default     = true
}

variable "ui_bucket_name" {
  description = "Name of S3 bucket for UI assets (if not provided, will be auto-generated)"
  type        = string
  default     = ""
}

variable "use_local_ui_source" {
  description = "Whether to upload UI assets from local directory"
  type        = bool
  default     = true
}

variable "ui_assets_local_path" {
  description = "Local path to UI assets directory"
  type        = string
  default     = "./ui/dist"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
