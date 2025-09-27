# S3 Module Outputs

output "ui_bucket_name" {
  description = "Name of the UI assets S3 bucket"
  value       = var.create_ui_bucket ? aws_s3_bucket.ui_assets[0].id : null
}

output "ui_bucket_arn" {
  description = "ARN of the UI assets S3 bucket"
  value       = var.create_ui_bucket ? aws_s3_bucket.ui_assets[0].arn : null
}

output "ui_bucket_domain_name" {
  description = "Domain name of the UI assets S3 bucket"
  value       = var.create_ui_bucket ? aws_s3_bucket.ui_assets[0].bucket_domain_name : null
}

output "uploaded_files_count" {
  description = "Number of UI files uploaded to S3"
  value       = length(aws_s3_object.ui_files)
}
