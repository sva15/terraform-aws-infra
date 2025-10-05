# Backend Module Outputs

output "lambda_functions" {
  description = "Information about created Lambda functions"
  value = {
    for name, func in aws_lambda_function.functions : name => {
      function_name = func.function_name
      arn           = func.arn
      invoke_arn    = func.invoke_arn
      version       = func.version
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

# Debug output for mapping validation
output "mapping_validation" {
  description = "Validation of Lambda and layer mappings to identify potential issues"
  value = {
    # Available functions and layers
    available_functions = local.lambda_function_names
    available_layers    = local.lambda_layer_names
    
    # Configured mappings
    configured_layer_mappings = var.lambda_layer_mappings
    configured_sns_mappings   = var.lambda_sns_subscriptions
    
    # Validation results
    missing_functions = [
      for func_name in keys(var.lambda_layer_mappings) :
      func_name if !contains(local.lambda_function_names, func_name)
    ]
    
    missing_layers = flatten([
      for func_name, layer_list in var.lambda_layer_mappings : [
        for layer_name in layer_list :
        layer_name if !contains(local.lambda_layer_names, layer_name)
      ]
    ])
    
    # Functions without layer mappings
    unmapped_functions = [
      for func_name in local.lambda_function_names :
      func_name if length(lookup(var.lambda_layer_mappings, func_name, [])) == 0
    ]
    
    # Final mappings that will be applied
    final_layer_mappings = local.function_layers
    
    # Summary
    validation_summary = {
      total_functions = length(local.lambda_function_names)
      total_layers    = length(local.lambda_layer_names)
      mapped_functions = length([for f in local.lambda_function_names : f if length(lookup(var.lambda_layer_mappings, f, [])) > 0])
      unmapped_functions = length([for f in local.lambda_function_names : f if length(lookup(var.lambda_layer_mappings, f, [])) == 0])
      missing_function_refs = length([for f in keys(var.lambda_layer_mappings) : f if !contains(local.lambda_function_names, f)])
      missing_layer_refs = length(flatten([for f, layers in var.lambda_layer_mappings : [for l in layers : l if !contains(local.lambda_layer_names, l)]]))
    }
  }
}

output "s3_bucket" {
  description = "S3 bucket information for all artifacts (Lambda code, layers, UI)"
  value = local.actual_bucket_name != "" ? {
    name = local.actual_bucket_name
    arn  = var.artifacts_s3_bucket != "" ? data.aws_s3_bucket.existing_artifacts[0].arn : aws_s3_bucket.artifacts[0].arn
    paths = {
      lambdas       = "lambdas/"
      lambda_layers = "lambda-layers/"
      ui_assets     = "ui/"
      database      = "database/"
    }
  } : null
}

output "iam_role_arn" {
  description = "IAM role ARN for Lambda functions"
  value       = aws_iam_role.lambda_execution_role.arn
}

output "sns_topics" {
  description = "SNS topics information"
  value = {
    topic_arns    = module.sns.topic_arns
    topic_names   = module.sns.topic_names
    subscriptions = module.sns.subscriptions_summary
  }
}
