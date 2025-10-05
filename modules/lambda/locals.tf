locals {
  # Environment prefix for naming
  env_prefix = var.environment == "prod" ? "" : "${var.environment}-"

  # Full Lambda function prefix
  lambda_name_prefix = "${local.env_prefix}${var.lambda_prefix}-"

  # S3 bucket name (either provided, existing, or generated)
  s3_bucket_name = var.artifacts_s3_bucket != "" ? var.artifacts_s3_bucket : "${local.env_prefix}${var.project_name}-artifacts-${random_id.bucket_suffix.hex}"
  
  # Actual bucket name to use (from existing or created bucket)
  actual_bucket_name = var.artifacts_s3_bucket != "" ? data.aws_s3_bucket.existing_artifacts[0].bucket : (var.create_s3_bucket ? aws_s3_bucket.artifacts[0].bucket : "")

  # Get all Lambda function zip files from local directory
  lambda_zip_files = var.use_local_source ? fileset(var.lambda_code_local_path, "*.zip") : []

  # Extract function names from zip files (remove .zip extension)
  lambda_function_names = [for file in local.lambda_zip_files : trimsuffix(file, ".zip")]

  # Get all Lambda layer zip files from local directory (if path provided)
  lambda_layer_files = var.use_local_source && var.lambda_layers_local_path != "" ? fileset(var.lambda_layers_local_path, "*.zip") : []

  # Extract layer names from local zip files (remove .zip extension)
  local_layer_names = [for file in local.lambda_layer_files : trimsuffix(file, ".zip")]
  
  # Get layer names from mappings (for S3-based layers)
  mapped_layer_names = distinct(flatten([for func, layers in var.lambda_layer_mappings : layers]))
  
  # Combine local and mapped layer names (deduplicated)
  lambda_layer_names = distinct(concat(local.local_layer_names, local.mapped_layer_names))

  # Create map of function names to their layer requirements
  function_layers = {
    for func_name in local.lambda_function_names :
    func_name => lookup(var.lambda_layer_mappings, func_name, [])
  }
}
