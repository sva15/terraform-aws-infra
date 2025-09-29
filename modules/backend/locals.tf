locals {
  # Environment prefix for naming
  env_prefix = var.environment == "prod" ? "" : "${var.environment}-"

  # Full Lambda function prefix
  lambda_name_prefix = "${local.env_prefix}${var.lambda_prefix}-"

  # S3 bucket name (either provided or generated)
  s3_bucket_name = var.s3_bucket_name != "" ? var.s3_bucket_name : "${local.env_prefix}${var.project_name}-lambda-artifacts-${random_id.bucket_suffix.hex}"

  # Get all Lambda function zip files from local directory
  lambda_zip_files = var.use_local_source ? fileset(var.lambda_code_local_path, "*.zip") : []

  # Extract function names from zip files (remove .zip extension)
  lambda_function_names = [for file in local.lambda_zip_files : trimsuffix(file, ".zip")]

  # Get all Lambda layer zip files from local directory
  lambda_layer_files = var.use_local_source ? fileset(var.lambda_layers_local_path, "*.zip") : []

  # Extract layer names from zip files (remove .zip extension)
  lambda_layer_names = [for file in local.lambda_layer_files : trimsuffix(file, ".zip")]

  # Create map of function names to their layer requirements
  function_layers = {
    for func_name in local.lambda_function_names :
    func_name => lookup(var.lambda_layer_mappings, func_name, [])
  }
}
