# Terraform Learning Guide - Advanced Concepts & Patterns

This comprehensive guide explains all the advanced Terraform concepts, functions, and patterns used in the IFRS InsightGen project. Each concept is explained with examples and practical use cases.

## Table of Contents

1. [Conditional Resource Creation](#conditional-resource-creation)
2. [String Functions and Type Conversions](#string-functions-and-type-conversions)
3. [Collection Functions and Iteration](#collection-functions-and-iteration)
4. [Data Sources and Resource References](#data-sources-and-resource-references)
5. [Local Values and Computed Expressions](#local-values-and-computed-expressions)
6. [Tag Management and Merging](#tag-management-and-merging)
7. [Dynamic Blocks and Meta-Arguments](#dynamic-blocks-and-meta-arguments)
8. [File and Template Functions](#file-and-template-functions)
9. [Error Handling and Validation](#error-handling-and-validation)
10. [Advanced Patterns and Best Practices](#advanced-patterns-and-best-practices)

---

## 1. Conditional Resource Creation

### The `count` Meta-Argument

**Example from RDS module:**
```t
count = (var.sql_backup_s3_bucket != "" && var.sql_backup_s3_key != "") || var.sql_backup_local_path != "" ? 1 : 0
```

**What's happening here:**

1. **Condition Check**: `(var.sql_backup_s3_bucket != "" && var.sql_backup_s3_key != "")`
   - Checks if BOTH S3 bucket AND S3 key are provided (not empty strings)
   - `&&` is the logical AND operator

2. **Alternative Condition**: `|| var.sql_backup_local_path != ""`
   - `||` is the logical OR operator
   - Checks if local backup path is provided

3. **Ternary Operator**: `condition ? true_value : false_value`
   - If either condition is true → create 1 resource
   - If both conditions are false → create 0 resources (no resource)

**Practical Example:**
```t
# Scenario 1: S3 backup provided
sql_backup_s3_bucket = "my-backup-bucket"
sql_backup_s3_key = "backups/db.sql"
sql_backup_local_path = ""
# Result: count = 1 (resource created)

# Scenario 2: Local backup provided
sql_backup_s3_bucket = ""
sql_backup_s3_key = ""
sql_backup_local_path = "./backup.sql"
# Result: count = 1 (resource created)

# Scenario 3: No backup provided
sql_backup_s3_bucket = ""
sql_backup_s3_key = ""
sql_backup_local_path = ""
# Result: count = 0 (no resource created)
```

### Other Conditional Patterns in the Project

**Environment-based conditions:**
```t
# From RDS module
deletion_protection = var.environment == "prod" ? true : var.deletion_protection
```
- Production environments get deletion protection automatically
- Other environments use the variable value

**Resource existence checks:**
```t
# From EC2 module
data "aws_ami" "selected" {
  count = var.ami_id == "" ? 1 : 0
  # Only fetch AMI data if specific AMI ID is not provided
}
```

---

## 2. String Functions and Type Conversions

### The `tostring()` Function

**Example from RDS module:**
```t
RDS_PORT = tostring(var.db_port)
```

**Why use `tostring()`?**

1. **Type Safety**: Environment variables in Lambda are always strings
2. **Variable Type**: `var.db_port` is defined as `number` type
3. **Conversion Need**: Must convert number to string for environment variable

**Practical Example:**
```t
variable "db_port" {
  type    = number
  default = 5432
}

# Without tostring() - ERROR!
environment {
  variables = {
    RDS_PORT = var.db_port  # Error: number cannot be used as string
  }
}

# With tostring() - WORKS!
environment {
  variables = {
    RDS_PORT = tostring(var.db_port)  # "5432"
  }
}
```

### String Interpolation and Functions

**Environment prefix logic:**
```t
# From locals.tf
env_prefix = var.environment == "prod" ? "" : "${var.environment}-"
```

**Examples:**
- `environment = "dev"` → `env_prefix = "dev-"`
- `environment = "prod"` → `env_prefix = ""`
- `environment = "int"` → `env_prefix = "int-"`

**String manipulation functions:**
```t
# From backend module
trimsuffix(each.value, ".zip")
# Removes ".zip" from end of filename
# "function1.zip" → "function1"
```

---

## 3. Collection Functions and Iteration

### The `for_each` Meta-Argument

**Example from SNS module:**
```t
resource "aws_sns_topic" "topics" {
  for_each = toset(var.topic_names)
  
  name = local.topic_full_names[each.value]
}
```

**What's happening:**

1. **`toset()`**: Converts list to set (removes duplicates, ensures uniqueness)
2. **`each.value`**: Current item being iterated
3. **`each.key`**: In sets, key equals value

**Practical Example:**
```t
variable "topic_names" {
  default = ["data-events", "user-notifications", "system-alerts"]
}

# This creates 3 SNS topics:
# - aws_sns_topic.topics["data-events"]
# - aws_sns_topic.topics["user-notifications"]  
# - aws_sns_topic.topics["system-alerts"]
```

### Complex Collection Processing

**Flattening nested structures:**
```t
# From SNS module
subscription_pairs = flatten([
  for lambda_name, topics in var.lambda_sns_subscriptions : [
    for topic in topics : {
      lambda_name = lambda_name
      topic_name  = topic
      key         = "${lambda_name}-${topic}"
    }
  ]
])
```

**Step-by-step breakdown:**

1. **Input data:**
```t
lambda_sns_subscriptions = {
  "data-processor" = ["data-events", "file-upload"]
  "api-handler" = ["user-notifications"]
}
```

2. **First loop:** `for lambda_name, topics in var.lambda_sns_subscriptions`
   - Iteration 1: `lambda_name = "data-processor"`, `topics = ["data-events", "file-upload"]`
   - Iteration 2: `lambda_name = "api-handler"`, `topics = ["user-notifications"]`

3. **Second loop:** `for topic in topics`
   - Creates object for each topic

4. **Result after flatten:**
```t
[
  {
    lambda_name = "data-processor"
    topic_name  = "data-events"
    key         = "data-processor-data-events"
  },
  {
    lambda_name = "data-processor"
    topic_name  = "file-upload"
    key         = "data-processor-file-upload"
  },
  {
    lambda_name = "api-handler"
    topic_name  = "user-notifications"
    key         = "api-handler-user-notifications"
  }
]
```

---

## 4. Data Sources and Resource References

### Array Indexing with `[0]`

**Example from RDS module:**
```t
filename = data.archive_file.db_restore_zip[0].output_path
```

**Why `[0]`?**

1. **Count-based resources**: When using `count`, Terraform creates an array
2. **Array access**: `[0]` gets the first (and only) element
3. **Conditional creation**: Resource only exists when `count = 1`

**Practical Example:**
```t
# Resource definition with count
resource "aws_lambda_function" "db_restore" {
  count = var.create_restore_function ? 1 : 0
  # ... other configuration
}

# When count = 1, creates: aws_lambda_function.db_restore[0]
# When count = 0, creates: nothing

# Referencing the resource
output "lambda_arn" {
  value = var.create_restore_function ? aws_lambda_function.db_restore[0].arn : null
}
```

### Data Source Usage

**AMI selection logic:**
```t
# From EC2 module
data "aws_ami" "selected" {
  count = var.ami_id == "" ? 1 : 0
  # Only fetch if specific AMI not provided
}

# Usage in resource
ami = var.ami_id != "" ? var.ami_id : data.aws_ami.selected[0].id
```

**Logic flow:**
1. If `ami_id` is provided → use it directly
2. If `ami_id` is empty → fetch AMI using data source, then use `[0]` to get first result

---

## 5. Local Values and Computed Expressions

### Complex Local Calculations

**Environment naming logic:**
```t
locals {
  env_prefix = var.environment == "prod" ? "" : "${var.environment}-"
  resource_name_prefix = "${local.env_prefix}${var.lambda_prefix}"
  db_instance_identifier = "${local.resource_name_prefix}-postgres"
}
```

**Example calculations:**
- Environment: `"dev"`, Lambda prefix: `"insightgen"`
- `env_prefix = "dev-"`
- `resource_name_prefix = "dev-insightgen"`
- `db_instance_identifier = "dev-insightgen-postgres"`

### File Discovery Logic

**Dynamic file listing:**
```t
# From backend module
locals {
  lambda_function_files = var.use_local_source ? (
    fileexists(var.lambda_code_local_path) ? 
    fileset(var.lambda_code_local_path, "*.zip") : []
  ) : []
}
```

**Step-by-step:**
1. **Check if using local source**: `var.use_local_source`
2. **Check if directory exists**: `fileexists(var.lambda_code_local_path)`
3. **Get all .zip files**: `fileset(var.lambda_code_local_path, "*.zip")`
4. **Return empty list if conditions not met**: `[]`

---

## 6. Tag Management and Merging

### The `merge()` Function

**Example from throughout the project:**
```t
tags = merge(var.common_tags, {
  Name        = "${local.resource_name_prefix}-postgres"
  Description = "PostgreSQL database for ${var.project_name}"
  Module      = "rds"
  Engine      = "postgres"
})
```

**Why use `merge()`?**

1. **Consistency**: Apply common tags to all resources
2. **Override capability**: Resource-specific tags override common ones
3. **Maintainability**: Change common tags in one place

**Practical Example:**
```t
# Common tags
common_tags = {
  Environment = "dev"
  Project     = "InsightGen"
  Owner       = "DataTeam"
  CostCenter  = "Engineering"
}

# Resource-specific tags
resource_tags = {
  Name   = "my-database"
  Module = "rds"
  Owner  = "DatabaseTeam"  # This overrides common_tags.Owner
}

# Result after merge
final_tags = {
  Environment = "dev"           # From common_tags
  Project     = "InsightGen"    # From common_tags
  Owner       = "DatabaseTeam"  # From resource_tags (overridden)
  CostCenter  = "Engineering"   # From common_tags
  Name        = "my-database"   # From resource_tags
  Module      = "rds"          # From resource_tags
}
```

---

## 7. Dynamic Blocks and Meta-Arguments

### Dynamic Block Creation

**Example from main.tf:**
```t
dynamic "filter" {
  for_each = var.subnet_names
  content {
    name   = "tag:Name"
    values = [filter.value]
  }
}
```

**What's happening:**

1. **`dynamic "filter"`**: Creates multiple `filter` blocks
2. **`for_each = var.subnet_names`**: One block per subnet name
3. **`filter.value`**: Current subnet name being processed

**Practical Example:**
```t
variable "subnet_names" {
  default = ["private-subnet-1", "private-subnet-2"]
}

# This generates:
filter {
  name   = "tag:Name"
  values = ["private-subnet-1"]
}
filter {
  name   = "tag:Name"
  values = ["private-subnet-2"]
}
```

### Conditional Blocks

**Example from RDS module:**
```t
vpc_config {
  subnet_ids         = var.subnet_ids
  security_group_ids = var.security_group_ids
}
```

This block is only included when the Lambda function needs VPC access.

---

## 8. File and Template Functions

### Template File Processing

**Example from EC2 module:**
```t
user_data = base64encode(templatefile("${path.module}/user-data.sh", {
  ecr_repository_url    = var.ecr_repository_url
  container_port        = var.ui_container_port
  aws_region           = data.aws_region.current.name
  deploy_database      = var.deploy_database
}))
```

**Function breakdown:**

1. **`templatefile()`**: Processes template with variables
2. **`${path.module}`**: Path to current module directory
3. **`base64encode()`**: Encodes result for EC2 user data
4. **Template variables**: Passed as second argument (map)

**Template usage in user-data.sh:**
```bash
# Template variables are referenced with ${variable_name}
aws ecr get-login-password --region ${aws_region}
docker run -p 80:${container_port} ${ecr_repository_url}:latest

%{ if deploy_database ~}
echo "Database deployment enabled"
%{ else ~}
echo "Database deployment disabled"
%{ endif ~}
```

### File Functions

**File existence and content:**
```t
# Check if file exists
fileexists(var.lambda_code_local_path)

# Get files matching pattern
fileset(var.lambda_code_local_path, "*.zip")

# Calculate file hash
filemd5("${var.lambda_layers_local_path}/${each.value}")
```

---

## 9. Error Handling and Validation

### Null Checks and Safe References

**Example from outputs:**
```t
rds_endpoint = module.frontend.database_info != null ? module.frontend.database_info.endpoint : null
```

**Safe array access:**
```t
ami_used = var.ami_id != "" ? var.ami_id : (
  length(data.aws_ami.selected) > 0 ? data.aws_ami.selected[0].id : null
)
```

### Validation Patterns

**Variable validation:**
```t
variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "int", "prod"], var.environment)
    error_message = "Environment must be dev, int, or prod."
  }
}
```

---

## 10. Advanced Patterns and Best Practices

### Module Communication

**Passing computed values between modules:**
```t
# In frontend module
module "rds" {
  source = "../rds"
  # ... configuration
}

module "ec2" {
  source = "../ec2"
  # Pass RDS endpoint to EC2
  database_endpoint = module.rds.db_instance_endpoint
  depends_on = [module.rds]
}
```

### Resource Dependencies

**Explicit dependencies:**
```t
depends_on = [aws_db_instance.main]
```

**Implicit dependencies:**
```t
# Terraform automatically detects this dependency
subnet_group_name = aws_db_subnet_group.main.name
```

---

## Real-World Examples from Our Project

### Example 1: SNS Topic Creation with Dynamic Naming

**From `modules/sns/main.tf`:**
```t
locals {
  env_prefix = var.environment == "prod" ? "" : "${var.environment}-"
  topic_name_prefix = "${local.env_prefix}${var.lambda_prefix}-"
  
  topic_full_names = {
    for topic in var.topic_names :
    topic => "${local.topic_name_prefix}${topic}"
  }
}

resource "aws_sns_topic" "topics" {
  for_each = toset(var.topic_names)
  
  name = local.topic_full_names[each.value]
}
```

**Breakdown:**
1. **Environment logic**: Production gets no prefix, others get env prefix
2. **For expression**: Creates map of topic names to full names
3. **Resource creation**: Uses `for_each` to create multiple topics

**Example with data:**
```t
# Input
environment = "dev"
lambda_prefix = "insightgen"
topic_names = ["data-events", "user-notifications"]

# Processing
env_prefix = "dev-"
topic_name_prefix = "dev-insightgen-"

topic_full_names = {
  "data-events" = "dev-insightgen-data-events"
  "user-notifications" = "dev-insightgen-user-notifications"
}

# Result: Creates 2 SNS topics with computed names
```

### Example 2: Lambda Layer Attachment Logic

**From `modules/backend/lambda-functions.tf`:**
```t
resource "aws_lambda_function" "functions" {
  for_each = toset(local.lambda_function_names)
  
  layers = lookup(var.lambda_layer_mappings, each.value, []) != [] ? [
    for layer_name in lookup(var.lambda_layer_mappings, each.value, []) :
    aws_lambda_layer_version.layers[layer_name].arn
  ] : []
}
```

**Complex logic breakdown:**

1. **`lookup(var.lambda_layer_mappings, each.value, [])`**:
   - Looks up layers for current function
   - Returns empty list `[]` if function not found in mapping

2. **`!= []`**: Checks if function has any layers assigned

3. **Conditional list creation**:
   - If layers exist: Create list of layer ARNs
   - If no layers: Use empty list

**Example:**
```t
# Input
lambda_layer_mappings = {
  "data-processor" = ["pandas-layer", "numpy-layer"]
  "api-handler" = ["requests-layer"]
}

# For function "data-processor":
lookup_result = ["pandas-layer", "numpy-layer"]
condition = ["pandas-layer", "numpy-layer"] != [] # true
layers = [
  aws_lambda_layer_version.layers["pandas-layer"].arn,
  aws_lambda_layer_version.layers["numpy-layer"].arn
]

# For function "simple-function" (not in mapping):
lookup_result = [] # default value
condition = [] != [] # false
layers = [] # empty list
```

### Example 3: S3 Object Upload with Content Type Detection

**From `modules/s3/main.tf`:**
```t
resource "aws_s3_object" "ui_files" {
  for_each = var.create_ui_bucket && var.use_local_ui_source ? toset(local.ui_files) : []
  
  bucket       = aws_s3_bucket.ui_assets[0].id
  key          = each.value
  source       = "${var.ui_assets_local_path}/${each.value}"
  etag         = filemd5("${var.ui_assets_local_path}/${each.value}")
  content_type = lookup(local.content_types, regex("\\.[^.]+$", each.value), "application/octet-stream")
}

locals {
  ui_files = var.use_local_ui_source ? (
    fileexists(var.ui_assets_local_path) ? 
    fileset(var.ui_assets_local_path, "**/*") : []
  ) : []
  
  content_types = {
    ".html" = "text/html"
    ".css"  = "text/css"
    ".js"   = "application/javascript"
    ".json" = "application/json"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".svg"  = "image/svg+xml"
  }
}
```

**Advanced concepts:**

1. **Nested conditionals**: `var.create_ui_bucket && var.use_local_ui_source`
2. **File discovery**: `fileset(var.ui_assets_local_path, "**/*")` gets all files recursively
3. **Regex extraction**: `regex("\\.[^.]+$", each.value)` extracts file extension
4. **Content type mapping**: Uses lookup with default fallback

### Example 4: RDS Parameter Group with Dynamic Parameters

**From `modules/rds/main.tf`:**
```t
resource "aws_db_parameter_group" "main" {
  family = "postgres15"
  name   = local.db_parameter_group_name
  
  parameter {
    name  = "log_statement"
    value = "all"
  }
  
  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
  }
  
  dynamic "parameter" {
    for_each = var.custom_parameters
    content {
      name  = parameter.key
      value = parameter.value
    }
  }
}
```

**Dynamic parameter addition:**
- Static parameters are always applied
- Dynamic block adds custom parameters from variable
- Allows flexibility without code changes

## Practice Exercises

### Exercise 1: Conditional Resource Creation
**Challenge**: Create an S3 bucket that only exists in production environments.

```t
# Your solution here
resource "aws_s3_bucket" "prod_only" {
  count  = var.environment == "prod" ? 1 : 0
  bucket = "${var.project_name}-prod-data"
}
```

### Exercise 2: Complex Naming Logic
**Challenge**: Create a naming convention that includes region, environment, and resource type.

```t
locals {
  # Your solution here
  base_name = "${var.region}-${var.environment}-${var.project_name}"
  
  resource_names = {
    database = "${local.base_name}-db"
    cache    = "${local.base_name}-cache"
    queue    = "${local.base_name}-queue"
  }
}
```

### Exercise 3: Collection Processing
**Challenge**: Create security group rules from a list of port configurations.

```t
variable "allowed_ports" {
  default = [
    { port = 80, protocol = "tcp", description = "HTTP" },
    { port = 443, protocol = "tcp", description = "HTTPS" },
    { port = 22, protocol = "tcp", description = "SSH" }
  ]
}

resource "aws_security_group_rule" "ingress" {
  for_each = { for idx, port in var.allowed_ports : idx => port }
  
  # Your solution here
  type        = "ingress"
  from_port   = each.value.port
  to_port     = each.value.port
  protocol    = each.value.protocol
  description = each.value.description
}
```

### Exercise 4: Template Processing
**Challenge**: Create a user data script that conditionally installs different software.

```bash
#!/bin/bash
# user-data-template.sh

%{ if install_docker ~}
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
%{ endif ~}

%{ if install_nodejs ~}
# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
apt-get install -y nodejs
%{ endif ~}

# Install packages
%{ for package in packages ~}
apt-get install -y ${package}
%{ endfor ~}
```

### Exercise 5: Advanced Tag Management
**Challenge**: Create a tagging system that automatically adds cost allocation tags.

```t
locals {
  # Base tags applied to all resources
  base_tags = {
    Environment   = var.environment
    Project      = var.project_name
    ManagedBy    = "Terraform"
    CreatedDate  = formatdate("YYYY-MM-DD", timestamp())
  }
  
  # Cost allocation tags
  cost_tags = {
    CostCenter   = var.cost_center
    Department   = var.department
    Application  = var.application_name
  }
  
  # Compliance tags
  compliance_tags = var.environment == "prod" ? {
    DataClass      = "confidential"
    BackupRequired = "true"
    Monitoring     = "enabled"
  } : {}
  
  # Final merged tags
  common_tags = merge(
    local.base_tags,
    local.cost_tags,
    local.compliance_tags,
    var.additional_tags
  )
}
```

## Hands-On Practice Questions

### Beginner Level

1. **Question**: What will be the value of `count` in this expression?
   ```t
   count = var.create_backup && var.environment != "dev" ? 1 : 0
   ```
   Given: `create_backup = true`, `environment = "prod"`

2. **Question**: What resources will be created with this `for_each`?
   ```t
   for_each = toset(["web", "api", "db"])
   ```

3. **Question**: What is the result of this merge?
   ```t
   merge({Name = "test", Env = "dev"}, {Name = "prod", Type = "db"})
   ```

### Intermediate Level

4. **Question**: Explain what this local value computes:
   ```t
   locals {
     subnet_map = {
       for subnet in data.aws_subnets.all.ids :
       subnet => data.aws_subnet.details[subnet].availability_zone
     }
   }
   ```

5. **Question**: What happens when `var.ami_id` is empty?
   ```t
   ami = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu[0].id
   ```

### Advanced Level

6. **Question**: Trace through this complex expression:
   ```t
   subscription_pairs = flatten([
     for lambda_name, topics in var.lambda_sns_subscriptions : [
       for topic in topics : {
         key = "${lambda_name}-${topic}"
         lambda = lambda_name
         topic = topic
       }
     ]
   ])
   ```

7. **Question**: What is the purpose of this validation?
   ```t
   lifecycle {
     precondition {
       condition = var.instance_count > 0 && var.instance_count <= 10
       error_message = "Instance count must be between 1 and 10."
     }
   }
   ```

## Answer Key

### Beginner Answers
1. `count = 1` (both conditions true: `true && true`)
2. Creates 3 resources with keys: "web", "api", "db"
3. `{Name = "prod", Env = "dev", Type = "db"}` (Name overridden)

### Intermediate Answers
4. Creates a map where each subnet ID maps to its availability zone
5. Uses the data source to fetch Ubuntu AMI and takes the first result

### Advanced Answers
6. Flattens nested lambda-topic relationships into a flat list of subscription pairs
7. Validates that instance count is within acceptable range before applying

---

*Continue practicing these patterns to master Terraform's advanced features!*
