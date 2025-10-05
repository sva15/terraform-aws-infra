# Global Monitoring Resources
# This module contains CloudWatch and monitoring resources shared across environments

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  common_tags = {
    Module     = "global-monitoring"
    Created_by = "Terraform"
    Purpose    = "Shared Monitoring Resources"
  }
}

# CloudWatch Log Groups for centralized logging
resource "aws_cloudwatch_log_group" "application_logs" {
  for_each = toset(var.log_groups)
  
  name              = "/aws/application/${each.value}"
  retention_in_days = var.log_retention_days

  tags = merge(local.common_tags, {
    Name    = "/aws/application/${each.value}"
    LogType = each.value
  })
}

# SNS topic for critical alerts
resource "aws_sns_topic" "critical_alerts" {
  name = "ifrs-critical-alerts"

  tags = merge(local.common_tags, {
    Name     = "ifrs-critical-alerts"
    Priority = "critical"
  })
}

# CloudWatch dashboard for overall system health
resource "aws_cloudwatch_dashboard" "system_overview" {
  dashboard_name = "IFRS-System-Overview"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", "alb-lambda"],
            [".", "Errors", ".", "."],
            [".", "Invocations", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Lambda Performance"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "ifrs-db"],
            [".", "DatabaseConnections", ".", "."],
            [".", "FreeableMemory", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "RDS Performance"
        }
      }
    ]
  })

  tags = local.common_tags
}

# CloudWatch alarms for system health
resource "aws_cloudwatch_metric_alarm" "high_lambda_errors" {
  alarm_name          = "ifrs-high-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors lambda errors"
  alarm_actions       = [aws_sns_topic.critical_alerts.arn]

  dimensions = {
    FunctionName = "alb-lambda"
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "high_rds_cpu" {
  alarm_name          = "ifrs-high-rds-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors RDS CPU utilization"
  alarm_actions       = [aws_sns_topic.critical_alerts.arn]

  dimensions = {
    DBInstanceIdentifier = "ifrs-db"
  }

  tags = local.common_tags
}
