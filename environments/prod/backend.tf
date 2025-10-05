# Production Environment Backend Configuration
terraform {
  backend "s3" {
    bucket       = "terraform-state-ifrs-prod"
    key          = "environments/prod/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true  # S3 native state locking (replaces DynamoDB)
    
    # Production-specific security settings
    kms_key_id = "alias/terraform-state-prod"
    # role_arn   = "arn:aws:iam::ACCOUNT-ID:role/TerraformRole"
  }
}
