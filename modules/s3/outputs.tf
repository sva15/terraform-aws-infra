# S3 Module Outputs - Unified Artifacts Bucket

output "artifacts_bucket_name" {
  description = "Name of the unified artifacts S3 bucket"
  value       = local.actual_bucket_name
}

output "artifacts_bucket_arn" {
  description = "ARN of the unified artifacts S3 bucket"
  value = var.artifacts_bucket_name != "" ? data.aws_s3_bucket.existing_artifacts[0].arn : (
    var.create_artifacts_bucket ? aws_s3_bucket.artifacts[0].arn : null
  )
}

output "artifacts_bucket_domain_name" {
  description = "Domain name of the unified artifacts S3 bucket"
  value = var.artifacts_bucket_name != "" ? data.aws_s3_bucket.existing_artifacts[0].bucket_domain_name : (
    var.create_artifacts_bucket ? aws_s3_bucket.artifacts[0].bucket_domain_name : null
  )
}

output "uploaded_artifacts_summary" {
  description = "Summary of uploaded artifacts"
  value = {
    lambda_functions = length(aws_s3_object.lambda_code)
    lambda_layers    = length(aws_s3_object.lambda_layers)
    sql_backups      = length(aws_s3_object.sql_backups)
    ui_assets        = length(aws_s3_object.ui_assets)
    total_files      = length(aws_s3_object.lambda_code) + length(aws_s3_object.lambda_layers) + length(aws_s3_object.sql_backups) + length(aws_s3_object.ui_assets)
  }
}

output "s3_bucket_paths" {
  description = "S3 bucket folder structure"
  value = {
    lambdas       = "lambdas/"
    lambda_layers = "lambda-layers/"
    database      = "database/"
    ui_assets     = "ui/"
  }
}
