# Random ID for S3 bucket suffix
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Data source for existing S3 bucket (when artifacts_s3_bucket is provided)
data "aws_s3_bucket" "existing_artifacts" {
  count  = var.artifacts_s3_bucket != "" ? 1 : 0
  bucket = var.artifacts_s3_bucket
}

# S3 bucket for all artifacts (conditional creation)
resource "aws_s3_bucket" "artifacts" {
  count  = var.artifacts_s3_bucket == "" && var.create_s3_bucket ? 1 : 0
  bucket = local.s3_bucket_name

  tags = merge(var.common_tags, {
    Name        = local.s3_bucket_name
    Description = "Unified bucket for Lambda code, layers, and UI assets"
    Module      = "lambda"
  })
}

resource "aws_s3_bucket_versioning" "artifacts" {
  count  = var.artifacts_s3_bucket == "" && var.create_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.artifacts[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  count  = var.artifacts_s3_bucket == "" && var.create_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.artifacts[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
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
    Module = "lambda"
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
    Module = "lambda"
  })
}

# Upload UI assets to S3 (organized in ui/ folder)
resource "aws_s3_object" "ui_assets" {
  count = var.use_local_source && local.actual_bucket_name != "" && fileexists("${var.ui_assets_local_path}/ui-assets.zip") ? 1 : 0

  bucket = local.actual_bucket_name
  key    = "ui/ui-assets.zip"
  source = "${var.ui_assets_local_path}/ui-assets.zip"
  etag   = filemd5("${var.ui_assets_local_path}/ui-assets.zip")

  tags = merge(var.common_tags, {
    Name   = "ui-assets"
    Type   = "UIAssets"
    Module = "lambda"
  })
}

# SNS Module for topic creation and Lambda subscriptions
module "sns" {
  source = "../sns"

  environment       = var.environment
  project_name      = var.project_name
  lambda_prefix     = var.lambda_prefix
  topic_names       = var.sns_topic_names
  enable_encryption = var.enable_sns_encryption
  lambda_function_arns = {
    for name, func in aws_lambda_function.functions :
    name => func.arn
  }
  lambda_sns_subscriptions = var.lambda_sns_subscriptions
  common_tags              = var.common_tags

  depends_on = [aws_lambda_function.functions]
}
