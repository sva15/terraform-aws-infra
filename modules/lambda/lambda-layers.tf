# Lambda Layers
resource "aws_lambda_layer_version" "layers" {
  for_each = toset(local.lambda_layer_names)

  layer_name          = "${local.lambda_name_prefix}${each.value}"
  description         = "Lambda layer for ${each.value}"
  compatible_runtimes = [var.lambda_runtime]

  # Conditional source based on use_local_source variable and S3 bucket availability
  filename         = var.use_local_source && local.actual_bucket_name == "" ? "${var.lambda_layers_local_path}/${each.value}.zip" : null
  source_code_hash = var.use_local_source && local.actual_bucket_name == "" ? filebase64sha256("${var.lambda_layers_local_path}/${each.value}.zip") : null

  # S3 source (either from existing bucket or uploaded to created bucket)
  s3_bucket         = local.actual_bucket_name != "" ? local.actual_bucket_name : null
  s3_key            = local.actual_bucket_name != "" ? "lambda-layers/${each.value}.zip" : null
  s3_object_version = var.use_local_source && local.actual_bucket_name != "" ? aws_s3_object.lambda_layers["${each.value}.zip"].version_id : null

  depends_on = [
    aws_s3_object.lambda_layers
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# Create a map of layer names to their ARNs for easy reference
locals {
  layer_arns = {
    for layer_name, layer in aws_lambda_layer_version.layers :
    layer_name => layer.arn
  }
}
