# Terraform Advanced Patterns & Troubleshooting

This document covers advanced Terraform patterns, common issues, and debugging techniques used in complex infrastructure projects.

## Advanced Patterns from Our Project

### 1. Module Composition Pattern

**Problem**: How to build complex infrastructure from reusable components?

**Solution**: Compose multiple focused modules within a parent module.

```hcl
# modules/frontend/main.tf - Composition example
module "ecr" {
  source = "../ecr"
  # ECR-specific configuration
}

module "s3" {
  source = "../s3"
  # S3-specific configuration
}

module "ec2" {
  source = "../ec2"
  # Pass outputs from other modules
  ecr_repository_url = module.ecr.repository_urls["angular-ui"]
  depends_on = [module.ecr]
}

module "rds" {
  source = "../rds"
  # RDS-specific configuration
}
```

**Benefits**:
- Single responsibility per module
- Reusable components
- Clear dependencies
- Easier testing and maintenance

### 2. Conditional Module Inclusion

**Problem**: Deploy different resources based on environment or feature flags.

**Solution**: Use count or for_each at the module level.

```hcl
# Conditional RDS deployment
module "rds" {
  count = var.deploy_database ? 1 : 0
  source = "./modules/rds"
  # ... configuration
}

# Reference with null check
database_endpoint = var.deploy_database ? module.rds[0].endpoint : null
```

### 3. Data Transformation Patterns

**Complex transformation example from SNS module:**

```hcl
# Input: Nested map structure
variable "lambda_sns_subscriptions" {
  default = {
    "data-processor" = ["data-events", "file-upload"]
    "api-handler" = ["user-notifications"]
  }
}

# Step 1: Flatten to list of objects
locals {
  subscription_pairs = flatten([
    for lambda_name, topics in var.lambda_sns_subscriptions : [
      for topic in topics : {
        lambda_name = lambda_name
        topic_name  = topic
        key         = "${lambda_name}-${topic}"
      }
    ]
  ])
  
  # Step 2: Convert to map for for_each
  subscriptions_map = {
    for item in local.subscription_pairs :
    item.key => item
  }
}

# Step 3: Use in resource creation
resource "aws_sns_topic_subscription" "lambda_subscriptions" {
  for_each = local.subscriptions_map
  
  topic_arn = aws_sns_topic.topics[each.value.topic_name].arn
  protocol  = "lambda"
  endpoint  = var.lambda_function_arns[each.value.lambda_name]
}
```

**Transformation steps explained:**
1. **Flatten**: Convert nested structure to flat list
2. **Map creation**: Create unique keys for for_each
3. **Resource creation**: Use transformed data

### 4. Dynamic Configuration Pattern

**Problem**: Configure resources based on runtime conditions.

**Example from RDS module:**

```hcl
resource "aws_db_instance" "main" {
  # Dynamic deletion protection
  deletion_protection = var.environment == "prod" ? true : var.deletion_protection
  
  # Dynamic backup retention
  backup_retention_period = var.environment == "prod" ? 30 : var.backup_retention_period
  
  # Dynamic instance class
  instance_class = var.environment == "prod" ? "db.t3.medium" : "db.t3.micro"
  
  # Dynamic multi-AZ
  multi_az = var.environment == "prod" ? true : var.multi_az
}
```

### 5. Resource Dependency Management

**Explicit vs Implicit Dependencies:**

```hcl
# Implicit dependency (preferred)
resource "aws_lambda_function" "example" {
  # Terraform detects dependency automatically
  role = aws_iam_role.lambda_role.arn
}

# Explicit dependency (when implicit isn't enough)
resource "aws_lambda_invocation" "db_restore" {
  function_name = aws_lambda_function.db_restore[0].function_name
  
  # Explicit dependency needed for proper ordering
  depends_on = [
    aws_db_instance.main,
    aws_lambda_function.db_restore
  ]
}
```

## Error Handling and Validation

### 1. Input Validation

```hcl
variable "environment" {
  type        = string
  description = "Environment name"
  
  validation {
    condition = contains(["dev", "int", "prod"], var.environment)
    error_message = "Environment must be one of: dev, int, prod."
  }
}

variable "instance_count" {
  type = number
  
  validation {
    condition = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}
```

### 2. Preconditions and Postconditions

```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  
  lifecycle {
    # Validate before creation
    precondition {
      condition = data.aws_ami.ubuntu.architecture == "x86_64"
      error_message = "AMI must be x86_64 architecture."
    }
    
    # Validate after creation
    postcondition {
      condition = self.public_ip != null
      error_message = "Instance must have a public IP."
    }
  }
}
```

### 3. Safe Resource References

```hcl
# Safe reference with null check
output "database_endpoint" {
  value = var.deploy_database ? module.rds[0].endpoint : null
}

# Safe array access
output "first_subnet" {
  value = length(data.aws_subnets.selected.ids) > 0 ? data.aws_subnets.selected.ids[0] : null
}

# Safe map access with default
output "layer_arn" {
  value = lookup(aws_lambda_layer_version.layers, "pandas-layer", null)
}
```

## Performance Optimization

### 1. Minimize Data Source Calls

**Bad - Multiple calls:**
```hcl
data "aws_subnet" "subnet_1" {
  id = "subnet-12345"
}

data "aws_subnet" "subnet_2" {
  id = "subnet-67890"
}
```

**Good - Single call:**
```hcl
data "aws_subnets" "selected" {
  filter {
    name   = "subnet-id"
    values = ["subnet-12345", "subnet-67890"]
  }
}
```

### 2. Use Locals for Complex Calculations

**Bad - Repeated calculations:**
```hcl
resource "aws_s3_object" "files" {
  for_each = toset(fileset(var.source_path, "**/*"))
  
  bucket = aws_s3_bucket.main.id
  key    = each.value
  source = "${var.source_path}/${each.value}"
  etag   = filemd5("${var.source_path}/${each.value}")
}
```

**Good - Calculate once:**
```hcl
locals {
  source_files = fileset(var.source_path, "**/*")
  file_hashes = {
    for file in local.source_files :
    file => filemd5("${var.source_path}/${file}")
  }
}

resource "aws_s3_object" "files" {
  for_each = toset(local.source_files)
  
  bucket = aws_s3_bucket.main.id
  key    = each.value
  source = "${var.source_path}/${each.value}"
  etag   = local.file_hashes[each.value]
}
```

## Debugging Techniques

### 1. Using `terraform console`

```bash
# Test expressions interactively
terraform console

# Test local values
> local.env_prefix
"dev-"

# Test functions
> merge({a = 1}, {b = 2})
{
  "a" = 1
  "b" = 2
}

# Test conditionals
> var.environment == "prod" ? "production" : "non-production"
"non-production"
```

### 2. Debug Output

```hcl
# Add debug outputs
output "debug_locals" {
  value = {
    env_prefix = local.env_prefix
    topic_names = local.topic_full_names
    file_count = length(local.ui_files)
  }
}

# Temporary debug resource
resource "null_resource" "debug" {
  triggers = {
    debug_info = jsonencode({
      subscription_pairs = local.subscription_pairs
      subscriptions_map = local.subscriptions_map
    })
  }
}
```

### 3. Validation with `terraform validate` and `terraform plan`

```bash
# Check syntax and configuration
terraform validate

# See what will be created/changed
terraform plan -detailed-exitcode

# Plan with specific variable file
terraform plan -var-file="dev.tfvars"

# Plan with target resource
terraform plan -target="module.frontend.module.rds"
```

## Common Pitfalls and Solutions

### 1. Count vs For_Each

**Problem**: Using count with dynamic lists causes resource recreation.

**Bad:**
```hcl
resource "aws_instance" "web" {
  count = length(var.instance_names)
  
  tags = {
    Name = var.instance_names[count.index]
  }
}
```

**Good:**
```hcl
resource "aws_instance" "web" {
  for_each = toset(var.instance_names)
  
  tags = {
    Name = each.value
  }
}
```

### 2. Module Output References

**Problem**: Referencing outputs from conditional modules.

**Bad:**
```hcl
output "db_endpoint" {
  value = module.rds.endpoint  # Error if module.rds doesn't exist
}
```

**Good:**
```hcl
output "db_endpoint" {
  value = var.deploy_database ? module.rds[0].endpoint : null
}
```

### 3. Circular Dependencies

**Problem**: Resources depend on each other.

**Solution**: Use data sources or separate the dependency.

```hcl
# Instead of circular dependency, use data source
data "aws_security_group" "existing" {
  name = "existing-sg"
}

resource "aws_security_group_rule" "new_rule" {
  security_group_id = data.aws_security_group.existing.id
  # ... rule configuration
}
```

## Testing Strategies

### 1. Unit Testing with Terratest

```go
// Example Terratest
func TestRDSModule(t *testing.T) {
    terraformOptions := &terraform.Options{
        TerraformDir: "../modules/rds",
        Vars: map[string]interface{}{
            "environment": "test",
            "db_name": "test_db",
        },
    }
    
    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)
    
    dbEndpoint := terraform.Output(t, terraformOptions, "db_instance_endpoint")
    assert.Contains(t, dbEndpoint, "rds.amazonaws.com")
}
```

### 2. Integration Testing

```bash
# Test complete deployment
terraform plan -var-file="test.tfvars"
terraform apply -var-file="test.tfvars" -auto-approve

# Run application tests
./run-integration-tests.sh

# Cleanup
terraform destroy -var-file="test.tfvars" -auto-approve
```

### 3. Policy Testing

```hcl
# Use Sentinel or OPA for policy testing
# Example: Ensure all S3 buckets are encrypted
rule "s3_bucket_encryption" {
  condition = all aws_s3_bucket as _, bucket {
    bucket.server_side_encryption_configuration is not null
  }
}
```

## Best Practices Summary

1. **Use locals for complex calculations**
2. **Validate inputs with validation blocks**
3. **Handle null values safely**
4. **Use for_each instead of count for dynamic resources**
5. **Minimize data source calls**
6. **Use explicit dependencies when needed**
7. **Test modules independently**
8. **Use consistent naming conventions**
9. **Tag all resources appropriately**
10. **Document complex logic with comments**

---

*This guide provides advanced patterns for building robust, maintainable Terraform infrastructure.*
