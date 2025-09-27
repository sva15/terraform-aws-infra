locals {
  # Environment prefix for naming
  env_prefix = var.environment == "prod" ? "" : "${var.environment}-"
  
  # S3 bucket name (either provided or generated)
  ui_bucket_name = var.ui_bucket_name != "" ? var.ui_bucket_name : "${local.env_prefix}${var.project_name}-ui-assets-${random_id.bucket_suffix.hex}"
  
  # Get all files from UI assets directory
  ui_files = var.use_local_ui_source && var.create_ui_bucket ? fileset(var.ui_assets_local_path, "**/*") : []
}

# Random ID for S3 bucket suffix
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 bucket for UI assets
resource "aws_s3_bucket" "ui_assets" {
  count  = var.create_ui_bucket ? 1 : 0
  bucket = local.ui_bucket_name
  
  tags = merge(var.common_tags, {
    Name        = local.ui_bucket_name
    Description = "Bucket for UI assets"
    Module      = "s3"
  })
}

resource "aws_s3_bucket_versioning" "ui_assets" {
  count  = var.create_ui_bucket ? 1 : 0
  bucket = aws_s3_bucket.ui_assets[0].id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ui_assets" {
  count  = var.create_ui_bucket ? 1 : 0
  bucket = aws_s3_bucket.ui_assets[0].id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "ui_assets" {
  count  = var.create_ui_bucket ? 1 : 0
  bucket = aws_s3_bucket.ui_assets[0].id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Upload UI assets to S3
resource "aws_s3_object" "ui_files" {
  for_each = var.create_ui_bucket && var.use_local_ui_source ? toset(local.ui_files) : []
  
  bucket = aws_s3_bucket.ui_assets[0].id
  key    = each.value
  source = "${var.ui_assets_local_path}/${each.value}"
  etag   = filemd5("${var.ui_assets_local_path}/${each.value}")
  
  # Set content type based on file extension
  content_type = lookup({
    "html" = "text/html"
    "css"  = "text/css"
    "js"   = "application/javascript"
    "json" = "application/json"
    "png"  = "image/png"
    "jpg"  = "image/jpeg"
    "jpeg" = "image/jpeg"
    "gif"  = "image/gif"
    "svg"  = "image/svg+xml"
    "ico"  = "image/x-icon"
    "woff" = "font/woff"
    "woff2" = "font/woff2"
    "ttf"  = "font/ttf"
    "eot"  = "application/vnd.ms-fontobject"
  }, split(".", each.value)[length(split(".", each.value)) - 1], "application/octet-stream")
  
  tags = merge(var.common_tags, {
    Name   = "ui-asset-${each.value}"
    Type   = "UIAsset"
    Module = "s3"
  })
}
