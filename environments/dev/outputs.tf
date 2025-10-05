# Development Environment Outputs

output "environment" {
  description = "Environment name"
  value       = "dev"
}

output "vpc_info" {
  description = "VPC information"
  value = {
    vpc_id     = data.aws_vpc.selected.id
    vpc_name   = var.vpc_name
    subnet_ids = data.aws_subnets.selected.ids
  }
}

output "lambda_info" {
  description = "Lambda module outputs"
  value = {
    lambda_functions = module.lambda.lambda_functions
    lambda_layers    = module.lambda.lambda_layers
    sns_topics       = module.lambda.sns_topics
    s3_bucket        = module.lambda.s3_bucket
  }
}

output "ec2_info" {
  description = "EC2 module outputs (private subnet only)"
  value = {
    instance_id = module.ec2.instance_id
    private_ip  = module.ec2.private_ip
    # Note: No public IP - instance deployed in private subnet for security
  }
}

output "ecr_info" {
  description = "ECR module outputs"
  value = {
    repository_urls = module.ecr.repository_urls
  }
}

output "rds_info" {
  description = "RDS module outputs"
  value = {
    endpoint = module.rds.endpoint
    port     = module.rds.port
  }
}

output "s3_info" {
  description = "S3 module outputs"
  value = {
    bucket_name = module.s3.bucket_name
    bucket_arn  = module.s3.bucket_arn
  }
}

output "quick_access" {
  description = "Quick access information for development"
  value = {
    environment     = "dev"
    project_name    = var.project_name
    aws_region      = var.aws_region
    lambda_functions = keys(module.lambda.lambda_functions)
    sns_topics      = var.sns_topic_names
    s3_bucket       = var.s3_bucket_name
    database_deployed = var.deploy_database
  }
}
