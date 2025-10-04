# ECR Module for container registries
module "ecr" {
  source = "../ecr"

  environment  = var.environment
  project_name = var.project_name
  repositories = var.ecr_repositories
  common_tags  = var.common_tags
}

# S3 Module for UI assets (conditional)
module "s3" {
  source = "../s3"

  environment          = var.environment
  project_name         = var.project_name
  create_ui_bucket     = var.use_local_ui_source
  use_local_ui_source  = var.use_local_ui_source
  ui_assets_local_path = var.ui_assets_local_path
  common_tags          = var.common_tags
}

# EC2 Module for hosting the UI application
module "ec2" {
  source = "../ec2"

  environment        = var.environment
  project_name       = var.project_name
  vpc_id             = var.vpc_id
  subnet_id          = var.public_subnet_id
  security_group_ids = var.security_group_ids
  instance_type      = var.instance_type
  create_key_pair    = var.create_key_pair
  ecr_repository_url = module.ecr.repository_urls["angular-ui"]

  # UI Configuration
  ui_s3_bucket = var.ui_s3_bucket
  ui_s3_key    = var.ui_s3_key
  ui_path      = var.ui_path
  BASE_URL     = var.BASE_URL

  # AMI Configuration
  ami_id           = var.ami_id
  ami_owner        = var.ami_owner
  ami_name_pattern = var.ami_name_pattern

  # Database Configuration
  deploy_database       = var.deploy_database
  postgres_db_name      = var.postgres_db_name
  postgres_user         = var.postgres_user
  postgres_password     = var.postgres_password
  pgadmin_email         = var.pgadmin_email
  pgadmin_password      = var.pgadmin_password
  postgres_port         = var.postgres_port
  pgadmin_port          = var.pgadmin_port
  sql_backup_s3_bucket  = var.sql_backup_s3_bucket
  sql_backup_s3_key     = var.sql_backup_s3_key
  sql_backup_local_path = var.sql_backup_local_path

  common_tags = var.common_tags

  depends_on = [module.ecr]
}

# RDS Module for PostgreSQL database
module "rds" {
  source = "../rds"

  environment        = var.environment
  project_name       = var.project_name
  lambda_prefix      = "insightgen"
  vpc_id             = var.vpc_id
  subnet_ids         = var.private_subnet_ids
  security_group_ids = var.security_group_ids

  # Database Configuration
  db_name             = var.postgres_db_name
  db_username         = var.postgres_user
  db_password         = var.postgres_password
  db_port             = var.postgres_port
  use_secrets_manager = var.use_secrets_manager

  # RDS Instance Configuration
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_encrypted = true

  # Backup Configuration
  backup_retention_period = 7
  skip_final_snapshot     = var.environment != "prod"
  deletion_protection     = var.environment == "prod"

  # SQL Backup Configuration
  sql_backup_s3_bucket  = var.sql_backup_s3_bucket
  sql_backup_s3_key     = var.sql_backup_s3_key
  sql_backup_local_path = var.sql_backup_local_path

  # Lambda Configuration
  lambda_runtime        = var.lambda_runtime
  lambda_timeout        = var.lambda_timeout
  lambda_memory_size    = var.lambda_memory_size
  lambda_layer_mappings = var.lambda_layer_mappings
  lambda_layers         = var.lambda_layers

  common_tags = var.common_tags
}
