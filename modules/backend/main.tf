# Random ID for S3 bucket suffix
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 bucket for Lambda artifacts (conditional creation)
resource "aws_s3_bucket" "lambda_artifacts" {
  count  = var.create_s3_bucket && var.use_local_source ? 1 : 0
  bucket = local.s3_bucket_name
  
  tags = merge(var.common_tags, {
    Name        = local.s3_bucket_name
    Description = "Bucket for Lambda function code and layers"
    Module      = "backend"
  })
}

resource "aws_s3_bucket_versioning" "lambda_artifacts" {
  count  = var.create_s3_bucket && var.use_local_source ? 1 : 0
  bucket = aws_s3_bucket.lambda_artifacts[0].id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lambda_artifacts" {
  count  = var.create_s3_bucket && var.use_local_source ? 1 : 0
  bucket = aws_s3_bucket.lambda_artifacts[0].id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Upload Lambda function zip files to S3
resource "aws_s3_object" "lambda_code" {
  for_each = var.create_s3_bucket && var.use_local_source ? toset(local.lambda_zip_files) : []
  
  bucket = aws_s3_bucket.lambda_artifacts[0].id
  key    = "lambda-functions/${each.value}"
  source = "${var.lambda_code_local_path}/${each.value}"
  etag   = filemd5("${var.lambda_code_local_path}/${each.value}")
  
  tags = merge(var.common_tags, {
    Name   = "lambda-function-${trimsuffix(each.value, ".zip")}"
    Type   = "LambdaFunction"
    Module = "backend"
  })
}

# Upload Lambda layer zip files to S3
resource "aws_s3_object" "lambda_layers" {
  for_each = var.create_s3_bucket && var.use_local_source ? toset(local.lambda_layer_files) : []
  
  bucket = aws_s3_bucket.lambda_artifacts[0].id
  key    = "lambda-layers/${each.value}"
  source = "${var.lambda_layers_local_path}/${each.value}"
  etag   = filemd5("${var.lambda_layers_local_path}/${each.value}")
  
  tags = merge(var.common_tags, {
    Name   = "lambda-layer-${trimsuffix(each.value, ".zip")}"
    Type   = "LambdaLayer"
    Module = "backend"
  })
}

# SNS Module for topic creation and Lambda subscriptions
module "sns" {
  source = "../sns"
  
  environment               = var.environment
  project_name             = var.project_name
  lambda_prefix            = var.lambda_prefix
  topic_names              = var.sns_topic_names
  enable_encryption        = var.enable_sns_encryption
  lambda_function_arns     = {
    for name, func in aws_lambda_function.functions :
    name => func.arn
  }
  lambda_sns_subscriptions = var.lambda_sns_subscriptions
  common_tags              = var.common_tags
  
  depends_on = [aws_lambda_function.functions]
}
