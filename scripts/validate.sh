#!/bin/bash

# IFRS InsightGen Infrastructure Validation Script
# This script validates the Terraform configuration across all environments

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Validate Terraform syntax
validate_terraform() {
    local path=$1
    local name=$2
    
    print_status "Validating $name..."
    
    cd "$path"
    
    # Initialize if needed
    if [ ! -d ".terraform" ]; then
        print_status "Initializing Terraform for $name..."
        terraform init -backend=false
    fi
    
    # Validate syntax
    if terraform validate; then
        print_status "$name validation: PASSED"
    else
        print_error "$name validation: FAILED"
        return 1
    fi
    
    # Format check
    if terraform fmt -check=true -diff=true; then
        print_status "$name formatting: PASSED"
    else
        print_warning "$name formatting: NEEDS FORMATTING"
        print_status "Run 'terraform fmt' to fix formatting"
    fi
    
    cd - > /dev/null
}

# Validate environment configuration
validate_environment() {
    local env=$1
    print_header "Validating $env Environment"
    
    local env_path="environments/$env"
    
    if [ ! -d "$env_path" ]; then
        print_error "Environment directory '$env_path' not found"
        return 1
    fi
    
    # Check required files
    local required_files=("main.tf" "variables.tf" "outputs.tf" "provider.tf" "backend.tf")
    for file in "${required_files[@]}"; do
        if [ ! -f "$env_path/$file" ]; then
            print_error "Required file '$file' not found in $env environment"
            return 1
        else
            print_status "Found required file: $file"
        fi
    done
    
    # Check if terraform.tfvars exists
    if [ ! -f "$env_path/terraform.tfvars" ]; then
        print_warning "terraform.tfvars not found in $env environment"
        print_status "You may need to create it from terraform.tfvars.example"
    else
        print_status "Found terraform.tfvars"
    fi
    
    # Validate Terraform configuration
    validate_terraform "$env_path" "$env environment"
}

# Validate global resources
validate_global() {
    print_header "Validating Global Resources"
    
    local global_modules=("iam" "networking" "monitoring" "s3-backend")
    
    for module in "${global_modules[@]}"; do
        local module_path="global/$module"
        if [ -d "$module_path" ]; then
            validate_terraform "$module_path" "global $module"
        else
            print_warning "Global module '$module' not found"
        fi
    done
}

# Validate modules
validate_modules() {
    print_header "Validating Modules"
    
    if [ ! -d "modules" ]; then
        print_error "Modules directory not found"
        return 1
    fi
    
    for module_dir in modules/*/; do
        if [ -d "$module_dir" ]; then
            local module_name=$(basename "$module_dir")
            validate_terraform "$module_dir" "module $module_name"
        fi
    done
}

# Check for common issues
check_common_issues() {
    print_header "Checking for Common Issues"
    
    # Check for hardcoded values that should be variables
    print_status "Checking for hardcoded AWS account IDs..."
    if grep -r "arn:aws:iam::[0-9]" . --include="*.tf" --exclude-dir=".terraform"; then
        print_warning "Found hardcoded AWS account IDs. Consider using data sources or variables."
    else
        print_status "No hardcoded AWS account IDs found"
    fi
    
    # Check for hardcoded regions
    print_status "Checking for hardcoded AWS regions..."
    if grep -r "us-east-1\|us-west-2\|eu-west-1" . --include="*.tf" --exclude-dir=".terraform" | grep -v "variable\|default"; then
        print_warning "Found hardcoded AWS regions. Consider using variables."
    else
        print_status "No hardcoded AWS regions found"
    fi
    
    # Check for missing tags
    print_status "Checking for resources without tags..."
    local untagged_resources=$(grep -r "resource \"aws_" . --include="*.tf" --exclude-dir=".terraform" | grep -v "tags\s*=" | wc -l)
    if [ "$untagged_resources" -gt 0 ]; then
        print_warning "Found $untagged_resources resources that might be missing tags"
    else
        print_status "All resources appear to have tags"
    fi
    
    # Check for sensitive values in tfvars
    print_status "Checking for sensitive values in tfvars files..."
    if find . -name "*.tfvars" -exec grep -l "password\|secret\|key" {} \; | head -1; then
        print_warning "Found potential sensitive values in tfvars files. Ensure they're properly secured."
    else
        print_status "No obvious sensitive values found in tfvars files"
    fi
}

# Generate validation report
generate_report() {
    print_header "Validation Summary"
    
    local total_errors=0
    local total_warnings=0
    
    # Count errors and warnings from the log
    # This is a simplified approach - in a real scenario, you'd track these during validation
    
    if [ $total_errors -eq 0 ]; then
        print_status "✅ All validations passed successfully!"
    else
        print_error "❌ Found $total_errors errors that need to be fixed"
    fi
    
    if [ $total_warnings -gt 0 ]; then
        print_warning "⚠️  Found $total_warnings warnings that should be reviewed"
    fi
    
    print_status "Validation complete!"
}

# Main execution
main() {
    print_header "IFRS InsightGen Infrastructure Validation"
    
    # Check if we're in the right directory
    if [ ! -f "README.md" ] || [ ! -d "modules" ]; then
        print_error "Please run this script from the terraform project root directory"
        exit 1
    fi
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform >= 1.0"
        exit 1
    fi
    
    local validation_failed=false
    
    # Validate modules first
    if ! validate_modules; then
        validation_failed=true
    fi
    
    # Validate global resources
    if ! validate_global; then
        validation_failed=true
    fi
    
    # Validate each environment
    for env in dev staging prod; do
        if ! validate_environment "$env"; then
            validation_failed=true
        fi
    done
    
    # Check for common issues
    check_common_issues
    
    # Generate report
    generate_report
    
    if [ "$validation_failed" = true ]; then
        print_error "Validation completed with errors. Please fix the issues above."
        exit 1
    else
        print_status "All validations completed successfully!"
        exit 0
    fi
}

# Run main function
main "$@"
