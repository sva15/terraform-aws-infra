# Frontend Module Outputs

output "ecr_repositories" {
  description = "ECR repository information"
  value       = module.ecr.repository_urls
}

output "ui_s3_bucket" {
  description = "UI assets S3 bucket information"
  value = {
    bucket_name = module.s3.ui_bucket_name
    bucket_arn  = module.s3.ui_bucket_arn
  }
}

output "ec2_instance" {
  description = "EC2 instance information"
  value = {
    instance_id       = module.ec2.instance_id
    public_ip        = module.ec2.instance_public_ip
    private_ip       = module.ec2.instance_private_ip
    public_dns       = module.ec2.instance_public_dns
    key_pair_name    = module.ec2.key_pair_name
    ami_used         = module.ec2.ami_used
  }
}

output "ui_application_url" {
  description = "URL to access the UI application (private IP only)"
  value       = "http://${module.ec2.instance_private_ip}"
}

output "database_info" {
  description = "RDS database connection information"
  value       = module.rds.connection_info
  sensitive   = true
}

output "rds_info" {
  description = "Complete RDS instance information"
  value = {
    instance_id       = module.rds.db_instance_id
    endpoint         = module.rds.db_instance_endpoint
    port            = module.rds.db_instance_port
    database_name   = module.rds.db_instance_name
    engine          = module.rds.db_instance_engine
    engine_version  = module.rds.db_instance_engine_version
    instance_class  = module.rds.db_instance_class
    status          = module.rds.db_instance_status
  }
  sensitive = true
}
