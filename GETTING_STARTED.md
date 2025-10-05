# 🚀 Getting Started with IFRS InsightGen

## 📋 **Prerequisites Checklist**

Before deploying, ensure you have:

- [ ] **AWS CLI** configured with appropriate permissions
- [ ] **Terraform >= 1.0** installed
- [ ] **Existing AWS Infrastructure**:
  - [ ] VPC with appropriate name tag
  - [ ] Private subnets for Lambda functions and RDS
  - [ ] Public subnets for EC2 instances
  - [ ] Security groups with appropriate name tags

## 🎯 **Quick Deploy - Development Environment**

### **Step 1: Configure Your Environment**
```bash
cd environments/dev
```

Edit `terraform.tfvars` with your AWS resources:
```hcl
# Basic Configuration
aws_region         = "us-east-1"
project_name       = "IFRS-InsightGen"
iam_role_prefix    = "YourCompany-User-Role"  # Customize this
project_short_name = "ifrs-app"               # Customize this

# Network Configuration (YOUR existing resources)
vpc_name               = "your-existing-vpc-name"
subnet_names           = ["your-private-subnet-1", "your-private-subnet-2"]
public_subnet_names    = ["your-public-subnet-1"]
security_group_names   = ["your-app-security-group"]

# Lambda Configuration
lambda_prefix            = "dev-ifrs"
use_local_source         = true
lambda_code_local_path   = "../../backend/python-aws-lambda-functions"
lambda_layers_local_path = "../../backend/lambda-layers"

# Database Configuration
postgres_db_name     = "ifrs_db"
postgres_password    = "SecurePassword123!"  # Or use Secrets Manager
use_secrets_manager  = true                  # Recommended
deploy_database      = true

# UI Configuration
ui_s3_bucket = "your-ui-assets-bucket"  # Optional
BASE_URL     = "https://your-domain.com"
```

### **Step 2: Deploy Infrastructure**
```bash
# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan

# Deploy the infrastructure
terraform apply
```

### **Step 3: Verify Deployment**
```bash
# Check outputs
terraform output

# View quick access information
terraform output quick_access
```

## 🏗️ **What Gets Created**

After successful deployment, you'll have:

### **✅ Lambda Functions:**
- `dev-ifrs-alb-lambda` - Application load balancer handler
- `dev-ifrs-sns-lambda` - Event processing function

### **✅ Database:**
- RDS PostgreSQL instance with automated backups
- Secrets Manager integration (if enabled)
- Enhanced monitoring

### **✅ Web Infrastructure:**
- EC2 instance for hosting Angular UI
- ECR repositories for container images
- Application Load Balancer

### **✅ Storage & Messaging:**
- S3 buckets for code and assets
- SNS topics for event processing
- CloudWatch logs and monitoring

## 🔧 **Post-Deployment Steps**

### **1. Build and Deploy UI Application:**
```bash
# Get ECR repository URL from Terraform outputs
ECR_URL=$(terraform output -raw ecr_info | jq -r '.repository_urls["ui-app"]')

# Build and push your Angular application
cd ../../ui
docker build -t ifrs-ui .
docker tag ifrs-ui:latest $ECR_URL:latest
docker push $ECR_URL:latest
```

### **2. Deploy Lambda Functions:**
Your Lambda functions are automatically deployed from the `backend/` directory.

### **3. Configure Database:**
If you have database initialization scripts:
```bash
# Connect to your RDS instance and run initialization scripts
# Database endpoint is available in Terraform outputs
```

## 🌍 **Deploy to Other Environments**

### **Staging Environment:**
```bash
cd ../staging

# Edit terraform.tfvars for staging-specific settings
# Then deploy
terraform init
terraform apply
```

### **Production Environment:**
```bash
cd ../prod

# Edit terraform.tfvars for production-specific settings
# Review security settings carefully
terraform init
terraform apply
```

## 🔍 **Troubleshooting**

### **Common Issues:**

#### **1. VPC/Subnet Not Found:**
```
Error: No VPC found with name: your-vpc-name
```
**Solution**: Update `vpc_name` in `terraform.tfvars` to match your actual VPC name tag.

#### **2. Security Group Not Found:**
```
Error: No security groups found with names: [your-sg-name]
```
**Solution**: Update `security_group_names` in `terraform.tfvars` to match your actual security group name tags.

#### **3. Lambda Function Deployment Failed:**
```
Error: Error creating Lambda function
```
**Solution**: Ensure your Lambda function zip files exist in `backend/python-aws-lambda-functions/`

### **Verification Commands:**
```bash
# Check AWS resources exist
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=your-vpc-name"
aws ec2 describe-subnets --filters "Name=tag:Name,Values=your-subnet-name"
aws ec2 describe-security-groups --filters "Name=tag:Name,Values=your-sg-name"

# Check Terraform state
terraform state list
terraform show
```

## 📊 **Monitoring Your Deployment**

### **CloudWatch Dashboards:**
- Navigate to AWS CloudWatch Console
- View custom dashboards created for your application
- Monitor Lambda function metrics, RDS performance, EC2 health

### **Application Logs:**
```bash
# View Lambda function logs
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/dev-ifrs"

# View EC2 instance logs (SSH to instance)
sudo journalctl -u your-application-service
```

## 🎯 **Next Steps**

1. **Customize Configuration**: Adjust instance sizes, backup policies, monitoring settings
2. **Set Up CI/CD**: Integrate with your deployment pipeline
3. **Configure Monitoring**: Set up custom CloudWatch alarms and SNS notifications
4. **Security Review**: Review IAM policies, security groups, and encryption settings
5. **Performance Tuning**: Optimize Lambda memory, RDS instance class, EC2 instance type

## 📚 **Additional Resources**

- **[PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md)**: Comprehensive project documentation
- **[docs/](docs/)**: Detailed technical documentation
- **[scripts/](scripts/)**: Automation scripts for common tasks

## 🆘 **Need Help?**

If you encounter issues:

1. **Check Terraform logs**: `terraform apply` output shows detailed error messages
2. **Verify AWS permissions**: Ensure your AWS credentials have necessary permissions
3. **Review configuration**: Double-check all values in `terraform.tfvars`
4. **Check AWS Console**: Verify resources are created as expected

---

**🎉 You're ready to deploy IFRS InsightGen! Start with the development environment and work your way up to production.**
