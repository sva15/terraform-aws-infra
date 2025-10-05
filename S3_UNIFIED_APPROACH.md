# 📦 Unified S3 Bucket Approach - Implementation Guide

## 🎯 **Overview**

The IFRS InsightGen infrastructure now uses a **unified S3 bucket approach** for all artifacts, providing better organization, cost efficiency, and simplified management.

## 🏗️ **Unified S3 Bucket Structure**

### **📁 Organized Folder Structure:**
```
your-artifacts-bucket/
├── lambdas/                    # Lambda function zip files
│   ├── alb-lambda.zip
│   ├── sns-lambda.zip
│   └── db-restore.zip         # RDS restore Lambda
│
├── lambda-layers/              # Lambda layer zip files
│   ├── sns-layer.zip
│   ├── pandas-layer.zip
│   └── requests-layer.zip
│
├── database/                   # SQL backup files
│   ├── initial_schema.sql
│   ├── sample_data.sql
│   └── migration_scripts.sql
│
└── ui/                         # UI assets
    └── ui-assets.zip          # Angular application assets
```

## 🔧 **Configuration Options**

### **Option 1: Auto-Create S3 Bucket (Recommended for Dev)**
```hcl
# terraform.tfvars
artifacts_s3_bucket = ""        # Leave empty to create new bucket
create_s3_bucket    = true      # Auto-create bucket
use_local_source    = true      # Upload from local files
```

**What happens:**
- ✅ Creates new S3 bucket with unique name
- ✅ Uploads all local files to organized folders
- ✅ Lambda functions use S3 sources
- ✅ Provides backup of all artifacts

### **Option 2: Use Existing S3 Bucket**
```hcl
# terraform.tfvars
artifacts_s3_bucket = "my-existing-bucket"  # Your existing bucket
create_s3_bucket    = false                 # Don't create new bucket
use_local_source    = false                 # Use S3 sources only
```

**What happens:**
- ✅ Uses existing S3 bucket via data source
- ✅ Expects artifacts already uploaded to correct paths
- ✅ Lambda functions use S3 sources
- ✅ No local file uploads

### **Option 3: Local Files Only (Testing)**
```hcl
# terraform.tfvars
artifacts_s3_bucket = ""        # No S3 bucket
create_s3_bucket    = false     # Don't create bucket
use_local_source    = true      # Use local files directly
```

**What happens:**
- ✅ Lambda functions use local zip files directly
- ❌ No S3 backup of artifacts
- ⚠️ Limited to smaller deployments

## 📋 **Module Integration**

### **Lambda Module:**
- **Creates/Uses**: Unified S3 bucket for all artifacts
- **Uploads**: Lambda functions, layers, UI assets
- **Organizes**: Files in structured folders
- **Provides**: Bucket information to other modules

### **RDS Module:**
- **Receives**: S3 bucket name from Lambda module
- **Uses**: Same bucket for DB restore Lambda and SQL files
- **Uploads**: 
  - DB restore Lambda to `lambdas/db-restore.zip`
  - SQL backup files to `database/*.sql`
- **Integrates**: With unified bucket structure
- **Environment Variables**: Updated to use unified bucket paths

### **EC2/S3 Modules:**
- **Access**: UI assets from unified bucket
- **Path**: `ui/ui-assets.zip`
- **Integration**: Seamless with other components

## 🚀 **Deployment Scenarios**

### **Development Environment:**
```hcl
# environments/dev/terraform.tfvars
artifacts_s3_bucket      = ""  # Auto-create bucket
create_s3_bucket         = true
use_local_source         = true
lambda_code_local_path   = "../../backend/python-aws-lambda-functions"
lambda_layers_local_path = "../../backend/lambda-layers"
ui_assets_local_path     = "../../ui"
sql_backup_local_path    = "../../database/pg_backup"
```

**Result:**
- Creates: `dev-IFRS-InsightGen-artifacts-{random}`
- Uploads: All local files to organized folders
- Provides: Backup and version control

### **Staging Environment:**
```hcl
# environments/staging/terraform.tfvars
artifacts_s3_bucket      = "staging-ifrs-artifacts"  # Existing bucket
create_s3_bucket         = false
use_local_source         = false
```

**Result:**
- Uses: Existing staging bucket
- Sources: All artifacts from S3
- Assumes: Files already uploaded to correct paths

### **Production Environment:**
```hcl
# environments/prod/terraform.tfvars
artifacts_s3_bucket      = "prod-ifrs-artifacts"  # Existing bucket
create_s3_bucket         = false
use_local_source         = false
```

**Result:**
- Uses: Existing production bucket
- Sources: All artifacts from S3
- Ensures: Production-ready deployment

## 📊 **Benefits**

### **🎯 Organization:**
- **Single Bucket**: All artifacts in one place
- **Clear Structure**: Organized folders for different types
- **Easy Management**: Simple to backup, replicate, version

### **💰 Cost Efficiency:**
- **Reduced Buckets**: One bucket instead of multiple
- **Storage Optimization**: Efficient use of S3 storage
- **Transfer Costs**: Minimized data transfer charges

### **🔒 Security:**
- **Unified Permissions**: Single set of IAM policies
- **Consistent Encryption**: Same encryption across all artifacts
- **Access Control**: Centralized access management

### **🚀 Deployment Flexibility:**
- **Local Development**: Upload from local files
- **CI/CD Integration**: Use existing S3 sources
- **Hybrid Approach**: Mix local and S3 sources

## 🔧 **Implementation Details**

### **S3 Bucket Creation Logic:**
```hcl
# Create bucket only if:
# 1. artifacts_s3_bucket is empty (not provided)
# 2. create_s3_bucket is true
# 3. use_local_source is true (need somewhere to upload)

resource "aws_s3_bucket" "artifacts" {
  count  = var.artifacts_s3_bucket == "" && var.create_s3_bucket ? 1 : 0
  bucket = local.s3_bucket_name
}
```

### **File Upload Logic:**
```hcl
# Upload files only if:
# 1. use_local_source is true (have local files)
# 2. actual_bucket_name is not empty (have bucket to upload to)

resource "aws_s3_object" "lambda_code" {
  for_each = var.use_local_source && local.actual_bucket_name != "" ? toset(local.lambda_zip_files) : []
  
  bucket = local.actual_bucket_name
  key    = "lambdas/${each.value}"
  source = "${var.lambda_code_local_path}/${each.value}"
}
```

### **Lambda Source Logic:**
```hcl
# Lambda function sources:
# 1. If no S3 bucket: use local files directly
# 2. If S3 bucket available: use S3 sources

resource "aws_lambda_function" "functions" {
  # Local source (when no S3 bucket)
  filename         = local.actual_bucket_name == "" ? "${var.lambda_code_local_path}/${each.value}.zip" : null
  
  # S3 source (when bucket available)
  s3_bucket = local.actual_bucket_name != "" ? local.actual_bucket_name : null
  s3_key    = local.actual_bucket_name != "" ? "lambdas/${each.value}.zip" : null
}
```

## 📚 **Usage Examples**

### **Example 1: Development with Auto-Created Bucket**
```bash
cd environments/dev

# Configure for auto-creation
cat > terraform.tfvars << EOF
artifacts_s3_bucket = ""
create_s3_bucket = true
use_local_source = true
EOF

# Deploy
terraform apply
```

### **Example 2: Production with Existing Bucket**
```bash
cd environments/prod

# Configure for existing bucket
cat > terraform.tfvars << EOF
artifacts_s3_bucket = "prod-ifrs-artifacts"
create_s3_bucket = false
use_local_source = false
EOF

# Ensure artifacts are uploaded to bucket first
aws s3 cp backend/python-aws-lambda-functions/ s3://prod-ifrs-artifacts/lambdas/ --recursive
aws s3 cp backend/lambda-layers/ s3://prod-ifrs-artifacts/lambda-layers/ --recursive
aws s3 cp ui/ui-assets.zip s3://prod-ifrs-artifacts/ui/

# Deploy
terraform apply
```

## 🎉 **Summary**

The unified S3 bucket approach provides:

- ✅ **Better Organization**: Structured folders for all artifacts
- ✅ **Cost Efficiency**: Single bucket for all environments
- ✅ **Deployment Flexibility**: Local files or S3 sources
- ✅ **Simplified Management**: One bucket to manage
- ✅ **Consistent Structure**: Same organization across environments
- ✅ **Integration Ready**: Works seamlessly across all modules

**Your IFRS InsightGen infrastructure now has enterprise-grade artifact management! 🚀**
