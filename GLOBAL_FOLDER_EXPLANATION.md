# 🌍 Global Folder - Shared Infrastructure Components

## 📋 **What is the Global Folder?**

The `global/` folder contains **shared infrastructure components** that are deployed **once per AWS account** and used across **all environments** (dev, staging, prod). These are resources that don't belong to a specific environment but are needed by all environments.

## 🏗️ **Global Folder Structure**

```
global/
├── s3-backend/          # Terraform state management
├── iam/                 # Cross-account IAM roles
├── networking/          # VPC data sources
└── monitoring/          # Centralized logging & monitoring
```

## 🔧 **Components Breakdown**

### **1. 📦 S3 Backend (`global/s3-backend/`)**

#### **Purpose**: Terraform State Management
```hcl
# Creates S3 buckets for storing Terraform state files
resource "aws_s3_bucket" "terraform_state" {
  for_each = toset(["dev", "staging", "prod"])
  bucket   = "terraform-state-ifrs-${each.value}"
}
```

#### **What it creates:**
- ✅ **S3 Buckets**: One per environment for state storage
  - `terraform-state-ifrs-dev`
  - `terraform-state-ifrs-staging`
  - `terraform-state-ifrs-prod`
- ✅ **Encryption**: Server-side encryption enabled
- ✅ **Versioning**: State file versioning enabled
- ✅ **Security**: Public access blocked
- ✅ **KMS Key**: Optional KMS encryption for production

#### **Why Global?**
- **One-time setup**: Deploy once, use by all environments
- **State isolation**: Each environment has its own state bucket
- **No dependencies**: Must exist before any environment deployment

### **2. 🔐 IAM (`global/iam/`)**

#### **Purpose**: Cross-Account IAM Roles
```hcl
# Cross-account role for Terraform operations
resource "aws_iam_role" "terraform_cross_account" {
  name = "HCL-User-Role-insightgen-terraform-cross-account"
}
```

#### **What it creates:**
- ✅ **Cross-Account Role**: For multi-account deployments
- ✅ **Service Roles**: Shared service roles across environments
- ✅ **Policies**: Common IAM policies used by multiple environments
- ✅ **Assume Role Policies**: Trust relationships for cross-account access

#### **Why Global?**
- **Account-level**: IAM roles are account-wide, not environment-specific
- **Shared Access**: Same roles used across dev/staging/prod
- **Security**: Centralized permission management

### **3. 🌐 Networking (`global/networking/`)**

#### **Purpose**: VPC and Network Data Sources
```hcl
# Data source for existing VPC
data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}
```

#### **What it provides:**
- ✅ **VPC Data Sources**: References to existing VPCs
- ✅ **Subnet Data Sources**: References to existing subnets
- ✅ **Security Group Data Sources**: References to existing security groups
- ✅ **Network Information**: Centralized network resource discovery

#### **Why Global?**
- **Shared Network**: Same VPC/subnets used across environments
- **Data Sources Only**: Doesn't create resources, just references existing ones
- **Centralized Discovery**: One place to define network resource lookups

### **4. 📊 Monitoring (`global/monitoring/`)**

#### **Purpose**: Centralized Logging and Monitoring
```hcl
# CloudWatch Log Groups for centralized logging
resource "aws_cloudwatch_log_group" "application_logs" {
  for_each = toset(var.log_groups)
  name     = "/aws/application/${each.value}"
}
```

#### **What it creates:**
- ✅ **CloudWatch Log Groups**: Centralized application logging
- ✅ **CloudWatch Alarms**: Account-wide monitoring alerts
- ✅ **SNS Topics**: Global notification topics
- ✅ **Dashboards**: Cross-environment monitoring dashboards

#### **Why Global?**
- **Centralized Logging**: All environments log to same central location
- **Cross-Environment Monitoring**: Monitor all environments from one place
- **Cost Efficiency**: Shared monitoring resources reduce costs

## 🚀 **Deployment Order**

### **1. Deploy Global Resources First:**
```bash
# 1. Deploy S3 backend (required for state management)
cd global/s3-backend
terraform init
terraform apply

# 2. Deploy IAM roles (if using cross-account access)
cd ../iam
terraform init
terraform apply

# 3. Deploy monitoring (optional, can be done later)
cd ../monitoring
terraform init
terraform apply

# Note: networking/ contains only data sources, no deployment needed
```

### **2. Then Deploy Environments:**
```bash
# After global resources exist, deploy environments
cd ../../environments/dev
terraform init  # Uses S3 backend created in step 1
terraform apply

cd ../staging
terraform init
terraform apply

cd ../prod
terraform init
terraform apply
```

## 📊 **Global vs Environment Resources**

### **🌍 Global Resources (Deploy Once):**
- **S3 State Buckets**: Terraform state storage
- **IAM Roles**: Cross-account access roles
- **CloudWatch Log Groups**: Centralized logging
- **KMS Keys**: Encryption keys for production
- **SNS Topics**: Global notification channels

### **🏢 Environment Resources (Deploy Per Environment):**
- **Lambda Functions**: Application code
- **RDS Databases**: Environment-specific data
- **EC2 Instances**: Environment-specific compute
- **Load Balancers**: Environment-specific traffic routing
- **S3 Buckets**: Environment-specific application data

## 🔧 **Configuration Examples**

### **Global S3 Backend Configuration:**
```hcl
# global/s3-backend/terraform.tfvars
create_kms_key = true  # Enable KMS encryption for production
```

### **Global IAM Configuration:**
```hcl
# global/iam/terraform.tfvars
cross_account_role_name = "HCL-User-Role-insightgen-terraform"
trusted_account_ids     = ["123456789012", "234567890123"]
```

### **Global Monitoring Configuration:**
```hcl
# global/monitoring/terraform.tfvars
log_groups = [
  "ifrs-application",
  "ifrs-lambda",
  "ifrs-database",
  "ifrs-api"
]
log_retention_days = 30
```

## 🎯 **Benefits of Global Folder**

### **🔧 Separation of Concerns:**
- **Global**: Account-wide, shared resources
- **Environment**: Environment-specific resources
- **Modules**: Reusable infrastructure components

### **💰 Cost Efficiency:**
- **Shared Resources**: One monitoring setup for all environments
- **Reduced Duplication**: No duplicate IAM roles or log groups
- **Optimized Storage**: Centralized state and log storage

### **🔒 Security:**
- **Centralized IAM**: Single place to manage cross-account access
- **Consistent Policies**: Same security policies across environments
- **Audit Trail**: Centralized logging for compliance

### **🚀 Scalability:**
- **Add Environments**: New environments automatically use global resources
- **Consistent Setup**: Same global resources for all environments
- **Easy Management**: Update global resources once, affects all environments

## 📋 **When to Use Global vs Environment**

### **✅ Use Global For:**
- **Terraform State Buckets**: Required for state management
- **Cross-Account IAM Roles**: Account-wide permissions
- **Centralized Logging**: Log aggregation across environments
- **Shared KMS Keys**: Encryption keys used by multiple environments
- **Global SNS Topics**: Notifications that span environments

### **✅ Use Environment For:**
- **Application Resources**: Lambda, RDS, EC2, etc.
- **Environment-Specific Config**: Different sizes, settings per environment
- **Data Storage**: Environment-specific S3 buckets, databases
- **Load Balancers**: Environment-specific traffic routing

## 🎉 **Summary**

The `global/` folder is your **foundation layer** that:

### **🏗️ Provides Infrastructure Foundation:**
- **State Management**: S3 buckets for Terraform state
- **Access Control**: IAM roles for cross-account operations
- **Network Discovery**: Data sources for existing VPC/subnets
- **Monitoring**: Centralized logging and alerting

### **🚀 Enables Environment Deployments:**
- **Deploy Once**: Global resources deployed once per AWS account
- **Use Everywhere**: All environments reference global resources
- **Consistent**: Same foundation for dev, staging, and production

### **💡 Best Practices:**
1. **Deploy Global First**: Before any environment deployments
2. **Version Control**: Treat global resources with extra care
3. **Access Control**: Limit who can modify global resources
4. **Documentation**: Keep global resource documentation updated

**🎯 Think of global/ as your AWS account's "operating system" - the foundational layer that everything else builds upon!**
