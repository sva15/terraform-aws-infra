# 🏢 IFRS InsightGen - AWS Infrastructure Project

## 🎯 **What This Project Does**

**IFRS InsightGen** is a comprehensive AWS-based application infrastructure that provides **International Financial Reporting Standards (IFRS) insights and analytics**. This Terraform project deploys a complete cloud infrastructure to support a financial reporting application with the following capabilities:

### **🔍 Core Functionality:**
- **📊 Financial Data Processing**: Lambda functions process IFRS financial data
- **🌐 Web Application**: Angular-based UI hosted on EC2 for user interaction
- **🗄️ Database Management**: PostgreSQL database for storing financial records
- **📈 Real-time Analytics**: SNS-driven event processing for financial insights
- **🔒 Secure Storage**: S3 buckets for financial documents and reports
- **📱 Container Support**: ECR repositories for containerized applications

## 🏗️ **Architecture Overview**

```
┌─────────────────────────────────────────────────────────────────┐
│                        IFRS InsightGen                         │
│                     AWS Infrastructure                         │
└─────────────────────────────────────────────────────────────────┘

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

## 🚀 **What Gets Deployed**

### **💻 Application Components:**

#### **1. Lambda Functions (Serverless Processing)**
- **`alb-lambda`**: Handles application load balancer requests
- **`sns-lambda`**: Processes SNS events for financial data
- **Purpose**: Serverless processing of IFRS financial calculations
- **Runtime**: Python 3.12
- **Features**: VPC access, CloudWatch logging, SNS integration

#### **2. Web Application (EC2 + Angular)**
- **Frontend**: Angular-based web application
- **Hosting**: EC2 instance with auto-scaling capabilities
- **Purpose**: User interface for IFRS data visualization and reporting
- **Features**: Responsive design, real-time dashboards

#### **3. Database (PostgreSQL on RDS)**
- **Engine**: PostgreSQL 15.4
- **Purpose**: Store IFRS financial data, user accounts, reports
- **Features**: Automated backups, encryption, monitoring
- **Access**: Secure VPC-only access with secrets management

#### **4. Container Registry (ECR)**
- **Repositories**: Store Docker images for applications
- **Purpose**: Version control for containerized applications
- **Integration**: Used by EC2 for application deployment

#### **5. Storage (S3 Buckets)**
- **Lambda Code**: Store function deployment packages
- **UI Assets**: Static web assets and resources
- **Reports**: Generated IFRS reports and documents
- **Backups**: Database backup storage

#### **6. Messaging (SNS Topics)**
- **Event Processing**: Real-time financial data events
- **Notifications**: System alerts and user notifications
- **Integration**: Triggers Lambda functions for data processing

### **🔒 Security & Compliance:**

#### **IAM Roles & Policies:**
- **Lambda Execution Role**: `HCL-User-Role-insightgen-lambda-execution`
- **EC2 Instance Role**: `HCL-User-Role-insightgen-ec2-ui`
- **RDS Monitoring Role**: `HCL-User-Role-insightgen-rds-monitoring`
- **Principle**: Least privilege access for all components

#### **Network Security:**
- **VPC Isolation**: All resources deployed in secure VPC
- **Security Groups**: Restrictive firewall rules
- **Private Subnets**: Database and sensitive components isolated
- **Encryption**: Data encrypted at rest and in transit

#### **Secrets Management:**
- **AWS Secrets Manager**: Database credentials
- **KMS Encryption**: Sensitive data encryption
- **No Hardcoded Secrets**: All secrets managed securely

## 🌍 **Multi-Environment Support**

### **Environment Separation:**
```
environments/
├── dev/          # Development environment
│   ├── Small instances (t3.micro)
│   ├── Local source code
│   ├── Relaxed security for testing
│   └── Cost-optimized settings
│
├── staging/      # Pre-production testing
│   ├── Production-like setup
│   ├── S3-based deployments
│   ├── Enhanced monitoring
│   └── Integration testing
│
└── prod/         # Production environment
    ├── High-availability setup
    ├── Enhanced security
    ├── Automated backups
    └── Full monitoring & alerting
```

### **Environment-Specific Features:**

| Feature | Dev | Staging | Production |
|---------|-----|---------|------------|
| **Instance Size** | t3.micro | t3.small | t3.medium |
| **Database** | db.t3.micro | db.t3.small | db.t3.medium |
| **Backup Retention** | 7 days | 14 days | 30 days |
| **Deletion Protection** | ❌ | ✅ | ✅ |
| **Monitoring** | Basic | Enhanced | Full |
| **Encryption** | Standard | Enhanced | Full KMS |

## 📊 **Business Value**

### **For Financial Teams:**
- **📈 IFRS Compliance**: Automated compliance reporting
- **⚡ Real-time Insights**: Live financial data processing
- **📋 Standardized Reports**: Consistent IFRS report generation
- **🔍 Data Analytics**: Advanced financial data analysis

### **For IT Teams:**
- **🏗️ Scalable Architecture**: Auto-scaling based on demand
- **🔒 Security First**: Enterprise-grade security controls
- **📊 Monitoring**: Comprehensive logging and alerting
- **🚀 DevOps Ready**: Infrastructure as Code with Terraform

### **For Business:**
- **💰 Cost Effective**: Pay-as-you-use serverless components
- **⚡ High Performance**: Optimized for financial workloads
- **🌐 Global Ready**: Multi-region deployment capable
- **📱 Modern UI**: Responsive web application

## 🛠️ **Technology Stack**

### **Infrastructure:**
- **☁️ AWS Cloud**: Complete AWS-native architecture
- **🏗️ Terraform**: Infrastructure as Code
- **🔧 Serverless**: Lambda functions for processing
- **🗄️ Managed Database**: RDS PostgreSQL
- **📦 Containerization**: Docker + ECR

### **Application Stack:**
- **🐍 Backend**: Python Lambda functions
- **🅰️ Frontend**: Angular web application
- **🗄️ Database**: PostgreSQL with advanced features
- **📨 Messaging**: SNS for event-driven architecture
- **📊 Monitoring**: CloudWatch + SNS alerts

## 🚀 **Getting Started**

### **Prerequisites:**
- AWS CLI configured with appropriate permissions
- Terraform >= 1.0 installed
- Access to existing VPC and subnets

### **Quick Deploy:**

#### **1. Development Environment:**
```bash
cd environments/dev
terraform init
terraform plan
terraform apply
```

#### **2. Configure Your Settings:**
Edit `terraform.tfvars` in each environment:
```hcl
# Your AWS Configuration
aws_region = "us-east-1"
project_name = "IFRS-InsightGen"

# Your IAM Naming
iam_role_prefix = "YourCompany-User-Role"
project_short_name = "ifrs-app"

# Your Network (existing resources)
vpc_name = "your-existing-vpc"
subnet_names = ["your-private-subnet-1", "your-private-subnet-2"]
security_group_names = ["your-app-security-group"]
```

#### **3. Deploy Other Environments:**
```bash
# Staging
cd environments/staging
terraform init && terraform apply

# Production  
cd environments/prod
terraform init && terraform apply
```

## 📈 **Monitoring & Operations**

### **CloudWatch Integration:**
- **📊 Dashboards**: System overview and performance metrics
- **🚨 Alarms**: Automated alerting for critical issues
- **📝 Logs**: Centralized logging for all components
- **📈 Metrics**: Custom metrics for business KPIs

### **Operational Features:**
- **🔄 Auto Backup**: Automated database backups
- **📊 Performance Monitoring**: RDS and Lambda metrics
- **🚨 Error Alerting**: SNS notifications for failures
- **🔍 Audit Logging**: Complete audit trail

## 🎯 **Use Cases**

### **Financial Reporting:**
- Generate IFRS-compliant financial statements
- Automate quarterly and annual reporting
- Real-time financial dashboard and analytics
- Regulatory compliance monitoring

### **Data Processing:**
- Batch processing of financial transactions
- Real-time event processing via SNS
- Data validation and cleansing
- Financial calculations and aggregations

### **User Management:**
- Secure user authentication and authorization
- Role-based access control
- Audit trail for all user actions
- Multi-tenant support for different organizations

## 🔧 **Customization**

The infrastructure is highly configurable through variables:

- **🏷️ Naming**: Customize all resource names and tags
- **📏 Sizing**: Adjust instance sizes per environment
- **🌐 Networking**: Use your existing VPC and subnets
- **🔒 Security**: Configure your IAM roles and policies
- **📊 Monitoring**: Enable/disable monitoring features
- **💾 Storage**: Configure backup and retention policies

## 📚 **Documentation**

- **[IAM Role Naming Standard](docs/IAM_ROLE_NAMING_STANDARD.md)**: IAM naming conventions
- **[Migration Guide](docs/MIGRATION_GUIDE.md)**: How to migrate from old structure
- **[Project Review](docs/PROJECT_REVIEW_SUMMARY.md)**: Technical assessment
- **[Advanced Patterns](docs/TERRAFORM_ADVANCED_PATTERNS.md)**: Advanced Terraform techniques
- **[Learning Guide](docs/TERRAFORM_LEARNING_GUIDE.md)**: Terraform learning resources

---

**🎉 IFRS InsightGen provides a complete, secure, and scalable AWS infrastructure for financial reporting and analytics applications!**
