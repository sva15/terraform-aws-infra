# S3 Backend Outputs

output "s3_bucket_names" {
  description = "Names of the Terraform state S3 buckets"
  value = {
    for env, bucket in aws_s3_bucket.terraform_state : env => bucket.id
  }
}

output "s3_bucket_arns" {
  description = "ARNs of the Terraform state S3 buckets"
  value = {
    for env, bucket in aws_s3_bucket.terraform_state : env => bucket.arn
  }
}

output "backend_configurations" {
  description = "Backend configurations for each environment (use these in your backend.tf files)"
  value = {
    for env in local.environments : env => {
      bucket         = aws_s3_bucket.terraform_state[env].id
      key           = "terraform.tfstate"
      region        = data.aws_region.current.name
      encrypt       = true
      use_lockfile  = true
      
      # Example backend configuration
      example_backend_config = <<-EOT
        terraform {
          backend "s3" {
            bucket         = "${aws_s3_bucket.terraform_state[env].id}"
            key           = "terraform.tfstate"
            region        = "${data.aws_region.current.name}"
            encrypt       = true
            use_lockfile  = true
          }
        }
      EOT
    }
  }
}

output "kms_key_arn" {
  description = "ARN of the KMS key for production state encryption (if created)"
  value       = var.create_kms_key ? aws_kms_key.terraform_state_prod[0].arn : null
}

output "kms_key_alias" {
  description = "Alias of the KMS key for production state encryption (if created)"
  value       = var.create_kms_key ? aws_kms_alias.terraform_state_prod[0].name : null
}

# Data source for current region
data "aws_region" "current" {}
