# SNS Module Outputs

output "topic_arns" {
  description = "ARNs of the created SNS topics"
  value = {
    for name, topic in aws_sns_topic.topics :
    name => topic.arn
  }
}

output "topic_names" {
  description = "Names of the created SNS topics"
  value = {
    for name, topic in aws_sns_topic.topics :
    name => topic.name
  }
}

output "topic_ids" {
  description = "IDs of the created SNS topics"
  value = {
    for name, topic in aws_sns_topic.topics :
    name => topic.id
  }
}

output "kms_key_id" {
  description = "KMS key ID used for SNS encryption (if created)"
  value       = var.enable_encryption && var.kms_key_id == "" ? aws_kms_key.sns_key[0].id : var.kms_key_id
}

output "kms_key_arn" {
  description = "KMS key ARN used for SNS encryption (if created)"
  value       = var.enable_encryption && var.kms_key_id == "" ? aws_kms_key.sns_key[0].arn : null
}

output "subscription_arns" {
  description = "ARNs of the Lambda function subscriptions"
  value = {
    for key, subscription in aws_sns_topic_subscription.lambda_subscriptions :
    key => subscription.arn
  }
}

output "subscriptions_summary" {
  description = "Summary of Lambda function subscriptions to SNS topics"
  value = {
    for key, item in local.subscriptions_map :
    key => {
      lambda_function = item.lambda_name
      topic_name      = item.topic_name
      topic_arn       = aws_sns_topic.topics[item.topic_name].arn
    }
  }
}
