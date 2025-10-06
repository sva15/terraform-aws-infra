# ✅ Dynamic Lambda Environment Variables Configuration

## 🎯 **Dynamic Environment Variables Setup**

Your lambda deployment now uses **dynamic environment variables** that can be configured per environment and per function.

## 🔧 **Configuration Structure**

### **✅ Environment Variable Definition:**
```hcl
# In terraform.tfvars
lambda_env_vars = {
  "function-name" = {
    ENV_VAR_1 = "value1"
    ENV_VAR_2 = "value2"
    # ... more variables
  }
}
```

### **✅ Current Dev Environment Configuration:**
```hcl
# environments/dev/terraform.tfvars
lambda_env_vars = {
  "sns-lambda" = {
    ENVIRONMENT = "dev"
    PROJECT     = "ifrs"
    FUNCTION    = "sns-lambda"
    TOPIC_NAME  = "dev-ifrs-notifications"
  }

  "alb-lambda" = {
    ENVIRONMENT = "dev"
    PROJECT     = "ifrs"
    FUNCTION    = "alb-lambda"
    ALB_NAME    = "ifrs-alb"
  }

  "db-restore" = {
    ENVIRONMENT = "dev"
    PROJECT     = "ifrs"
    FUNCTION    = "db-restore"
    DB_NAME     = "ifrs-db"
    DB_USER     = "admin"
  }
}
```

## 📊 **How It Works**

### **✅ Lambda Module Logic:**
```hcl
# In modules/lambda/lambda-functions.tf
resource "aws_lambda_function" "functions" {
  for_each = toset(local.lambda_function_names)
  
  # ... other configuration ...
  
  environment {
    variables = lookup(var.lambda_env_vars, each.value, {})
  }
}
```

### **✅ Variable Definition:**
```hcl
# In modules/lambda/variables.tf
variable "lambda_env_vars" {
  description = "Environment variables per Lambda function"
  type        = map(map(string))
  default     = {}
}
```

### **✅ Module Call:**
```hcl
# In environments/{env}/main.tf
module "lambda" {
  source = "../../modules/lambda"
  
  # ... other parameters ...
  lambda_env_vars = var.lambda_env_vars
  # ... other parameters ...
}
```

## 🌍 **Environment-Specific Configuration**

### **✅ Development Environment:**
```hcl
# environments/dev/terraform.tfvars
lambda_env_vars = {
  "sns-lambda" = {
    ENVIRONMENT = "dev"
    PROJECT     = "ifrs"
    LOG_LEVEL   = "DEBUG"
    API_URL     = "https://dev-api.example.com"
  }
}
```

### **✅ Staging Environment:**
```hcl
# environments/staging/terraform.tfvars (example)
lambda_env_vars = {
  "sns-lambda" = {
    ENVIRONMENT = "staging"
    PROJECT     = "ifrs"
    LOG_LEVEL   = "INFO"
    API_URL     = "https://staging-api.example.com"
  }
}
```

### **✅ Production Environment:**
```hcl
# environments/prod/terraform.tfvars (example)
lambda_env_vars = {
  "sns-lambda" = {
    ENVIRONMENT = "prod"
    PROJECT     = "ifrs"
    LOG_LEVEL   = "WARN"
    API_URL     = "https://api.example.com"
  }
}
```

## 🔧 **Updated Files**

### **✅ Files Modified:**
1. **environments/dev/main.tf** → Added `lambda_env_vars = var.lambda_env_vars`
2. **environments/staging/main.tf** → Added `lambda_env_vars = var.lambda_env_vars`
3. **environments/prod/main.tf** → Added `lambda_env_vars = var.lambda_env_vars`
4. **environments/staging/variables.tf** → Added `lambda_env_vars` variable
5. **environments/prod/variables.tf** → Added `lambda_env_vars` variable

### **✅ Files Already Configured:**
1. **modules/lambda/variables.tf** → `lambda_env_vars` variable defined
2. **modules/lambda/lambda-functions.tf** → Dynamic env vars logic implemented
3. **environments/dev/variables.tf** → `lambda_env_vars` variable defined
4. **environments/dev/terraform.tfvars** → Environment variables configured

## 🎯 **Benefits**

### **✅ Dynamic Configuration:**
- **Per-function** environment variables
- **Per-environment** customization
- **Easy maintenance** and updates

### **✅ Environment Isolation:**
- **Different values** per environment (dev/staging/prod)
- **Environment-specific** API URLs, log levels, etc.
- **Secure configuration** management

### **✅ Function-Specific Variables:**
- **sns-lambda** → SNS-specific variables
- **alb-lambda** → ALB-specific variables
- **db-restore** → Database-specific variables (though not required as you mentioned)

## 📋 **Usage Examples**

### **✅ Adding New Environment Variables:**
```hcl
# In terraform.tfvars
lambda_env_vars = {
  "sns-lambda" = {
    ENVIRONMENT     = "dev"
    PROJECT         = "ifrs"
    FUNCTION        = "sns-lambda"
    TOPIC_NAME      = "dev-ifrs-notifications"
    LOG_LEVEL       = "DEBUG"           # New variable
    RETRY_COUNT     = "3"               # New variable
    TIMEOUT_SECONDS = "30"              # New variable
  }
}
```

### **✅ Adding New Function:**
```hcl
# In terraform.tfvars
lambda_env_vars = {
  "sns-lambda" = { /* existing config */ },
  "alb-lambda" = { /* existing config */ },
  "new-function" = {                    # New function
    ENVIRONMENT = "dev"
    PROJECT     = "ifrs"
    FUNCTION    = "new-function"
    CUSTOM_VAR  = "custom-value"
  }
}
```

## ⚠️ **Important Notes**

### **✅ DB-Restore Function:**
- **Environment variables not required** for db-restore (as you mentioned)
- **RDS module handles** its own environment variables
- **Configuration remains** in terraform.tfvars for consistency

### **✅ Variable Types:**
- **All values** must be strings (Terraform requirement)
- **Boolean values** → Use "true"/"false" strings
- **Numeric values** → Use string representation "123"

### **✅ Default Behavior:**
- **Missing functions** → Get empty environment variables `{}`
- **Missing variables** → Function gets only specified variables
- **Empty configuration** → All functions get empty environment variables

## 🚀 **Deployment**

### **✅ Apply Changes:**
```bash
cd environments/dev
terraform plan   # Review environment variable changes
terraform apply  # Deploy with dynamic environment variables
```

### **✅ Verify Environment Variables:**
```bash
# Check Lambda function environment variables in AWS Console
# or use AWS CLI:
aws lambda get-function-configuration --function-name dev-ifrs-sns-lambda
```

## 🎉 **Summary**

Your lambda deployment now supports **dynamic environment variables**:

### ✅ **Configured:**
- **All environments** (dev/staging/prod) support dynamic env vars
- **Lambda module** uses lookup logic for per-function variables
- **Development environment** has example configuration

### ✅ **Flexible:**
- **Add/modify** variables per function
- **Environment-specific** values
- **Easy maintenance** through terraform.tfvars

### ✅ **Production Ready:**
- **Consistent structure** across environments
- **Type-safe** configuration
- **Default fallbacks** for missing configurations

**🚀 Dynamic environment variables are now ready for deployment!**
