# 🔄 Migration Guide: From Monolithic to Best Practice Structure

This guide explains how to migrate from the old monolithic Terraform structure to the new best practice structure.

## 📋 Overview

**Old Structure (Monolithic):**
```
terraform-aws-infra/
├── main.tf                    # All resources in one file
├── variables.tf               # All variables
├── outputs.tf                 # All outputs
├── terraform.tfvars           # Single environment config
├── modules/                   # Modules (good)
├── backend/                   # Application code
├── database/                  # Database files
└── *.md                      # Documentation scattered
```

**New Structure (Best Practice):**
```
terraform-aws-infra/
├── .gitignore
├── README.md
├── docs/                      # Centralized documentation
├── environments/              # Environment-specific configs
│   ├── dev/
│   ├── staging/
│   └── prod/
├── global/                    # Shared global resources
│   ├── iam/
│   ├── networking/
│   ├── monitoring/
│   └── s3-backend/
├── modules/                   # Reusable modules
├── backend/                   # Application code
├── database/                  # Database files
├── scripts/                   # Automation scripts
└── terraform-root/            # Shared configurations
```

## 🎯 Migration Benefits

### **1. Environment Isolation**
- ✅ **Before**: Single state file for all environments
- ✅ **After**: Separate state files per environment
- **Benefit**: Reduced blast radius, safer deployments

### **2. Remote State Management**
- ✅ **Before**: Local state files
- ✅ **After**: S3 backend with DynamoDB locking
- **Benefit**: Team collaboration, state locking, backup

### **3. Global Resource Management**
- ✅ **Before**: Resources mixed with application logic
- ✅ **After**: Dedicated global modules
- **Benefit**: Better organization, reusability

### **4. Automation**
- ✅ **Before**: Manual terraform commands
- ✅ **After**: Automated scripts for common operations
- **Benefit**: Standardized workflows, reduced errors

## 🚀 Migration Steps

### **Phase 1: Backup Current State**

1. **Backup existing state:**
   ```bash
   cp terraform.tfstate terraform.tfstate.backup
   cp terraform.tfvars terraform.tfvars.backup
   ```

2. **Export current resources:**
   ```bash
   terraform show > current-resources.txt
   terraform output > current-outputs.txt
   ```

### **Phase 2: Initialize New Structure**

1. **Setup global S3 backend:**
   ```bash
   cd global/s3-backend
   terraform init
   terraform apply -var="create_kms_key=true"
   ```

2. **Setup global IAM resources:**
   ```bash
   cd ../iam
   terraform init
   terraform apply
   ```

3. **Setup global networking (if needed):**
   ```bash
   cd ../networking
   terraform init
   terraform apply -var="create_prod_vpc=true"
   ```

### **Phase 3: Migrate Environments**

1. **Start with development environment:**
   ```bash
   cd environments/dev
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   terraform init
   ```

2. **Import existing resources (if any):**
   ```bash
   # Example: Import existing Lambda function
   terraform import module.backend.aws_lambda_function.alb_lambda alb-lambda
   ```

3. **Plan and apply:**
   ```bash
   terraform plan
   terraform apply
   ```

4. **Repeat for staging and production:**
   ```bash
   cd ../staging
   # Repeat the process
   cd ../prod
   # Repeat the process
   ```

### **Phase 4: Cleanup Old Structure**

1. **Verify new structure works:**
   ```bash
   # Test each environment
   cd environments/dev && terraform plan
   cd ../staging && terraform plan
   cd ../prod && terraform plan
   ```

2. **Destroy old resources (if migrated):**
   ```bash
   # In old structure
   terraform destroy
   ```

3. **Remove old files:**
   ```bash
   # Move to backup folder
   mkdir old-structure-backup
   mv main.tf variables.tf outputs.tf old-structure-backup/
   ```

## 📁 File Migration Mapping

| **Old Location** | **New Location** | **Notes** |
|------------------|------------------|-----------|
| `main.tf` | `environments/{env}/main.tf` | Split by environment |
| `variables.tf` | `environments/{env}/variables.tf` | Environment-specific |
| `outputs.tf` | `environments/{env}/outputs.tf` | Environment-specific |
| `terraform.tfvars` | `environments/{env}/terraform.tfvars` | One per environment |
| `*.md` (root) | `docs/*.md` | Centralized documentation |
| `modules/` | `modules/` | No change (already good) |
| `backend/` | `backend/` | No change |
| `database/` | `database/` | No change |

## 🔧 Configuration Updates

### **Backend Configuration**
**Old (local state):**
```hcl
# No backend configuration
```

**New (S3 backend):**
```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-ifrs-dev"
    key            = "environments/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks-ifrs-dev"
  }
}
```

### **Provider Configuration**
**Old:**
```hcl
provider "aws" {
  region = var.aws_region
}
```

**New:**
```hcl
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "dev"
      Project     = var.project_name
      Created_by  = "Terraform"
      ManagedBy   = "Terraform"
    }
  }
}
```

### **Module References**
**Old:**
```hcl
module "backend" {
  source = "./modules/backend"
  # ...
}
```

**New:**
```hcl
module "backend" {
  source = "../../modules/backend"
  # ...
}
```

## 🛠️ Using New Automation Scripts

### **Setup Script**
```bash
# Initialize everything
./scripts/setup.sh

# Setup specific environment
./scripts/setup.sh dev
```

### **Validation Script**
```bash
# Validate all configurations
./scripts/validate.sh
```

### **Plan and Apply Script**
```bash
# Plan changes for dev environment
./scripts/plan_apply.sh dev plan

# Apply changes to staging
./scripts/plan_apply.sh staging apply
```

### **Cleanup Script**
```bash
# Clean temporary files
./scripts/cleanup.sh temp-files

# Clean all files
./scripts/cleanup.sh all-files
```

## ⚠️ Migration Considerations

### **State Management**
- **Remote State**: Each environment has its own state file
- **State Locking**: DynamoDB prevents concurrent modifications
- **State Backup**: S3 versioning provides automatic backups

### **Security**
- **Secrets**: Use AWS Secrets Manager instead of hardcoded values
- **IAM Roles**: Follow standardized naming convention
- **Encryption**: KMS encryption for sensitive data

### **Environment Differences**
- **Dev**: Local sources, smaller instances, relaxed security
- **Staging**: S3 sources, production-like setup, testing environment
- **Prod**: S3 sources, larger instances, enhanced security, monitoring

## 🔍 Troubleshooting

### **Common Issues**

1. **State Import Errors**
   ```bash
   # Check resource exists
   aws lambda get-function --function-name alb-lambda
   
   # Import with correct resource address
   terraform import module.backend.aws_lambda_function.alb_lambda alb-lambda
   ```

2. **Backend Initialization Errors**
   ```bash
   # Ensure S3 bucket exists
   aws s3 ls s3://terraform-state-ifrs-dev
   
   # Ensure DynamoDB table exists
   aws dynamodb describe-table --table-name terraform-locks-ifrs-dev
   ```

3. **Module Path Errors**
   ```bash
   # Update module sources to use relative paths
   source = "../../modules/backend"  # Not "./modules/backend"
   ```

### **Validation Commands**
```bash
# Check Terraform syntax
terraform validate

# Check formatting
terraform fmt -check

# Plan without applying
terraform plan

# Show current state
terraform show
```

## 📈 Post-Migration Benefits

### **Operational Benefits**
- ✅ **Environment Isolation**: Safe to test in dev without affecting prod
- ✅ **Parallel Development**: Multiple teams can work on different environments
- ✅ **Automated Workflows**: Standardized scripts reduce manual errors
- ✅ **Better Monitoring**: Centralized monitoring and alerting

### **Security Benefits**
- ✅ **Least Privilege**: Environment-specific IAM roles
- ✅ **Secrets Management**: No hardcoded passwords
- ✅ **Audit Trail**: Detailed logging and monitoring
- ✅ **Compliance**: Standardized security practices

### **Maintenance Benefits**
- ✅ **Easier Updates**: Update one environment at a time
- ✅ **Better Testing**: Test changes in dev/staging first
- ✅ **Rollback Capability**: Environment-specific rollbacks
- ✅ **Documentation**: Centralized and up-to-date

## 🎉 Success Criteria

Migration is successful when:
- ✅ All environments deploy independently
- ✅ Remote state is working correctly
- ✅ Automation scripts function properly
- ✅ All resources are properly tagged
- ✅ Monitoring and alerting are operational
- ✅ Team can collaborate effectively

**🚀 Congratulations! You've successfully migrated to a best practice Terraform structure!**
