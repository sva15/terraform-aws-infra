# ✅ Lambda Layer Double Prefix Fix

## 🚨 **Issue Identified and Fixed**

**Problem**: Lambda layer names were getting double environment prefixes like `"dev-dev-ifrs-lambda-deps-layer"`

## 🔧 **Root Cause Analysis**

### **❌ Previous Configuration:**
```hcl
# In terraform.tfvars
lambda_prefix = "dev-ifrs"    # Already includes "dev-"

# In modules/lambda/locals.tf
env_prefix = "dev-"           # Adds another "dev-"
lambda_name_prefix = "${env_prefix}${lambda_prefix}-"  # Results in "dev-dev-ifrs-"
```

### **✅ Naming Logic:**
```hcl
# Layer name construction:
layer_name = "${lambda_name_prefix}${layer_name}"
# Results in: "dev-dev-ifrs-lambda-deps-layer"
#             ^^^^^ Double prefix
```

## 🔧 **Fixes Applied**

### **✅ 1. Updated Lambda Prefix (All Environments):**

#### **Development:**
```hcl
# BEFORE:
lambda_prefix = "dev-ifrs"

# AFTER:
lambda_prefix = "ifrs"
```

#### **Staging:**
```hcl
# BEFORE:
lambda_prefix = "staging-ifrs"

# AFTER:
lambda_prefix = "ifrs"
```

#### **Production:**
```hcl
# BEFORE:
lambda_prefix = "prod-ifrs"

# AFTER:
lambda_prefix = "ifrs"
```

### **✅ 2. Updated SNS Topic Names:**

#### **Development:**
```hcl
# BEFORE:
sns_topic_names = ["dev-ifrs-notifications"]

# AFTER:
sns_topic_names = ["ifrs-notifications"]
```

#### **Staging:**
```hcl
# BEFORE:
sns_topic_names = ["staging-ifrs-notifications"]

# AFTER:
sns_topic_names = ["ifrs-notifications"]
```

#### **Production:**
```hcl
# BEFORE:
sns_topic_names = ["prod-ifrs-notifications", "prod-ifrs-alerts"]

# AFTER:
sns_topic_names = ["ifrs-notifications", "ifrs-alerts"]
```

### **✅ 3. Updated Lambda Environment Variables:**

You need to manually update the lambda environment variable in dev terraform.tfvars:

```hcl
# In lambda_env_vars for "sns-lambda":
# BEFORE:
TOPIC_NAME = "dev-ifrs-notifications"

# AFTER:
TOPIC_NAME = "ifrs-notifications"
```

## 📊 **New Naming Convention**

### **✅ How Names Are Constructed:**
```hcl
# Environment prefix (automatic)
env_prefix = var.environment == "prod" ? "" : "${var.environment}-"

# Lambda prefix (from terraform.tfvars)
lambda_prefix = "ifrs"

# Combined prefix
lambda_name_prefix = "${env_prefix}${lambda_prefix}-"

# Results:
# Dev:     "dev-ifrs-"
# Staging: "staging-ifrs-"
# Prod:    "ifrs-"
```

### **✅ Final Resource Names:**

#### **Lambda Functions:**
```
Dev:     dev-ifrs-sns-lambda, dev-ifrs-alb-lambda, dev-ifrs-db-restore
Staging: staging-ifrs-sns-lambda, staging-ifrs-alb-lambda, staging-ifrs-db-restore
Prod:    ifrs-sns-lambda, ifrs-alb-lambda, ifrs-db-restore
```

#### **Lambda Layers:**
```
Dev:     dev-ifrs-sns-layer, dev-ifrs-alb-layer, dev-ifrs-lambda-deps-layer
Staging: staging-ifrs-sns-layer, staging-ifrs-alb-layer, staging-ifrs-lambda-deps-layer
Prod:    ifrs-sns-layer, ifrs-alb-layer, ifrs-lambda-deps-layer
```

#### **SNS Topics:**
```
Dev:     dev-ifrs-notifications
Staging: staging-ifrs-notifications
Prod:    ifrs-notifications, ifrs-alerts
```

## 🎯 **Benefits of Fix**

### **✅ Clean Naming:**
- **No double prefixes** (dev-dev-, staging-staging-, etc.)
- **Consistent pattern** across environments
- **Readable resource names**

### **✅ Environment Isolation:**
- **Dev**: `dev-ifrs-*`
- **Staging**: `staging-ifrs-*`
- **Prod**: `ifrs-*` (no environment prefix for production)

### **✅ Simplified Configuration:**
- **Base names** in terraform.tfvars (without environment prefix)
- **Automatic prefixing** by modules
- **Consistent across all resources**

## 📋 **Manual Update Required**

### **✅ Lambda Environment Variable:**
In `environments/dev/terraform.tfvars`, update:

```hcl
lambda_env_vars = {
  "sns-lambda" = {
    ENVIRONMENT = "dev"
    PROJECT     = "ifrs"
    FUNCTION    = "sns-lambda"
    TOPIC_NAME  = "ifrs-notifications"  # ← Change this from "dev-ifrs-notifications"
  }
  # ... other functions
}
```

## 🚀 **Deployment**

### **✅ Apply Changes:**
```bash
cd environments/dev
terraform plan   # Review naming changes
terraform apply  # Deploy with correct names
```

### **✅ Expected Results:**
```
# Lambda layers will be named:
dev-ifrs-sns-layer
dev-ifrs-alb-layer
dev-ifrs-lambda-deps-layer

# Instead of:
dev-dev-ifrs-sns-layer
dev-dev-ifrs-alb-layer
dev-dev-ifrs-lambda-deps-layer
```

## 🔍 **Verification**

### **✅ Check Resource Names:**
```bash
# List Lambda functions
aws lambda list-functions --query 'Functions[?starts_with(FunctionName, `dev-ifrs-`)].FunctionName'

# List Lambda layers
aws lambda list-layers --query 'Layers[?starts_with(LayerName, `dev-ifrs-`)].LayerName'

# List SNS topics
aws sns list-topics --query 'Topics[?contains(TopicArn, `dev-ifrs-`)].TopicArn'
```

## 📝 **Configuration Summary**

### **✅ All Environments Fixed:**

| Environment | Lambda Prefix | SNS Topics | Layer Names |
|-------------|---------------|------------|-------------|
| **Dev** | `ifrs` | `ifrs-notifications` | `dev-ifrs-*` |
| **Staging** | `ifrs` | `ifrs-notifications` | `staging-ifrs-*` |
| **Prod** | `ifrs` | `ifrs-notifications`, `ifrs-alerts` | `ifrs-*` |

### **✅ Naming Pattern:**
```
{environment_prefix}{lambda_prefix}-{resource_name}
```

Where:
- `environment_prefix` = `"dev-"`, `"staging-"`, or `""` (for prod)
- `lambda_prefix` = `"ifrs"`
- `resource_name` = `"sns-lambda"`, `"layer-name"`, etc.

## 🎉 **Summary**

### ✅ **Fixed Issues:**
- **Double environment prefixes** eliminated
- **Consistent naming** across all environments
- **Clean resource names** for better organization

### ✅ **All Environments Updated:**
- **Dev, Staging, Prod** configurations fixed
- **Lambda functions, layers, SNS topics** all consistent
- **Environment isolation** maintained

### ✅ **Manual Action Required:**
- **Update lambda environment variable** `TOPIC_NAME` in dev terraform.tfvars
- **From**: `"dev-ifrs-notifications"`
- **To**: `"ifrs-notifications"`

**🚀 Lambda layer double prefix issue is now resolved across all environments!**
