# ✅ EC2 Architecture Compatibility Fix

## 🚨 **Issue Resolved**

**Error**: Architecture mismatch between EC2 instance type (`x86_64`) and AMI (`arm64`)

## 🔧 **Root Cause**

### **❌ Previous Configuration:**
```hcl
instance_type    = "t3.micro"     # x86_64 architecture
ami_name_pattern = "ubuntu/*"     # Could match arm64 AMIs
```

### **✅ Problem:**
- **t3.micro** instances use **x86_64** architecture
- **AMI filter** was too broad and selected an **arm64** Ubuntu AMI
- **Architecture mismatch** caused deployment failure

## 🔧 **Fixes Applied**

### **✅ 1. Updated EC2 Module - Added Architecture Filter:**
```hcl
# In modules/ec2/main.tf
data "aws_ami" "selected" {
  # ... existing filters ...
  
  filter {
    name   = "architecture"
    values = ["x86_64"]        # ← Added this filter
  }
}
```

### **✅ 2. Updated AMI Pattern - More Specific:**
```hcl
# In environments/dev/terraform.tfvars
ami_name_pattern = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
#                                                            ^^^^^ 
#                                                    Explicitly amd64 (x86_64)
```

## 📊 **Architecture Compatibility Matrix**

### **✅ x86_64 Instance Types:**
```hcl
# General Purpose
instance_type = "t3.micro"     # x86_64
instance_type = "t3.small"     # x86_64
instance_type = "t3.medium"    # x86_64
instance_type = "m5.large"     # x86_64

# AMI Pattern for x86_64:
ami_name_pattern = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
```

### **✅ ARM64 Instance Types (Alternative):**
```hcl
# Graviton-based (ARM64) - Often more cost-effective
instance_type = "t4g.micro"    # arm64
instance_type = "t4g.small"    # arm64
instance_type = "m6g.medium"   # arm64

# AMI Pattern for ARM64:
ami_name_pattern = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-*"
```

## 🎯 **Current Configuration**

### **✅ Development Environment:**
```hcl
# Guaranteed x86_64 compatibility
instance_type    = "t3.micro"
ami_owner        = "099720109477"  # Canonical (Ubuntu)
ami_name_pattern = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"

# EC2 module will filter for:
# - architecture = "x86_64"
# - virtualization-type = "hvm"
# - name matching the specific pattern
```

## 💡 **Alternative Configurations**

### **✅ Option 1: Stick with x86_64 (Current Fix):**
```hcl
instance_type    = "t3.micro"
ami_name_pattern = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
```

### **✅ Option 2: Switch to ARM64 (Cost-Effective):**
```hcl
instance_type    = "t4g.micro"    # ARM64 Graviton processor
ami_name_pattern = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-*"

# Would also need to update EC2 module filter:
filter {
  name   = "architecture"
  values = ["arm64"]
}
```

## 🔍 **AMI Selection Logic**

### **✅ How AMI is Selected:**
```hcl
data "aws_ami" "selected" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}
```

### **✅ Result:**
- **Selects**: Most recent Ubuntu 22.04 LTS AMI
- **Architecture**: x86_64 (amd64)
- **Virtualization**: HVM
- **Compatible with**: t3.micro, t3.small, m5.*, etc.

## 🚀 **Deployment**

### **✅ Test the Fix:**
```bash
cd environments/dev
terraform plan
# Should now show successful AMI selection with matching architecture
```

### **✅ Apply Changes:**
```bash
terraform apply
# EC2 instance should be created successfully
```

### **✅ Verify Instance:**
```bash
# Check instance details
aws ec2 describe-instances --filters "Name=tag:Name,Values=*ui-server*"

# Check AMI details
aws ec2 describe-images --image-ids ami-xxxxxxxxx
```

## 📋 **Best Practices**

### **✅ Always Specify Architecture:**
```hcl
# In AMI data source, always include architecture filter
filter {
  name   = "architecture"
  values = ["x86_64"]  # or ["arm64"] for Graviton
}
```

### **✅ Use Specific AMI Patterns:**
```hcl
# Specific pattern (recommended)
ami_name_pattern = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"

# Generic pattern (can cause issues)
ami_name_pattern = "ubuntu/*"  # Too broad, avoid this
```

### **✅ Match Instance Type and AMI:**
```hcl
# x86_64 instances + amd64 AMIs
instance_type = "t3.micro"
ami_pattern   = "*-amd64-server-*"

# ARM64 instances + arm64 AMIs  
instance_type = "t4g.micro"
ami_pattern   = "*-arm64-server-*"
```

## 🎉 **Summary**

### ✅ **Fixed Issues:**
- **Architecture filter** added to EC2 module
- **Specific AMI pattern** ensures x86_64 compatibility
- **Instance type and AMI** now have matching architectures

### ✅ **Current Setup:**
- **Instance**: t3.micro (x86_64)
- **AMI**: Ubuntu 22.04 LTS amd64
- **Compatibility**: Guaranteed match

### ✅ **Ready for Deployment:**
- **EC2 instance** will be created successfully
- **No architecture mismatch** errors
- **Consistent configuration** across environments

**🚀 EC2 architecture compatibility is now fixed and ready for deployment!**
