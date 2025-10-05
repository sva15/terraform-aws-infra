# 🔄 Mixed Layer Configuration - Local + S3 Layers

## ✅ **Updated Configuration for Mixed Layer Sources**

Your configuration now supports **mixed layer sources**:
- **Lambda Code**: Local path (all functions)
- **Lambda Layers**: Mixed (S3 + Local)
  - `sns-layer`, `alb-layer` → S3 (existing)
  - `lambda-deps-layer` → Local (for db-restore)
- **Database SQL**: S3 path (existing)

## 🔧 **Current Configuration**

### **✅ Updated terraform.tfvars:**
```hcl
# Lambda Configuration (HYBRID: Local code + Mixed layers)
lambda_prefix            = "dev-ifrs"
use_local_source         = true
artifacts_s3_bucket      = "filterrithas"
create_s3_bucket         = false
lambda_code_local_path   = "../../backend/python-aws-lambda-functions"  # Local Lambda code
lambda_layers_local_path = "../../backend/lambda-layers"               # Local layers path
ui_assets_local_path     = "../../ui"

# Lambda Layer Mappings (mixed: S3 layers + local layer for db-restore)
lambda_layer_mappings = {
  "sns-lambda" = ["sns-layer"]          # Use existing layer from S3
  "alb-lambda" = ["alb-layer"]          # Use existing layer from S3  
  "db-restore" = ["lambda-deps-layer"]  # Use local layer for db-restore function
}

# SQL Backup Configuration (S3 path - existing files)
sql_backup_s3_bucket = "filterrithas"
sql_backup_s3_key    = "postgres/ifrs_backup_20250928_144411.sql"
sql_backup_local_path = ""
```

## 📊 **Layer Source Matrix**

### **🔄 Layer Sources:**
```
Function        Layer Name           Source    Location
├── sns-lambda → sns-layer        → S3     → s3://filterrithas/layers/sns-layer.zip
├── alb-lambda → alb-layer        → S3     → s3://filterrithas/layers/alb-layer.zip
└── db-restore → lambda-deps-layer → Local → ../../backend/lambda-layers/lambda-deps-layer.zip
```

### **📁 File Structure Required:**

#### **✅ Local Files (must exist):**
```
backend/
├── python-aws-lambda-functions/
│   ├── sns-lambda.zip          # ← Local Lambda function
│   ├── alb-lambda.zip          # ← Local Lambda function
│   └── db-restore.zip          # ← Local Lambda function (if exists, or auto-generated)
└── lambda-layers/
    └── lambda-deps-layer.zip   # ← Local layer for db-restore

ui/
└── ui-assets.zip               # ← Local UI assets
```

#### **✅ S3 Files (must exist in S3):**
```
s3://filterrithas/
├── layers/
│   ├── sns-layer.zip           # ← Existing S3 layer for sns-lambda
│   └── alb-layer.zip           # ← Existing S3 layer for alb-lambda
└── postgres/
    └── ifrs_backup_20250928_144411.sql  # ← Existing SQL backup
```

## 🚀 **Deployment Flow**

### **1. ✅ Local → S3 Upload:**
```bash
# Terraform will upload these local files:
Local Files                                    →  S3 Destination
├── backend/python-aws-lambda-functions/
│   ├── sns-lambda.zip                        →  s3://filterrithas/lambdas/sns-lambda.zip
│   ├── alb-lambda.zip                        →  s3://filterrithas/lambdas/alb-lambda.zip
│   └── db-restore.zip                        →  s3://filterrithas/lambdas/db-restore.zip
├── backend/lambda-layers/
│   └── lambda-deps-layer.zip                 →  s3://filterrithas/layers/lambda-deps-layer.zip
└── ui/ui-assets.zip                          →  s3://filterrithas/ui-build/ui-assets.zip
```

### **2. ✅ Layer Attachment Logic:**
```bash
# Lambda functions will get layers from mixed sources:
Lambda Function    →  Layer Source
├── sns-lambda     →  S3: s3://filterrithas/layers/sns-layer.zip (existing)
├── alb-lambda     →  S3: s3://filterrithas/layers/alb-layer.zip (existing)
└── db-restore     →  S3: s3://filterrithas/layers/lambda-deps-layer.zip (uploaded)
```

## 🔧 **Module Logic**

### **✅ Smart Layer Detection:**
```hcl
# Lambda module will handle:
locals {
  # Local layers (from local directory)
  local_layer_names = ["lambda-deps-layer"]  # Found in ../../backend/lambda-layers/
  
  # Mapped layers (from terraform.tfvars)
  mapped_layer_names = ["sns-layer", "alb-layer", "lambda-deps-layer"]
  
  # Combined (all layers to create)
  lambda_layer_names = ["sns-layer", "alb-layer", "lambda-deps-layer"]
}

# Layer creation:
resource "aws_lambda_layer_version" "layers" {
  for_each = toset(["sns-layer", "alb-layer", "lambda-deps-layer"])
  
  # Source logic:
  # - lambda-deps-layer: Use local file (uploaded to S3)
  # - sns-layer, alb-layer: Reference existing S3 files
}
```

## 📋 **Benefits of Mixed Approach**

### **✅ Flexibility:**
- **Reuse existing** S3 layers (sns-layer, alb-layer)
- **Add new layers** locally (lambda-deps-layer)
- **No duplication** of existing S3 resources

### **✅ Development Workflow:**
- **Stable layers** stay in S3 (no re-upload needed)
- **New layers** developed locally and uploaded
- **Function code** always from local (easy iteration)

### **✅ Resource Efficiency:**
- **Minimal uploads** (only new/changed files)
- **Existing S3 layers** referenced directly
- **No unnecessary** layer recreation

## ⚠️ **Important Notes**

### **📋 File Verification:**
Before deployment, ensure these files exist:

#### **✅ Local Files:**
```bash
# Check local files exist:
ls backend/python-aws-lambda-functions/
# Should show: sns-lambda.zip, alb-lambda.zip, (db-restore.zip if not auto-generated)

ls backend/lambda-layers/
# Should show: lambda-deps-layer.zip

ls ui/
# Should show: ui-assets.zip
```

#### **✅ S3 Files:**
```bash
# Check S3 files exist:
aws s3 ls s3://filterrithas/layers/
# Should show: sns-layer.zip, alb-layer.zip

aws s3 ls s3://filterrithas/postgres/
# Should show: ifrs_backup_20250928_144411.sql
```

### **🔧 Layer Naming:**
- **S3 layers**: `sns-layer`, `alb-layer` (must match S3 file names)
- **Local layer**: `lambda-deps-layer` (must match local file name)
- **Function mapping**: Connects functions to their required layers

## 🎯 **Deployment Verification**

### **1. ✅ Plan Check:**
```bash
cd environments/dev
terraform plan
# Should show:
# - Upload lambda-deps-layer.zip to S3
# - Create layer from uploaded file
# - Reference existing S3 layers for other functions
```

### **2. ✅ Apply and Verify:**
```bash
terraform apply
# Check layer creation:
terraform output mapping_validation
# Should show all layers properly mapped
```

### **3. ✅ S3 Verification:**
```bash
# After deployment, check S3 structure:
aws s3 ls s3://filterrithas/layers/
# Should show:
# - sns-layer.zip (existing)
# - alb-layer.zip (existing)  
# - lambda-deps-layer.zip (newly uploaded)
```

## 🎉 **Summary**

Your configuration now supports **mixed layer sources**:

### ✅ **Layer Sources:**
- **sns-lambda** → `sns-layer` (S3, existing)
- **alb-lambda** → `alb-layer` (S3, existing)
- **db-restore** → `lambda-deps-layer` (Local, uploaded)

### ✅ **File Sources:**
- **Lambda Functions**: All local (uploaded)
- **Lambda Layers**: Mixed (S3 existing + Local uploaded)
- **SQL Backups**: S3 existing
- **UI Assets**: Local (uploaded)

### ✅ **Benefits:**
- **Efficient**: Reuses existing S3 layers
- **Flexible**: Supports new local layers
- **Clean**: No duplicate uploads

**🚀 Ready to deploy with mixed layer configuration!**
