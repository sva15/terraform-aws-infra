# Lambda Layers
resource "aws_lambda_layer_version" "layers" {
  for_each = toset(local.lambda_layer_names)
  
  layer_name          = "${local.lambda_name_prefix}${each.value}"
  description         = "Lambda layer for ${each.value}"
  compatible_runtimes = [var.lambda_runtime]
  
  # Conditional source based on use_local_source variable
  filename         = var.use_local_source ? "${var.lambda_layers_local_path}/${each.value}.zip" : null
  source_code_hash = var.use_local_source ? filebase64sha256("${var.lambda_layers_local_path}/${each.value}.zip") : null
  
  s3_bucket         = !var.use_local_source ? var.lambda_layers_s3_bucket : (var.create_s3_bucket ? aws_s3_bucket.lambda_artifacts[0].id : null)
  s3_key            = !var.use_local_source ? "${each.value}.zip" : (var.create_s3_bucket ? aws_s3_object.lambda_layers[each.value].key : null)
  s3_object_version = !var.use_local_source ? null : (var.create_s3_bucket ? aws_s3_object.lambda_layers[each.value].version_id : null)
  
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
