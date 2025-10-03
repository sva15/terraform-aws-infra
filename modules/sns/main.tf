locals {
  # Environment prefix for naming
  env_prefix = var.environment == "prod" ? "" : "${var.environment}-"

  # Full SNS topic prefix
  topic_name_prefix = "${local.env_prefix}${var.lambda_prefix}-"

  # Create a map of topic names to full topic names
  topic_full_names = {
    for topic in var.topic_names :
    topic => "${local.topic_name_prefix}${topic}"
  }

  # Create subscription mappings
  subscription_pairs = flatten([
    for lambda_name, topics in var.lambda_sns_subscriptions : [
      for topic in topics : {
        lambda_name = lambda_name
        topic_name  = topic
        key         = "${lambda_name}-${topic}"
      }
    ]
  ])

  # Convert to map for for_each
  subscriptions_map = {
    for item in local.subscription_pairs :
    item.key => item
  }
}

# KMS key for SNS encryption (if not provided)
resource "aws_kms_key" "sns_key" {
  count = var.enable_encryption && var.kms_key_id == "" ? 1 : 0

  description             = "KMS key for SNS topic encryption"
  deletion_window_in_days = 7

  tags = merge(var.common_tags, {
    Name        = "${local.topic_name_prefix}sns-key"
    Description = "KMS key for SNS topic encryption"
    Module      = "sns"
  })
}

resource "aws_kms_alias" "sns_key_alias" {
  count = var.enable_encryption && var.kms_key_id == "" ? 1 : 0

  name          = "alias/${local.topic_name_prefix}sns-key"
  target_key_id = aws_kms_key.sns_key[0].key_id
}

# SNS Topics
resource "aws_sns_topic" "topics" {
  for_each = toset(var.topic_names)

  name         = local.topic_full_names[each.value]
  display_name = "${var.project_name} ${title(each.value)} Topic"

  # Encryption configuration
  kms_master_key_id = var.enable_encryption ? (
    var.kms_key_id != "" ? var.kms_key_id : aws_kms_key.sns_key[0].arn
  ) : null

  # Delivery policy
  delivery_policy = var.delivery_policy != "" ? var.delivery_policy : jsonencode({
    "http" = {
      "defaultHealthyRetryPolicy" = {
        "minDelayTarget"     = 20
        "maxDelayTarget"     = 20
        "numRetries"         = 3
        "numMaxDelayRetries" = 0
        "numMinDelayRetries" = 0
        "numNoDelayRetries"  = 0
        "backoffFunction"    = "linear"
      }
      "disableSubscriptionOverrides" = false
      "defaultThrottlePolicy" = {
        "maxReceivesPerSecond" = 1
      }
    }
  })

  tags = merge(var.common_tags, {
    Name        = local.topic_full_names[each.value]
    Description = "SNS topic for ${each.value} events"
    TopicType   = each.value
    Module      = "sns"
  })
}

# SNS Topic Policies (allow Lambda functions to be invoked)
resource "aws_sns_topic_policy" "topic_policies" {
  for_each = aws_sns_topic.topics

  arn = each.value.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowLambdaInvocation"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = [
          "SNS:Publish"
        ]
        Resource = each.value.arn
        Condition = {
          StringEquals = {
            "AWS:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "AllowAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "SNS:Subscribe",
          "SNS:SetTopicAttributes",
          "SNS:RemovePermission",
          "SNS:Receive",
          "SNS:Publish",
          "SNS:ListSubscriptionsByTopic",
          "SNS:GetTopicAttributes",
          "SNS:DeleteTopic",
          "SNS:AddPermission"
        ]
        Resource = each.value.arn
      }
    ]
  })
}

# Lambda function subscriptions to SNS topics
resource "aws_sns_topic_subscription" "lambda_subscriptions" {
  for_each = local.subscriptions_map

  topic_arn = aws_sns_topic.topics[each.value.topic_name].arn
  protocol  = "lambda"
  endpoint  = var.lambda_function_arns[each.value.lambda_name]

  depends_on = [aws_sns_topic.topics]
}

# Lambda permissions to allow SNS to invoke Lambda functions
resource "aws_lambda_permission" "allow_sns" {
  for_each = local.subscriptions_map

  statement_id  = "AllowExecutionFromSNS-${each.value.topic_name}"
  action        = "lambda:InvokeFunction"
  function_name =  var.lambda_function_arns[each.value.lambda_name]
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.topics[each.value.topic_name].arn

  depends_on = [aws_sns_topic_subscription.lambda_subscriptions]

}

# Data source for current AWS account
data "aws_caller_identity" "current" {}
