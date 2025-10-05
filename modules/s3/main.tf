locals {
  # Environment prefix for naming
  env_prefix = var.environment == "prod" ? "" : "${var.environment}-"

  # Unified S3 bucket name (either provided or generated)
  artifacts_bucket_name = var.artifacts_bucket_name != "" ? var.artifacts_bucket_name : "${local.env_prefix}${var.project_name}-artifacts-${random_id.bucket_suffix.hex}"

  # Get all files from different directories
  lambda_zip_files = var.use_local_source && var.lambda_code_local_path != "" ? fileset(var.lambda_code_local_path, "*.zip") : []
  lambda_layer_files = var.use_local_source && var.lambda_layers_local_path != "" ? fileset(var.lambda_layers_local_path, "*.zip") : []
  sql_backup_files = var.use_local_source && var.sql_backup_local_path != "" ? fileset(var.sql_backup_local_path, "*.sql") : []
  
  # UI assets - now as a single zip file
  ui_zip_file = var.use_local_source && fileexists("${var.ui_assets_local_path}/ui-assets.zip") ? ["ui-assets.zip"] : []
}

# Random ID for S3 bucket suffix
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Data source for existing S3 bucket (when artifacts_bucket_name is provided)
data "aws_s3_bucket" "existing_artifacts" {
  count  = var.artifacts_bucket_name != "" ? 1 : 0
  bucket = var.artifacts_bucket_name
}

# Unified S3 bucket for all artifacts
resource "aws_s3_bucket" "artifacts" {
  count  = var.artifacts_bucket_name == "" && var.create_artifacts_bucket ? 1 : 0
  bucket = local.artifacts_bucket_name

  tags = merge(var.common_tags, {
    Name        = local.artifacts_bucket_name
    Description = "Unified bucket for Lambda code, layers, database files, and UI assets"
    Module      = "s3"
  })
}

resource "aws_s3_bucket_versioning" "artifacts" {
  count  = var.artifacts_bucket_name == "" && var.create_artifacts_bucket ? 1 : 0
  bucket = aws_s3_bucket.artifacts[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  count  = var.artifacts_bucket_name == "" && var.create_artifacts_bucket ? 1 : 0
  bucket = aws_s3_bucket.artifacts[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "artifacts" {
  count  = var.artifacts_bucket_name == "" && var.create_artifacts_bucket ? 1 : 0
  bucket = aws_s3_bucket.artifacts[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Determine which bucket to use
locals {
  actual_bucket_name = var.artifacts_bucket_name != "" ? var.artifacts_bucket_name : (var.create_artifacts_bucket ? aws_s3_bucket.artifacts[0].bucket : "")
}

# Upload Lambda function zip files to S3 (organized in lambdas/ folder)
resource "aws_s3_object" "lambda_code" {
  for_each = var.use_local_source && local.actual_bucket_name != "" ? toset(local.lambda_zip_files) : []

  bucket = local.actual_bucket_name
  key    = "lambdas/${each.value}"
  source = "${var.lambda_code_local_path}/${each.value}"
  etag   = filemd5("${var.lambda_code_local_path}/${each.value}")

  tags = merge(var.common_tags, {
    Name   = "lambda-function-${trimsuffix(each.value, ".zip")}"
    Type   = "LambdaFunction"
    Module = "s3"
  })
}

# Upload Lambda layer zip files to S3 (organized in layers/ folder to match existing structure)
resource "aws_s3_object" "lambda_layers" {
  for_each = var.use_local_source && local.actual_bucket_name != "" ? toset(local.lambda_layer_files) : []

  bucket = local.actual_bucket_name
  key    = "layers/${each.value}"  # Changed to match existing structure
  source = "${var.lambda_layers_local_path}/${each.value}"
  etag   = filemd5("${var.lambda_layers_local_path}/${each.value}")

  tags = merge(var.common_tags, {
    Name   = "lambda-layer-${trimsuffix(each.value, ".zip")}"
    Type   = "LambdaLayer"
    Module = "s3"
  })
}

# Upload SQL backup files to S3 (organized in database/ folder)
resource "aws_s3_object" "sql_backups" {
  for_each = var.use_local_source && local.actual_bucket_name != "" ? toset(local.sql_backup_files) : []

  bucket = local.actual_bucket_name
  key    = "database/${each.value}"
  source = "${var.sql_backup_local_path}/${each.value}"
  etag   = filemd5("${var.sql_backup_local_path}/${each.value}")

  tags = merge(var.common_tags, {
    Name   = "sql-backup-${trimsuffix(each.value, ".sql")}"
    Type   = "SQLBackup"
    Module = "s3"
  })
}

# Upload UI assets to S3 (organized in ui-build/ folder to match existing structure)
resource "aws_s3_object" "ui_assets" {
  for_each = var.use_local_source && local.actual_bucket_name != "" ? toset(local.ui_zip_file) : []

  bucket = local.actual_bucket_name
  key    = "ui-build/${each.value}"  # Changed to match existing structure
  source = "${var.ui_assets_local_path}/${each.value}"
  etag   = filemd5("${var.ui_assets_local_path}/${each.value}")

  tags = merge(var.common_tags, {
    Name   = "ui-assets"
    Type   = "UIAssets"
    Module = "s3"
  })
}
