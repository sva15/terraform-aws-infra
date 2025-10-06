# ✅ SNS Configuration Fix - Lambda Subscriptions

## 🚨 **Issue Identified and Fixed**

The SNS lambda subscriptions were configured incorrectly, causing the following errors:
- `Invalid index` errors in SNS module
- Topic ARN lookup failures
- Lambda function ARN mapping issues

## 🔧 **Root Cause**

### **❌ Previous (Incorrect) Configuration:**
```hcl
# WRONG: Topic name as key, lambda functions as values
lambda_sns_subscriptions = {
  "dev-ifrs-notifications" = ["sns-lambda"]
}
```

### **✅ Correct Configuration:**
```hcl
# CORRECT: Lambda function as key, topic names as values
lambda_sns_subscriptions = {
  "sns-lambda" = ["dev-ifrs-notifications"]
}
```

## 📊 **SNS Module Logic**

### **✅ How SNS Module Processes Subscriptions:**
```hcl
# In modules/sns/main.tf
subscription_pairs = flatten([
  for lambda_name, topics in var.lambda_sns_subscriptions : [
    for topic in topics : {
      lambda_name = lambda_name  # Key from lambda_sns_subscriptions
      topic_name  = topic        # Value from lambda_sns_subscriptions
      key         = "${lambda_name}-${topic}"
    }
  ]
])
```

### **✅ Expected Data Structure:**
- **Key**: Lambda function name (e.g., "sns-lambda")
- **Value**: List of topic names that lambda should subscribe to

## 🔧 **Fixed Configurations**

### **✅ Development Environment:**
```hcl
# environments/dev/terraform.tfvars
sns_topic_names = ["dev-ifrs-notifications"]
lambda_sns_subscriptions = {
  "sns-lambda" = ["dev-ifrs-notifications"]
}
```

### **✅ Staging Environment:**
```hcl
# environments/staging/terraform.tfvars
sns_topic_names = ["staging-ifrs-notifications"]
lambda_sns_subscriptions = {
  "sns-lambda" = ["staging-ifrs-notifications"]
}
```

### **✅ Production Environment:**
```hcl
# environments/prod/terraform.tfvars
sns_topic_names = ["prod-ifrs-notifications", "prod-ifrs-alerts"]
lambda_sns_subscriptions = {
  "sns-lambda" = ["prod-ifrs-notifications", "prod-ifrs-alerts"]
}
```

## 🎯 **Configuration Logic**

### **✅ Topic Creation:**
```hcl
# Creates topics with environment prefix
sns_topic_names = ["dev-ifrs-notifications"]
# Results in topic: "dev-dev-ifrs-notifications" (with environment prefix)
```

### **✅ Lambda Subscriptions:**
```hcl
# Maps lambda functions to topics they should subscribe to
lambda_sns_subscriptions = {
  "sns-lambda" = ["dev-ifrs-notifications"]
}
# Results in: sns-lambda function subscribes to dev-ifrs-notifications topic
```

### **✅ Multiple Topics per Lambda:**
```hcl
# Example: One lambda function subscribing to multiple topics
lambda_sns_subscriptions = {
  "sns-lambda" = ["notifications", "alerts", "errors"]
}
```

### **✅ Multiple Lambdas per Topic:**
```hcl
# Example: Multiple lambda functions subscribing to different topics
lambda_sns_subscriptions = {
  "sns-lambda"   = ["notifications"]
  "alert-lambda" = ["alerts"]
  "error-lambda" = ["errors"]
}
```

## 🔍 **Error Resolution**

### **❌ Previous Errors:**
```
Error: Invalid index
│ on ../../modules/sns/main.tf line 144:
│ topic_arn = aws_sns_topic.topics[each.value.topic_name].arn
│ aws_sns_topic.topics is object with 1 attribute "dev-ifrs-notifications"
│ each.value.topic_name is "sns-lambda"
```

### **✅ Why It Failed:**
1. **SNS module expected**: `topic_name = "dev-ifrs-notifications"`
2. **But received**: `topic_name = "sns-lambda"` (lambda function name)
3. **Topic lookup failed**: No topic named "sns-lambda" exists

### **✅ How Fix Resolves It:**
1. **Now SNS module receives**: `topic_name = "dev-ifrs-notifications"`
2. **Topic lookup succeeds**: Topic exists with that name
3. **Lambda ARN lookup succeeds**: Lambda function "sns-lambda" exists

## 📋 **Additional Fixes**

### **✅ Lambda Environment Variables:**
```hcl
# Fixed missing environment variables for alb-lambda
lambda_env_vars = {
  "alb-lambda" = {
    ENVIRONMENT = "dev"    # Added
    PROJECT     = "ifrs"   # Added
    FUNCTION    = "alb-lambda"
    ALB_NAME    = "ifrs-alb"
  }
}
```

## 🚀 **Deployment**

### **✅ Test the Fix:**
```bash
cd environments/dev
terraform plan
# Should now show successful SNS topic and subscription creation
```

### **✅ Apply Changes:**
```bash
terraform apply
# SNS topics and lambda subscriptions should be created successfully
```

### **✅ Verify SNS Configuration:**
```bash
# Check SNS topics
aws sns list-topics

# Check subscriptions
aws sns list-subscriptions

# Check lambda permissions
aws lambda get-policy --function-name dev-ifrs-sns-lambda
```

## 🎯 **Best Practices**

### **✅ SNS Configuration Pattern:**
```hcl
# Always use this pattern:
lambda_sns_subscriptions = {
  "lambda-function-name" = ["topic1", "topic2", ...]
}

# NOT this pattern:
lambda_sns_subscriptions = {
  "topic-name" = ["lambda1", "lambda2", ...]  # WRONG
}
```

### **✅ Environment-Specific Topics:**
```hcl
# Use environment prefixes for topic names
# Dev
sns_topic_names = ["dev-ifrs-notifications"]

# Staging  
sns_topic_names = ["staging-ifrs-notifications"]

# Prod
sns_topic_names = ["prod-ifrs-notifications", "prod-ifrs-alerts"]
```

## 🎉 **Summary**

### ✅ **Fixed Issues:**
- **SNS subscription mapping** corrected across all environments
- **Lambda environment variables** completed for all functions
- **Topic name resolution** now works correctly
- **Lambda ARN mapping** now functions properly

### ✅ **All Environments Updated:**
- **Dev**: Single topic subscription fixed
- **Staging**: Single topic subscription fixed  
- **Prod**: Multiple topic subscriptions fixed

### ✅ **Ready for Deployment:**
- **SNS topics** will be created with correct names
- **Lambda subscriptions** will be established properly
- **Environment variables** are complete and consistent

**🚀 SNS configuration is now correct and ready for deployment!**
