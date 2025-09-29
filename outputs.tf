# Root Module Outputs

# Backend outputs
output "backend" {
  description = "Backend module outputs"
  value = {
    lambda_functions = module.backend.lambda_functions
    lambda_layers    = module.backend.lambda_layers
    s3_bucket        = module.backend.s3_bucket
    iam_role_arn     = module.backend.iam_role_arn
    sns_topics       = module.backend.sns_topics
  }
}

# Frontend outputs
output "frontend" {
  description = "Frontend module outputs"
  value = {
    ecr_repositories   = module.frontend.ecr_repositories
    ui_s3_bucket       = module.frontend.ui_s3_bucket
    ec2_instance       = module.frontend.ec2_instance
    ui_application_url = module.frontend.ui_application_url
    database_info      = module.frontend.database_info
    rds_info           = module.frontend.rds_info
  }
  sensitive = true
}

# VPC configuration
output "vpc_configuration" {
  description = "VPC configuration used by all resources"
  value = {
    vpc_id             = data.aws_vpc.selected.id
    private_subnet_ids = data.aws_subnets.selected.ids
    public_subnet_ids  = data.aws_subnets.public.ids
    security_group_ids = data.aws_security_groups.selected.ids
  }
}

# Deployment summary
output "deployment_summary" {
  description = "Summary of the complete deployment"
  value = {
    environment       = var.environment
    project_name      = var.project_name
    aws_region        = var.aws_region
    backend_deployed  = length(module.backend.lambda_functions) > 0
    frontend_deployed = module.frontend.ec2_instance.instance_id != null
    ui_url            = module.frontend.ui_application_url
  }
}

# Quick access URLs and connection info
output "quick_access" {
  description = "Quick access information for the deployed application"
  value = {
    ui_application_url = module.frontend.ui_application_url
    ssh_command        = "ssh -i ${module.frontend.ec2_instance.key_pair_name}.pem ubuntu@${module.frontend.ec2_instance.private_ip}"
    ecr_login_command  = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${split("/", values(module.frontend.ecr_repositories)[0])[0]}"
    rds_endpoint       = module.frontend.database_info != null ? module.frontend.database_info.endpoint : null
    database_info      = "RDS PostgreSQL database deployed - check frontend.rds_info for details"
  }
  sensitive = true
}
