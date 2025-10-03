locals {
  # Environment prefix for naming
  env_prefix = var.environment == "prod" ? "" : "${var.environment}-"

  # Full resource name prefix
  resource_name_prefix = "${local.env_prefix}${var.lambda_prefix}"

  # DB subnet group name
  db_subnet_group_name = "${local.resource_name_prefix}-db-subnet-group"

  # DB instance identifier
  db_instance_identifier = "${local.resource_name_prefix}-postgres"

  # Parameter group name
  db_parameter_group_name = "${local.resource_name_prefix}-postgres-params"
}

# KMS key for RDS encryption (if not provided)
resource "aws_kms_key" "rds_key" {
  count = var.storage_encrypted && var.kms_key_id == "" ? 1 : 0

  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 7

  tags = merge(var.common_tags, {
    Name        = "HCL-User-Role-insightgen-rds-monitoring"
    Description = "Enhanced monitoring role for RDS"
    Module      = "rds"
    Service     = "rds-monitoring"
  })
}

resource "aws_kms_alias" "rds_key_alias" {
  count = var.storage_encrypted && var.kms_key_id == "" ? 1 : 0

  name          = "alias/${local.resource_name_prefix}-rds-key"
  target_key_id = aws_kms_key.rds_key[0].key_id
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = local.db_subnet_group_name
  subnet_ids = var.subnet_ids

  tags = merge(var.common_tags, {
    Name        = local.db_subnet_group_name
    Description = "DB subnet group for ${var.project_name}"
    Module      = "rds"
  })
}

# DB Parameter Group
resource "aws_db_parameter_group" "main" {
  family = "postgres15"
  name   = local.db_parameter_group_name

  # PostgreSQL performance and logging parameters
  parameter {
    name  = "log_statement"
    value = "all"
    apply_immediately = "pending-reboot"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
    apply_immediately = "pending-reboot"
  }

  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
    apply_immediately = "pending-reboot"
  }

  parameter {
    name  = "track_activity_query_size"
    value = "2048"
    apply_immediately = "pending-reboot"
  }

  parameter {
    name  = "log_connections"
    value = "1"
    apply_immediately = "pending-reboot"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
    apply_immediately = "pending-reboot"
  }

  tags = merge(var.common_tags, {
    Name        = local.db_parameter_group_name
    Description = "Parameter group for ${var.project_name} PostgreSQL"
    Module      = "rds"
  })
}

# Enhanced Monitoring Role
resource "aws_iam_role" "rds_enhanced_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  name = "HCL-User-Role-insightgen-rds-monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name    = "HCL-User-Role-insightgen-rds-monitoring"
    Module  = "rds"
    Service = "rds-monitoring"
  })
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  role       = aws_iam_role.rds_enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# RDS Instance with managed password in Secrets Manager
resource "aws_db_instance" "main" {
  identifier = local.db_instance_identifier

  # Engine configuration
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  # Database configuration with managed password
  db_name                     = var.db_name
  username                    = var.db_username
  manage_master_user_password = var.use_secrets_manager
  master_user_secret_kms_key_id = var.use_secrets_manager ? (
    var.kms_key_id != "" ? var.kms_key_id : aws_kms_key.rds_key[0].arn
  ) : null

  # Fallback to traditional password if not using Secrets Manager
  password = var.use_secrets_manager ? null : var.db_password
  port     = var.db_port

  # Storage configuration
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted
  kms_key_id = var.storage_encrypted ? (
    var.kms_key_id != "" ? var.kms_key_id : aws_kms_key.rds_key[0].arn
  ) : null

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = var.security_group_ids
  publicly_accessible    = false

  # Parameter and option groups
  parameter_group_name = aws_db_parameter_group.main.name

  # Backup configuration
  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window

  # Snapshot configuration
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${local.db_instance_identifier}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # Security and maintenance
  multi_az = var.multi_az

  # Monitoring
  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_interval > 0 ? aws_iam_role.rds_enhanced_monitoring[0].arn : null

  # Performance Insights
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
  performance_insights_kms_key_id = var.performance_insights_enabled && var.storage_encrypted ? (
    var.kms_key_id != "" ? var.kms_key_id : aws_kms_key.rds_key[0].arn
  ) : null

  # Enable automated minor version upgrades
  auto_minor_version_upgrade = true

  # Enable deletion protection for production
  deletion_protection = var.environment == "prod" ? true : var.deletion_protection

  tags = merge(var.common_tags, {
    Name        = local.db_instance_identifier
    Description = "PostgreSQL database for ${var.project_name}"
    Module      = "rds"
    Engine      = "postgres"
    Version     = var.engine_version
  })

  depends_on = [
    aws_db_subnet_group.main,
    aws_db_parameter_group.main
  ]
}

# CloudWatch Log Groups for RDS logs
resource "aws_cloudwatch_log_group" "postgresql" {
  name              = "/aws/rds/instance/${local.db_instance_identifier}/postgresql"
  retention_in_days = 7

  tags = merge(var.common_tags, {
    Name   = "${local.db_instance_identifier}-postgresql-logs"
    Module = "rds"
  })
}

# Data source for current AWS region and account
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Lambda function for SQL backup restoration (if backup is provided)
resource "aws_lambda_function" "db_restore" {
  count = (var.sql_backup_s3_bucket != "" && var.sql_backup_s3_key != "") || var.sql_backup_local_path != "" ? 1 : 0

  filename         = data.archive_file.db_restore_zip[0].output_path
  function_name    = "${local.resource_name_prefix}-db-restore"
  role             = aws_iam_role.db_restore_lambda[0].arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.db_restore_zip[0].output_base64sha256
  runtime          = "python3.9"
  timeout          = 300

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.security_group_ids
  }

  environment {
    variables = merge(
      {
        RDS_ENDPOINT        = aws_db_instance.main.endpoint
        RDS_PORT            = tostring(var.db_port)
        DB_NAME             = var.db_name
        DB_USERNAME         = var.db_username
        S3_BUCKET           = var.sql_backup_s3_bucket
        S3_KEY              = var.sql_backup_s3_key
        USE_SECRETS_MANAGER = tostring(var.use_secrets_manager)
        AWS_REGION          = data.aws_region.current.name
      },
      var.use_secrets_manager ? {
        DB_SECRET_NAME = aws_db_instance.main.master_user_secret[0].secret_arn
        } : {
        DB_PASSWORD = var.db_password
      }
    )
  }

  tags = merge(var.common_tags, {
    Name   = "${local.resource_name_prefix}-db-restore"
    Module = "rds"
  })

  depends_on = [aws_db_instance.main]
}

# IAM role for Lambda function
resource "aws_iam_role" "db_restore_lambda" {
  count = (var.sql_backup_s3_bucket != "" && var.sql_backup_s3_key != "") || var.sql_backup_local_path != "" ? 1 : 0

  name = "HCL-User-Role-insightgen-db-restore-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name    = "HCL-User-Role-insightgen-db-restore-lambda"
    Module  = "rds"
    Service = "lambda"
  })
}

# IAM policy for Lambda function
resource "aws_iam_role_policy" "db_restore_lambda" {
  count = (var.sql_backup_s3_bucket != "" && var.sql_backup_s3_key != "") || var.sql_backup_local_path != "" ? 1 : 0

  name = "${local.resource_name_prefix}-db-restore-lambda-policy"
  role = aws_iam_role.db_restore_lambda[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "arn:aws:logs:*:*:*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "secretsmanager:GetSecretValue"
        ],
        "Resource" : [
          "${var.use_secrets_manager ? aws_db_instance.main.master_user_secret[0].secret_arn : "*"}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:AttachNetworkInterface",
          "ec2:DetachNetworkInterface"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = var.sql_backup_s3_bucket != "" ? "arn:aws:s3:::${var.sql_backup_s3_bucket}/*" : "*"
      }
    ]
  })
}

# Attach VPC execution policy to Lambda role
resource "aws_iam_role_policy_attachment" "db_restore_lambda_vpc" {
  count = (var.sql_backup_s3_bucket != "" && var.sql_backup_s3_key != "") || var.sql_backup_local_path != "" ? 1 : 0

  role       = aws_iam_role.db_restore_lambda[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Lambda function code
data "archive_file" "db_restore_zip" {
  count = (var.sql_backup_s3_bucket != "" && var.sql_backup_s3_key != "") || var.sql_backup_local_path != "" ? 1 : 0

  type        = "zip"
  output_path = "${path.module}/db_restore.zip"

  source {
    content = templatefile("${path.module}/db_restore.py", {
      s3_bucket = var.sql_backup_s3_bucket
      s3_key    = var.sql_backup_s3_key
    })
    filename = "index.py"
  }
}

# Invoke Lambda function to restore database
resource "aws_lambda_invocation" "db_restore" {
  count = (var.sql_backup_s3_bucket != "" && var.sql_backup_s3_key != "") || var.sql_backup_local_path != "" ? 1 : 0

  function_name = aws_lambda_function.db_restore[0].function_name

  input = jsonencode({
    action = "restore_database"
  })

  depends_on = [aws_lambda_function.db_restore]
}
