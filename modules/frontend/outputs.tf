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
  }
}

output "ui_application_url" {
  description = "URL to access the UI application"
  value       = "http://${module.ec2.instance_public_ip}"
}
