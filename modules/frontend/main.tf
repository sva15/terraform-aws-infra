# ECR Module for container registries
module "ecr" {
  source = "../ecr"
  
  environment    = var.environment
  project_name   = var.project_name
  repositories   = var.ecr_repositories
  common_tags    = var.common_tags
}

# S3 Module for UI assets (conditional)
module "s3" {
  source = "../s3"
  
  environment           = var.environment
  project_name          = var.project_name
  create_ui_bucket      = var.use_local_ui_source
  use_local_ui_source   = var.use_local_ui_source
  ui_assets_local_path  = var.ui_assets_local_path
  common_tags           = var.common_tags
}

# EC2 Module for hosting the UI application
module "ec2" {
  source = "../ec2"
  
  environment        = var.environment
  project_name       = var.project_name
  vpc_id            = var.vpc_id
  subnet_id         = var.public_subnet_id
  security_group_ids = var.security_group_ids
  instance_type     = var.instance_type
  create_key_pair   = var.create_key_pair
  ecr_repository_url = module.ecr.repository_urls["angular-ui"]
  common_tags       = var.common_tags
  
  depends_on = [module.ecr]
}
