# 🏢 IFRS InsightGen - AWS Infrastructure

> **Enterprise-grade Terraform infrastructure for IFRS financial reporting and analytics**

## 🎯 **What This Project Does**

**IFRS InsightGen** deploys a complete AWS infrastructure for **International Financial Reporting Standards (IFRS)** applications, providing:

- **📊 Financial Data Processing** via serverless Lambda functions
- **🌐 Web Application** with Angular UI hosted on EC2
- **🗄️ PostgreSQL Database** for financial data storage
- **📈 Real-time Analytics** through SNS event processing
- **🔒 Secure Document Storage** in S3 buckets
- **📱 Container Support** via ECR repositories

## 🏗️ **Architecture**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Users/Web     │    │   Application   │    │   Data Layer    │
│                 │    │     Layer       │    │                 │
│  ┌───────────┐  │    │  ┌───────────┐  │    │  ┌───────────┐  │
│  │ Angular   │  │◄──►│  │  Lambda   │  │◄──►│  │PostgreSQL │  │
│  │    UI     │  │    │  │Functions  │  │    │  │ Database  │  │
│  │   (EC2)   │  │    │  │           │  │    │  │   (RDS)   │  │
│  └───────────┘  │    │  └───────────┘  │    │  └───────────┘  │
│                 │    │       │         │    │                 │
│  ┌───────────┐  │    │  ┌───────────┐  │    │  ┌───────────┐  │
│  │Container  │  │    │  │   SNS     │  │    │  │    S3     │  │
│  │Images     │  │    │  │ Topics    │  │    │  │ Buckets   │  │
│  │  (ECR)    │  │    │  │           │  │    │  │           │  │
│  └───────────┘  │    │  └───────────┘  │    │  └───────────┘  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📁 **Project Structure**

```
terraform-aws-infra/
├── environments/                    # 🎯 Environment-specific configurations
│   ├── dev/main.tf                 # Development environment
│   ├── staging/main.tf             # Staging environment  
│   └── prod/main.tf                # Production environment
│
├── modules/                         # 🧩 Reusable infrastructure modules
│   ├── lambda/                     # Lambda functions & layers
│   ├── ec2/                        # EC2 instances
│   ├── rds/                        # PostgreSQL database
│   ├── ecr/                        # Container registries
│   ├── s3/                         # S3 buckets
│   └── sns/                        # SNS topics
│
├── global/                          # 🌐 Shared global resources
│   ├── iam/                        # IAM roles and policies
│   ├── networking/                 # VPC data sources
│   ├── monitoring/                 # CloudWatch & alerts
│   └── s3-backend/                 # Terraform state management
│
├── scripts/                         # 🔧 Automation scripts
├── docs/                           # 📚 Documentation
├── backend/                        # 🐍 Application code
├── database/                       # 🗄️ Database files
└── ui/                             # 🅰️ Angular UI code
```

## 🚀 **Quick Start**

### **Prerequisites:**
- AWS CLI configured with appropriate permissions
- Terraform >= 1.0 installed
- Existing VPC, subnets, and security groups

### **1. Deploy Development Environment:**
```bash
cd environments/dev
terraform init
terraform plan
terraform apply
```

### **2. Configure Your Settings:**
Edit `terraform.tfvars` in each environment:
```hcl
# Basic Configuration
aws_region         = "us-east-1"
project_name       = "IFRS-InsightGen"
iam_role_prefix    = "YourCompany-User-Role"
project_short_name = "ifrs-app"

# Network Configuration (existing resources)
vpc_name               = "your-existing-vpc"
subnet_names           = ["private-subnet-1", "private-subnet-2"]
public_subnet_names    = ["public-subnet-1"]
security_group_names   = ["app-security-group"]
```

### **3. Deploy Other Environments:**
```bash
# Staging
cd environments/staging
terraform init && terraform apply

# Production  
cd environments/prod
terraform init && terraform apply
```

## 🌍 **Multi-Environment Support**

| Environment | Instance Size | Database | Backup Retention | Features |
|-------------|---------------|----------|------------------|----------|
| **Dev** | t3.micro | db.t3.micro | 7 days | Cost-optimized, local sources |
| **Staging** | t3.small | db.t3.small | 14 days | Production-like, S3 sources |
| **Production** | t3.medium | db.t3.medium | 30 days | High-availability, full security |

## 🔒 **Security Features**

### **IAM Role Naming:**
All IAM roles follow a configurable pattern:
```
${iam_role_prefix}-${project_short_name}-service-name
```

**Examples:**
- `HCL-User-Role-insightgen-lambda-execution`
- `HCL-User-Role-insightgen-ec2-ui`
- `HCL-User-Role-insightgen-rds-monitoring`

### **Network Security:**
- **VPC Isolation**: All resources in secure VPC
- **Private Subnets**: Database and sensitive components isolated
- **Security Groups**: Restrictive firewall rules
- **Secrets Manager**: Secure credential management

## 📊 **What Gets Deployed**

### **Lambda Functions:**
- **alb-lambda**: Application load balancer handler
- **sns-lambda**: Event processing for financial data
- **Runtime**: Python 3.12 with VPC access

### **Web Application:**
- **Frontend**: Angular UI on EC2
- **Container Registry**: ECR for Docker images
- **Load Balancing**: Application Load Balancer

### **Database:**
- **Engine**: PostgreSQL 15.4 on RDS
- **Features**: Automated backups, encryption, monitoring
- **Access**: VPC-only with Secrets Manager

### **Storage & Messaging:**
- **S3 Buckets**: Code, assets, and document storage
- **SNS Topics**: Real-time event processing
- **CloudWatch**: Comprehensive monitoring and logging

## 🛠️ **Automation Scripts**

```bash
# Complete infrastructure setup
./scripts/setup.sh

# Validate all configurations
./scripts/validate.sh

# Plan and apply changes
./scripts/plan_apply.sh dev apply

# Cleanup resources
./scripts/cleanup.sh temp-files
```

## 📈 **Monitoring & Operations**

### **CloudWatch Integration:**
- **Dashboards**: System overview and performance metrics
- **Alarms**: Automated alerting for critical issues
- **Logs**: Centralized logging for all components

### **Operational Features:**
- **Auto Backup**: Automated database backups
- **Performance Monitoring**: RDS and Lambda metrics
- **Error Alerting**: SNS notifications for failures
- **Audit Logging**: Complete audit trail

## 📚 **Documentation**

- **[GETTING_STARTED.md](GETTING_STARTED.md)**: Step-by-step deployment guide
- **[PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md)**: Comprehensive project documentation
- **[DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md)**: Complete project status and structure
- **[docs/](docs/)**: Additional technical documentation

## 🎯 **Business Value**

### **For Financial Teams:**
- **📈 IFRS Compliance**: Automated compliance reporting
- **⚡ Real-time Insights**: Live financial data processing
- **📋 Standardized Reports**: Consistent IFRS report generation

### **For IT Teams:**
- **🏗️ Scalable Architecture**: Auto-scaling based on demand
- **🔒 Security First**: Enterprise-grade security controls
- **📊 Monitoring**: Comprehensive logging and alerting

### **For Business:**
- **💰 Cost Effective**: Pay-as-you-use serverless components
- **⚡ High Performance**: Optimized for financial workloads
- **🌐 Global Ready**: Multi-region deployment capable

## 🔧 **Customization**

The infrastructure is highly configurable:

- **🏷️ Naming**: Customize all resource names and tags
- **📏 Sizing**: Adjust instance sizes per environment
- **🌐 Networking**: Use your existing VPC and subnets
- **🔒 Security**: Configure your IAM roles and policies
- **📊 Monitoring**: Enable/disable monitoring features

---

**🎉 IFRS InsightGen provides a complete, secure, and scalable AWS infrastructure for financial reporting and analytics applications!**

For detailed information, see **[PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md)**
