# Development Environment Backend Configuration
terraform {
  backend "s3" {
    bucket       = "terraform-state-ifrs-dev"
    key          = "environments/dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true  # S3 native state locking (replaces DynamoDB)
    
    # Optional: Uncomment for additional security in production
    # kms_key_id = "arn:aws:kms:us-east-1:ACCOUNT-ID:key/KEY-ID"
    # role_arn   = "arn:aws:iam::ACCOUNT-ID:role/TerraformRole"
  }
}
