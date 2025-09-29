# AWS Full-Stack Application Deployment with Terraform

This Terraform project deploys a complete full-stack application with AWS Lambda backend functions and an Angular UI frontend, using a modular architecture for scalability and maintainability.

## Features

### Backend (Lambda Functions)
- **Multi-Environment Support**: Deploy to dev, int, or prod environments with appropriate naming conventions
- **Flexible Source Management**: Use local zip files or S3-stored artifacts
- **Automatic S3 Upload**: Optionally create S3 bucket and upload local files
- **Layer Management**: Conditional layer attachment based on function requirements
- **VPC Integration**: Deploy Lambda functions within existing VPC infrastructure
- **CloudWatch Integration**: Automatic log group creation for each function
- **SNS Integration**: Automatic topic creation and Lambda function subscriptions

### Frontend (Angular UI)
- **Containerized Deployment**: Angular app deployed via Docker containers
- **ECR Integration**: Automatic ECR repository creation and management
- **Private EC2 Hosting**: UI served from EC2 instance (no public IP) with nginx
- **RDS Integration**: Connects to managed PostgreSQL database
- **Health Monitoring**: Built-in health checks and auto-restart capabilities

### Database (RDS PostgreSQL)
- **Managed Database**: AWS RDS PostgreSQL with automated backups
- **Secrets Manager Integration**: Secure password management with AWS Secrets Manager
- **SQL Backup Restoration**: Automatic restoration from S3 or local backup files
- **Multi-AZ Support**: High availability configuration for production
- **Performance Insights**: Enhanced monitoring and performance analysis
- **Encryption**: KMS encryption for data at rest and credentials

### Infrastructure
- **Modular Architecture**: Separate modules for backend, frontend, ECR, EC2, S3, SNS, and RDS
- **Consistent Tagging**: Global tagging strategy with project-level tags
- **Security Best Practices**: Encrypted storage, standardized IAM roles, VPC isolation, and security groups
- **Private Networking**: EC2 instances with no public IP for enhanced security
- **IAM Role Standards**: All roles follow `HCL-User-Role-insightgen-servicename` naming convention

## Security Features

### Password Management
- **AWS Secrets Manager**: RDS passwords are automatically generated and stored securely
- **No Plain Text**: Passwords never appear in Terraform state or logs
- **Automatic Rotation**: Support for automatic password rotation (configurable)

### Network Security
- **Private Subnets**: RDS and EC2 instances deployed in private subnets
- **Access Control**:
  - **IAM Roles**: Least privilege access with service-specific roles
  - **Standardized Naming**: All IAM roles follow `HCL-User-Role-insightgen-servicename` pattern
  - **Resource Isolation**: Clear boundaries between different services
  - **Policy Segregation**: Separate policies for different access patterns

### IAM Role Naming Convention
All IAM roles in this project follow a standardized naming pattern:
- **Pattern**: `HCL-User-Role-insightgen-servicename`
- **Examples**:
  - `HCL-User-Role-insightgen-lambda-execution` (Backend Lambda functions)
  - `HCL-User-Role-insightgen-ec2-ui` (EC2 instance for UI hosting)
  - `HCL-User-Role-insightgen-rds-monitoring` (RDS enhanced monitoring)
  - `HCL-User-Role-insightgen-db-restore-lambda` (Database restore Lambda)

### Encryption
- **Data at Rest**: RDS storage encrypted with KMS
- **Data in Transit**: SSL/TLS encryption for database connections
- **Secrets Encryption**: Secrets Manager uses KMS encryption
- **EBS Encryption**: EC2 instance storage encrypted

## Project Structure

```
.
├── main.tf                    # Root module orchestrating all components
├── variables.tf               # Root module variables
├── outputs.tf                 # Root module outputs
├── terraform.tfvars.example   # Example configuration
├── README.md                  # This documentation
├── .gitignore                 # Git ignore rules
│
├── modules/                   # Terraform modules
│   ├── backend/              # Lambda functions and layers
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── locals.tf
│   │   ├── iam.tf
│   │   ├── lambda-layers.tf
│   │   └── lambda-functions.tf
│   │
│   ├── frontend/             # UI application orchestration
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── ecr/                  # Container registries
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── s3/                   # S3 buckets for assets
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── ec2/                  # EC2 instance for UI hosting
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── user-data.sh
│   │
│   ├── sns/                  # SNS topics and subscriptions
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   └── rds/                  # RDS PostgreSQL database
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── db_restore.py
│
├── backend/                  # Backend Lambda code
│   ├── python-aws-lambda-functions/
│   │   ├── function1.zip
│   │   ├── function2.zip
│   │   └── sample_function.py
│   └── lambda-layers/
│       ├── layer1.zip
│       └── layer2.zip
│
└── ui/                       # Frontend Angular application
    ├── dist/                 # Angular build output (ng build)
    ├── Dockerfile           # Docker configuration
    ├── default.conf         # Nginx configuration
    ├── package.json         # Node.js dependencies
    └── build-and-push.ps1   # Build and push script
```

## Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.0 installed
3. **Docker** installed for building UI containers
4. **Node.js and npm** for Angular development (optional)
5. **Backend Assets**:
   - Python Lambda function zip files in `backend/python-aws-lambda-functions/`
   - Lambda layer zip files in `backend/lambda-layers/`
6. **Frontend Assets**:
   - Angular build output in `ui/dist/` (from `ng build`)
7. **Existing AWS Infrastructure**:
   - VPC with appropriate name tag
   - Private subnets for Lambda functions
   - Public subnets for EC2 instance
   - Security groups with appropriate name tags

## Quick Start

### 1. **Setup Configuration**:
```bash
# Copy the example configuration
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your specific values:
```hcl
environment = "dev"
vpc_name = "your-vpc-name"
subnet_names = ["private-subnet-1", "private-subnet-2"]
public_subnet_names = ["public-subnet-1", "public-subnet-2"]
security_group_names = ["lambda-sg"]
```

### 2. **Prepare Backend Assets**:
```bash
# Backend assets are already in the correct location
# backend/python-aws-lambda-functions/sample_function.py (example provided)
# Place your Lambda function zip files in backend/python-aws-lambda-functions/
# Place your Lambda layer zip files in backend/lambda-layers/
```

### 3. **Prepare Frontend Assets**:
```bash
# Build your Angular application
cd ui
ng build --configuration production

# Verify dist folder exists
ls dist/
```

### 4. **Deploy Infrastructure**:
```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan -var="environment=dev"

# Apply the deployment
terraform apply -var="environment=dev"
```

### 5. **Build and Push UI Container**:
After Terraform deployment completes, get the ECR repository URL from outputs:
```bash
# Get ECR repository URL
terraform output frontend

# Build and push the UI container
cd ui
./build-and-push.ps1 -ECRRepository "YOUR_ECR_REPO_URL" -AWSRegion "us-east-1"
```

### 6. **Access Your Application**:
```bash
# Get the UI application URL
terraform output quick_access
```

## Configuration

Copy `terraform.tfvars.example` to `terraform.tfvars` and customize the values:

### Database Security Configuration

**Recommended (Secrets Manager):**
```hcl
use_secrets_manager = true  # Default: true
postgres_password = ""      # Not needed when using Secrets Manager
```

**Legacy (Plain Text Password):**
```hcl
use_secrets_manager = false
postgres_password = "your-secure-password"
```

When `use_secrets_manager = true`:
- RDS automatically generates a secure password
- Password is stored in AWS Secrets Manager
- Lambda functions retrieve password securely
- No passwords in Terraform state or logs

### Environment Naming

The project automatically handles environment-specific naming:

- **Production** (`prod`): `insightgen-function-name`
- **Development** (`dev`): `dev-insightgen-function-name`
- **Integration** (`int`): `int-insightgen-function-name`

### Layer Mappings

Define which layers each function should use in `terraform.tfvars`:

```hcl
lambda_layer_mappings = {
  "data-processor" = ["pandas-layer", "numpy-layer"]
  "api-handler" = ["requests-layer"]
  "ml-inference" = ["sklearn-layer", "pandas-layer"]
}
```

### Source Management Options

#### Option 1: Local Files with S3 Upload (Recommended)
```hcl
use_local_source = true
create_s3_bucket = true
```
- Reads zip files from local directories
- Creates S3 bucket automatically
- Uploads files to S3 for Lambda deployment

#### Option 2: Local Files Only
```hcl
use_local_source = true
create_s3_bucket = false
```
- Deploys directly from local zip files
- No S3 bucket creation

#### Option 3: Existing S3 Sources
```hcl
use_local_source = false
lambda_code_s3_bucket = "existing-code-bucket"
lambda_layers_s3_bucket = "existing-layers-bucket"
```
- Uses existing S3 buckets
- Expects zip files already uploaded

## Key Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `environment` | Environment (dev/int/prod) | Required |
| `vpc_name` | VPC name tag | Required |
| `subnet_names` | List of subnet name tags | Required |
| `security_group_names` | List of security group name tags | Required |
| `use_local_source` | Use local files vs S3 | `true` |
| `create_s3_bucket` | Create S3 bucket for uploads | `true` |
| `lambda_layer_mappings` | Function to layer mappings | `{}` |
| `use_secrets_manager` | Use AWS Secrets Manager for RDS password | `true` |
| `postgres_password` | RDS password (only if secrets manager disabled) | `""` |
| `deploy_database` | Whether to deploy RDS database | `true` |

## Outputs

The deployment provides comprehensive outputs:

- **Lambda Functions**: ARNs, names, and configuration details
- **Lambda Layers**: Layer ARNs and versions
- **CloudWatch Log Groups**: Log group names and ARNs
- **S3 Bucket**: Bucket information (if created)
- **IAM Role**: Execution role details
- **VPC Configuration**: Network configuration used
- **RDS Database**: Connection information and instance details
- **Secrets Manager**: Secret ARNs for database credentials
- **ECR Repositories**: Container registry URLs
- **EC2 Instance**: Instance details and connection information

## Best Practices

1. **Security First**: Always use `use_secrets_manager = true` for production deployments
2. **IAM Role Naming**: Follow the `HCL-User-Role-insightgen-servicename` naming convention for all IAM roles
3. **Layer Organization**: Group related dependencies in layers (e.g., data processing, API clients)
4. **Function Naming**: Use descriptive names for zip files as they become function names
5. **Environment Separation**: Use separate AWS accounts or regions for different environments
6. **Tagging**: Leverage the global tagging strategy for cost allocation and resource management
7. **Network Security**: Deploy resources in private subnets with restrictive security groups
8. **Encryption**: Enable encryption for all data at rest and in transit
9. **Access Control**: Use IAM roles with least privilege principles
10. **Monitoring**: Enable CloudWatch logging and monitoring for all resources
11. **Backup Strategy**: Configure appropriate backup retention periods for production

## Troubleshooting

### Common Issues

1. **VPC/Subnet Not Found**: Verify the name tags match exactly
2. **Zip File Not Found**: Ensure zip files exist in the specified directories
3. **Layer Not Attached**: Check that layer names in mappings match actual layer file names
4. **Permission Denied**: Verify AWS credentials and IAM permissions
5. **Database Connection Failed**: Check if Lambda has Secrets Manager permissions
6. **Secret Not Found**: Verify RDS instance was created with managed password enabled

### Debugging

```bash
# Check Terraform plan
terraform plan -detailed-exitcode

# Validate configuration
terraform validate

# Check AWS resources
aws lambda list-functions --query 'Functions[?starts_with(FunctionName, `dev-insightgen-`)]'

# Check RDS instances
aws rds describe-db-instances --query 'DBInstances[?starts_with(DBInstanceIdentifier, `dev-insightgen-`)]'

# Check Secrets Manager secrets
aws secretsmanager list-secrets --query 'SecretList[?starts_with(Name, `dev-insightgen-`)]'

# Test database connectivity (from Lambda)
aws lambda invoke --function-name dev-insightgen-db-restore response.json
```

## Customization

### Adding Custom IAM Policies

Extend the IAM policy in `data.tf`:

```hcl
data "aws_iam_policy_document" "lambda_execution_policy" {
  # Existing statements...
  
  statement {
    effect = "Allow"
    actions = ["s3:GetObject", "s3:PutObject"]
    resources = ["arn:aws:s3:::your-bucket/*"]
  }
}
```

### Environment Variables

Customize per-function environment variables in `lambda-functions.tf`:

```hcl
environment {
  variables = {
    ENVIRONMENT = var.environment
    PROJECT     = var.project_name
    FUNCTION    = each.value
    # Add custom variables here
    DATABASE_URL = var.database_url
  }
}
```

## Contributing

1. Follow Terraform best practices
2. Update documentation for any new features
3. Test with multiple environments
4. Ensure backward compatibility

## License

This project is licensed under the MIT License - see the LICENSE file for details.
