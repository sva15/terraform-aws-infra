#!/bin/bash

# IFRS InsightGen Infrastructure Setup Script
# This script initializes the Terraform infrastructure for all environments

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

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform >= 1.0"
        exit 1
    fi
    
    # Check Terraform version
    TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
    print_status "Terraform version: $TERRAFORM_VERSION"
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install AWS CLI"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Please run 'aws configure'"
        exit 1
    fi
    
    print_status "Prerequisites check passed!"
}

# Initialize global resources
setup_global_resources() {
    print_header "Setting up Global Resources"
    
    # Setup S3 backend infrastructure first
    print_status "Creating S3 backends and DynamoDB tables..."
    cd global/s3-backend
    terraform init
    terraform plan -var="create_kms_key=true"
    read -p "Do you want to apply the S3 backend configuration? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        terraform apply -auto-approve -var="create_kms_key=true"
        print_status "S3 backends created successfully!"
    else
        print_warning "Skipping S3 backend creation"
    fi
    cd ../..
    
    # Setup global IAM resources
    print_status "Creating global IAM resources..."
    cd global/iam
    terraform init
    terraform plan
    read -p "Do you want to apply the IAM configuration? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        terraform apply -auto-approve
        print_status "Global IAM resources created successfully!"
    else
        print_warning "Skipping global IAM creation"
    fi
    cd ../..
    
    # Setup global networking
    print_status "Creating global networking resources..."
    cd global/networking
    terraform init
    terraform plan -var="create_prod_vpc=true"
    read -p "Do you want to apply the networking configuration? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        terraform apply -auto-approve -var="create_prod_vpc=true"
        print_status "Global networking resources created successfully!"
    else
        print_warning "Skipping global networking creation"
    fi
    cd ../..
    
    # Setup global monitoring
    print_status "Creating global monitoring resources..."
    cd global/monitoring
    terraform init
    terraform plan
    read -p "Do you want to apply the monitoring configuration? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        terraform apply -auto-approve
        print_status "Global monitoring resources created successfully!"
    else
        print_warning "Skipping global monitoring creation"
    fi
    cd ../..
}

# Initialize environment
setup_environment() {
    local env=$1
    print_header "Setting up $env Environment"
    
    cd "environments/$env"
    
    print_status "Initializing Terraform for $env environment..."
    terraform init
    
    print_status "Creating terraform.tfvars from template..."
    if [ ! -f terraform.tfvars ]; then
        cp terraform.tfvars terraform.tfvars.bak 2>/dev/null || true
        print_status "terraform.tfvars created for $env environment"
        print_warning "Please review and update terraform.tfvars with your specific values"
    else
        print_status "terraform.tfvars already exists for $env environment"
    fi
    
    print_status "Running terraform plan for $env environment..."
    terraform plan
    
    read -p "Do you want to apply the $env environment? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        terraform apply -auto-approve
        print_status "$env environment created successfully!"
    else
        print_warning "Skipping $env environment creation"
    fi
    
    cd ../..
}

# Main execution
main() {
    print_header "IFRS InsightGen Infrastructure Setup"
    
    # Check if we're in the right directory
    if [ ! -f "README.md" ] || [ ! -d "modules" ]; then
        print_error "Please run this script from the terraform project root directory"
        exit 1
    fi
    
    check_prerequisites
    
    # Ask which components to setup
    echo
    print_status "What would you like to setup?"
    echo "1) Global resources only"
    echo "2) Specific environment only"
    echo "3) All environments"
    echo "4) Complete setup (global + all environments)"
    read -p "Enter your choice (1-4): " -n 1 -r
    echo
    
    case $REPLY in
        1)
            setup_global_resources
            ;;
        2)
            echo "Available environments: dev, staging, prod"
            read -p "Enter environment name: " env
            if [ -d "environments/$env" ]; then
                setup_environment "$env"
            else
                print_error "Environment '$env' not found"
                exit 1
            fi
            ;;
        3)
            for env in dev staging prod; do
                setup_environment "$env"
            done
            ;;
        4)
            setup_global_resources
            for env in dev staging prod; do
                setup_environment "$env"
            done
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac
    
    print_header "Setup Complete!"
    print_status "Your IFRS InsightGen infrastructure is ready!"
    print_status "Next steps:"
    echo "  1. Review the created resources in AWS Console"
    echo "  2. Update any environment-specific configurations"
    echo "  3. Run 'terraform output' in each environment to see important information"
}

# Run main function
main "$@"
