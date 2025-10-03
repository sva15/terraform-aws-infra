# RDS Module Outputs

output "db_instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.main.id
}

output "db_instance_arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.main.arn
}

output "db_instance_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "db_instance_hosted_zone_id" {
  description = "RDS instance hosted zone ID"
  value       = aws_db_instance.main.hosted_zone_id
}

output "db_instance_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

output "db_instance_name" {
  description = "RDS instance database name"
  value       = aws_db_instance.main.db_name
}

output "db_instance_username" {
  description = "RDS instance master username"
  value       = aws_db_instance.main.username
  sensitive   = true
}

output "db_instance_engine" {
  description = "RDS instance engine"
  value       = aws_db_instance.main.engine
}

output "db_instance_engine_version" {
  description = "RDS instance engine version"
  value       = aws_db_instance.main.engine_version
}

output "db_instance_class" {
  description = "RDS instance class"
  value       = aws_db_instance.main.instance_class
}

output "db_instance_status" {
  description = "RDS instance status"
  value       = aws_db_instance.main.status
}

output "db_subnet_group_id" {
  description = "DB subnet group identifier"
  value       = aws_db_subnet_group.main.id
}

output "db_subnet_group_arn" {
  description = "DB subnet group ARN"
  value       = aws_db_subnet_group.main.arn
}

output "db_parameter_group_id" {
  description = "DB parameter group identifier"
  value       = aws_db_parameter_group.main.id
}

output "db_parameter_group_arn" {
  description = "DB parameter group ARN"
  value       = aws_db_parameter_group.main.arn
}

output "kms_key_id" {
  description = "KMS key ID used for encryption (if created)"
  value       = var.storage_encrypted && var.kms_key_id == "" ? aws_kms_key.rds_key[0].id : var.kms_key_id
}

output "kms_key_arn" {
  description = "KMS key ARN used for encryption (if created)"
  value       = var.storage_encrypted && var.kms_key_id == "" ? aws_kms_key.rds_key[0].arn : null
}

output "monitoring_role_arn" {
  description = "Enhanced monitoring IAM role ARN"
  value       = var.monitoring_interval > 0 ? aws_iam_role.rds_enhanced_monitoring[0].arn : null
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for PostgreSQL logs"
  value = {
    name = aws_cloudwatch_log_group.postgresql.name
    arn  = aws_cloudwatch_log_group.postgresql.arn
  }
}

output "restore_lambda_function" {
  description = "Database restore Lambda function information (if created)"
  value = (var.sql_backup_s3_bucket != "" && var.sql_backup_s3_key != "") || var.sql_backup_local_path != "" ? {
    function_name = aws_lambda_function.db_restore[0].function_name
    function_arn  = aws_lambda_function.db_restore[0].arn
    role_arn      = aws_iam_role.db_restore_lambda[0].arn
  } : null
}

output "connection_info" {
  description = "Database connection information"
  value = {
    endpoint              = aws_db_instance.main.endpoint
    port                  = aws_db_instance.main.port
    database              = aws_db_instance.main.db_name
    username              = aws_db_instance.main.username
    password_secret_arn   = var.use_secrets_manager ? aws_db_instance.main.master_user_secret[0].secret_arn : null
    #password_secret_name  = var.use_secrets_manager ? aws_db_instance.main.master_user_secret[0].secret_name : null
    using_secrets_manager = var.use_secrets_manager
  }
  sensitive = true
}

output "backup_info" {
  description = "Backup configuration information"
  value = {
    backup_retention_period = var.backup_retention_period
    backup_window           = var.backup_window
    maintenance_window      = var.maintenance_window
    multi_az                = var.multi_az
    storage_encrypted       = var.storage_encrypted
  }
}
