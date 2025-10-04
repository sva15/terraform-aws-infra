# CloudWatch Log Groups for Lambda functions
resource "aws_cloudwatch_log_group" "lambda_logs" {
  for_each = toset(local.lambda_function_names)

  name              = "/aws/lambda/${local.lambda_name_prefix}${each.value}"
  retention_in_days = 14

  tags = merge(var.common_tags, {
    Name        = "${local.lambda_name_prefix}${each.value}-logs"
    Description = "CloudWatch log group for Lambda function ${each.value}"
    Function    = "${local.lambda_name_prefix}${each.value}"
    Module      = "backend"
  })
}

# Lambda Functions
resource "aws_lambda_function" "functions" {
  for_each = toset(local.lambda_function_names)

  function_name = "${local.lambda_name_prefix}${each.value}"
  description   = "Lambda function for ${each.value}"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = var.lambda_runtime
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory_size

  # Conditional source based on use_local_source variable
  filename         = var.use_local_source ? "${var.lambda_code_local_path}/${each.value}.zip" : null
  source_code_hash = var.use_local_source ? filebase64sha256("${var.lambda_code_local_path}/${each.value}.zip") : null

  s3_bucket         = !var.use_local_source ? var.lambda_code_s3_bucket : (var.create_s3_bucket ? aws_s3_bucket.lambda_artifacts[0].id : null)
  s3_key            = !var.use_local_source ? "${each.value}.zip" : (var.create_s3_bucket ? aws_s3_object.lambda_code["${each.value}.zip"].key : null)
  s3_object_version = !var.use_local_source ? null : (var.create_s3_bucket ? aws_s3_object.lambda_code["${each.value}.zip"].version_id : null)

  # Attach layers based on configuration
  layers = [
    for layer_name in lookup(local.function_layers, each.value, []) :
    local.layer_arns[layer_name]
    if contains(local.lambda_layer_names, layer_name)
  ]

  # VPC Configuration - only if both subnets and security groups are provided
  dynamic "vpc_config" {
    for_each = length(var.subnet_ids) > 0 && length(var.security_group_ids) > 0 ? [1] : []
    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = var.security_group_ids
    }
  }

  # Environment variables
  environment {
    variables = {
      ENVIRONMENT = var.environment
      PROJECT     = var.project_name
      FUNCTION    = each.value
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_execution_policy,
    aws_iam_role_policy_attachment.lambda_vpc_execution_policy,
    aws_cloudwatch_log_group.lambda_logs,
    aws_lambda_layer_version.layers,
    aws_s3_object.lambda_code
  ]

  tags = merge(var.common_tags, {
    Name        = "${local.lambda_name_prefix}${each.value}"
    Description = "Lambda function for ${each.value}"
    Function    = each.value
    Module      = "backend"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Lambda permissions for CloudWatch Logs
resource "aws_lambda_permission" "allow_cloudwatch_logs" {
  for_each = toset(local.lambda_function_names)

  statement_id  = "AllowExecutionFromCloudWatchLogs"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.functions[each.value].function_name
  principal     = "logs.amazonaws.com"
}
