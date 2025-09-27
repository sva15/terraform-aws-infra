# Backend Module Outputs

output "lambda_functions" {
  description = "Information about created Lambda functions"
  value = {
    for name, func in aws_lambda_function.functions : name => {
      function_name = func.function_name
      arn          = func.arn
      invoke_arn   = func.invoke_arn
      version      = func.version
    }
  }
}

output "lambda_layers" {
  description = "Information about created Lambda layers"
  value = {
    for name, layer in aws_lambda_layer_version.layers : name => {
      layer_name = layer.layer_name
      arn        = layer.arn
      version    = layer.version
    }
  }
}

output "s3_bucket" {
  description = "S3 bucket information (if created)"
  value = var.create_s3_bucket && var.use_local_source ? {
    bucket_name = aws_s3_bucket.lambda_artifacts[0].id
    bucket_arn  = aws_s3_bucket.lambda_artifacts[0].arn
  } : null
}

output "iam_role_arn" {
  description = "IAM role ARN for Lambda functions"
  value       = aws_iam_role.lambda_execution_role.arn
}
