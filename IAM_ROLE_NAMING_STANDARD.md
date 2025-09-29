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

## 🔍 **Role Permissions Summary**

### **Lambda Execution Role**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream", 
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:AttachNetworkInterface",
        "ec2:DetachNetworkInterface"
      ],
      "Resource": "*"
    }
  ]
}
```

### **RDS Monitoring Role**
- **Managed Policy**: `AmazonRDSEnhancedMonitoringRole`
- **Purpose**: Enhanced monitoring for RDS instances
- **Service**: `monitoring.rds.amazonaws.com`

### **DB Restore Lambda Role**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": ["${secret_arn}"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": ["${s3_bucket_arn}/*"]
    }
  ]
}
```

### **EC2 UI Role**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ],
      "Resource": "*"
    }
  ]
}
```

## 🚀 **Deployment Impact**

### **What Changed**
- ✅ IAM role names updated to follow standard
- ✅ Role tags updated with service identifiers
- ✅ Documentation updated with new naming convention
- ✅ No functional changes to permissions or policies

### **What Stays the Same**
- ✅ All role permissions remain identical
- ✅ Policy attachments unchanged
- ✅ Service functionality unaffected
- ✅ Existing deployments continue to work

### **Migration Notes**
- **New Deployments**: Will use the new naming convention automatically
- **Existing Deployments**: Will update role names on next `terraform apply`
- **No Downtime**: Role updates are handled gracefully by Terraform
- **Rollback**: Can be reverted by changing role names back if needed

## 📚 **Documentation Updates**

### **README.md Changes**
- ✅ Added IAM Role Naming Convention section
- ✅ Updated Security Features section
- ✅ Added naming standard to Best Practices
- ✅ Updated Infrastructure overview

### **Best Practices**
- ✅ IAM role naming is now #2 in best practices list
- ✅ Clear examples provided for each service type
- ✅ Integration with existing security practices

## 🎉 **Compliance Achievement**

The project now fully complies with the requested naming standard:
- **✅ Pattern**: `HCL-User-Role-Projectname-servicename`
- **✅ Project Name**: `insightgen`
- **✅ Service Names**: Descriptive and consistent
- **✅ All Modules**: Backend, RDS, EC2 updated
- **✅ Documentation**: Complete and up-to-date

This standardization enhances security, improves operational efficiency, and ensures compliance with enterprise IAM naming conventions! 🔐✨
