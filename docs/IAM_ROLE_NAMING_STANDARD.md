# IAM Role Naming Standard Implementation

## 🎯 **Naming Convention Applied**

All IAM roles in this Terraform project now follow the standardized naming pattern:
```
HCL-User-Role-insightgen-servicename
```

Where:
- **HCL-User-Role**: Fixed prefix for all roles
- **insightgen**: Project name
- **servicename**: Specific service identifier

## ✅ **Updated IAM Roles**

### **Backend Module (`modules/backend/iam.tf`)**
| Old Name | New Name | Service |
|----------|----------|---------|  
| `${local.lambda_name_prefix}execution-role` | `HCL-User-Role-insightgen-lambda-execution` | Lambda Functions |

**Purpose**: IAM role for Lambda function execution with VPC access and CloudWatch logging permissions.

### **RDS Module (`modules/rds/main.tf`)**
| Old Name | New Name | Service |
|----------|----------|---------|  
| `${local.resource_name_prefix}-rds-monitoring-role` | `HCL-User-Role-insightgen-rds-monitoring` | RDS Enhanced Monitoring |
| `${local.resource_name_prefix}-db-restore-lambda-role` | `HCL-User-Role-insightgen-db-restore-lambda` | Database Restore Lambda |

**Purposes**:
- **RDS Monitoring**: Enhanced monitoring role for RDS performance insights
- **DB Restore Lambda**: Lambda function for database backup restoration from S3

### **EC2 Module (`modules/ec2/main.tf`)**
| Old Name | New Name | Service |
|----------|----------|---------|  
| `${local.env_prefix}${var.project_name}-ui-ec2-role` | `HCL-User-Role-insightgen-ec2-ui` | EC2 UI Hosting |

**Purpose**: IAM role for EC2 instance hosting the Angular UI application with ECR access permissions.

## 🔧 **Implementation Details**

### **Role Naming Pattern Breakdown**
```hcl
# Example: HCL-User-Role-insightgen-lambda-execution
#          ├─ HCL-User-Role ─┤├─ insightgen ─┤├─ lambda-execution ─┤
#          │    Fixed Prefix ││ Project Name ││   Service Name     │
#          └─────────────────┘└──────────────┘└────────────────────┘
```

### **Service Name Conventions**
- **lambda-execution**: Backend Lambda functions
- **rds-monitoring**: RDS enhanced monitoring
- **db-restore-lambda**: Database restoration Lambda
- **ec2-ui**: EC2 instance for UI hosting

### **Tag Updates**
All IAM roles now include consistent tagging:
```hcl
tags = merge(var.common_tags, {
  Name    = "HCL-User-Role-insightgen-servicename"
  Module  = "module_name"
  Service = "service_identifier"
})
```

## 📋 **Benefits of Standardization**

### **1. Consistent Naming**
- All roles follow the same pattern
- Easy to identify project resources
- Clear service identification

### **2. Improved Security**
- Standardized naming helps with IAM policy management
- Easier to audit and review permissions
- Clear ownership and purpose identification

### **3. Better Organization**
- Roles are easily searchable in AWS Console
- Consistent with enterprise naming standards
- Facilitates automated compliance checking

### **4. Operational Benefits**
- Simplified troubleshooting
- Easier role management and updates
- Clear documentation and maintenance

This standardization enhances security, improves operational efficiency, and ensures compliance with enterprise IAM naming conventions! 🔐✨
