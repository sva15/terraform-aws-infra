#!/bin/bash

# IFRS InsightGen Infrastructure Plan and Apply Script
# This script helps plan and apply Terraform changes across environments

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

# Show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] ENVIRONMENT [ACTION]"
    echo ""
    echo "ENVIRONMENT:"
    echo "  dev         Development environment"
    echo "  staging     Staging environment"
    echo "  prod        Production environment"
    echo "  global      Global resources"
    echo ""
    echo "ACTION:"
    echo "  plan        Run terraform plan (default)"
    echo "  apply       Run terraform apply"
    echo "  destroy     Run terraform destroy"
    echo ""
    echo "OPTIONS:"
    echo "  -h, --help     Show this help message"
    echo "  -v, --verbose  Enable verbose output"
    echo "  -y, --yes      Auto-approve apply/destroy operations"
    echo "  --var-file     Specify additional tfvars file"
    echo ""
    echo "Examples:"
    echo "  $0 dev plan"
    echo "  $0 staging apply"
    echo "  $0 prod destroy"
    echo "  $0 global plan"
}

# Parse command line arguments
parse_args() {
    VERBOSE=false
    AUTO_APPROVE=false
    VAR_FILE=""
    ENVIRONMENT=""
    ACTION="plan"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -y|--yes)
                AUTO_APPROVE=true
                shift
                ;;
            --var-file)
                VAR_FILE="$2"
                shift 2
                ;;
            dev|staging|prod|global)
                ENVIRONMENT="$1"
                shift
                ;;
            plan|apply|destroy)
                ACTION="$1"
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    if [ -z "$ENVIRONMENT" ]; then
        print_error "Environment is required"
        show_usage
        exit 1
    fi
}

# Validate environment
validate_environment() {
    local env=$1
    
    if [ "$env" = "global" ]; then
        if [ ! -d "global" ]; then
            print_error "Global directory not found"
            exit 1
        fi
        return 0
    fi
    
    if [ ! -d "environments/$env" ]; then
        print_error "Environment '$env' not found"
        exit 1
    fi
    
    if [ ! -f "environments/$env/terraform.tfvars" ]; then
        print_error "terraform.tfvars not found for $env environment"
        print_status "Please create it from terraform.tfvars.example"
        exit 1
    fi
}

# Execute terraform command for environment
execute_terraform_env() {
    local env=$1
    local action=$2
    
    print_header "Executing $action for $env environment"
    
    cd "environments/$env"
    
    # Initialize if needed
    if [ ! -d ".terraform" ]; then
        print_status "Initializing Terraform..."
        terraform init
    fi
    
    # Build terraform command
    local tf_cmd="terraform $action"
    
    # Add var file if specified
    if [ -n "$VAR_FILE" ]; then
        tf_cmd="$tf_cmd -var-file=$VAR_FILE"
    fi
    
    # Add auto-approve for apply/destroy
    if [ "$action" = "apply" ] || [ "$action" = "destroy" ]; then
        if [ "$AUTO_APPROVE" = true ]; then
            tf_cmd="$tf_cmd -auto-approve"
        fi
    fi
    
    # Add verbose flag if requested
    if [ "$VERBOSE" = true ]; then
        tf_cmd="$tf_cmd -verbose"
    fi
    
    print_status "Running: $tf_cmd"
    
    # Execute the command
    if [ "$action" = "plan" ]; then
        eval "$tf_cmd -out=tfplan"
        print_status "Plan saved to tfplan"
    else
        eval "$tf_cmd"
    fi
    
    cd ../..
}

# Execute terraform command for global resources
execute_terraform_global() {
    local action=$1
    
    print_header "Executing $action for global resources"
    
    local global_modules=("s3-backend" "iam" "networking" "monitoring")
    
    for module in "${global_modules[@]}"; do
        if [ -d "global/$module" ]; then
            print_status "Processing global/$module..."
            cd "global/$module"
            
            # Initialize if needed
            if [ ! -d ".terraform" ]; then
                print_status "Initializing Terraform for $module..."
                terraform init
            fi
            
            # Build terraform command
            local tf_cmd="terraform $action"
            
            # Add auto-approve for apply/destroy
            if [ "$action" = "apply" ] || [ "$action" = "destroy" ]; then
                if [ "$AUTO_APPROVE" = true ]; then
                    tf_cmd="$tf_cmd -auto-approve"
                fi
            fi
            
            # Add verbose flag if requested
            if [ "$VERBOSE" = true ]; then
                tf_cmd="$tf_cmd -verbose"
            fi
            
            print_status "Running: $tf_cmd"
            
            # Execute the command
            if [ "$action" = "plan" ]; then
                eval "$tf_cmd -out=tfplan"
            else
                eval "$tf_cmd"
            fi
            
            cd ../..
        else
            print_warning "Global module '$module' not found, skipping..."
        fi
    done
}

# Confirm destructive actions
confirm_destructive_action() {
    local env=$1
    local action=$2
    
    if [ "$action" = "destroy" ] && [ "$AUTO_APPROVE" != true ]; then
        print_warning "You are about to DESTROY resources in $env environment!"
        print_warning "This action cannot be undone!"
        read -p "Are you absolutely sure? Type 'yes' to confirm: " -r
        if [ "$REPLY" != "yes" ]; then
            print_status "Operation cancelled"
            exit 0
        fi
    fi
    
    if [ "$action" = "apply" ] && [ "$env" = "prod" ] && [ "$AUTO_APPROVE" != true ]; then
        print_warning "You are about to apply changes to PRODUCTION environment!"
        read -p "Are you sure you want to continue? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Operation cancelled"
            exit 0
        fi
    fi
}

# Show plan summary
show_plan_summary() {
    local env=$1
    
    if [ "$ACTION" = "plan" ]; then
        print_header "Plan Summary for $env"
        print_status "Plan file saved. To apply these changes, run:"
        if [ "$env" = "global" ]; then
            print_status "$0 global apply"
        else
            print_status "$0 $env apply"
        fi
    fi
}

# Main execution
main() {
    print_header "IFRS InsightGen Infrastructure Management"
    
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
    
    # Parse arguments
    parse_args "$@"
    
    # Validate environment
    validate_environment "$ENVIRONMENT"
    
    # Confirm destructive actions
    confirm_destructive_action "$ENVIRONMENT" "$ACTION"
    
    # Execute terraform command
    if [ "$ENVIRONMENT" = "global" ]; then
        execute_terraform_global "$ACTION"
    else
        execute_terraform_env "$ENVIRONMENT" "$ACTION"
    fi
    
    # Show summary
    show_plan_summary "$ENVIRONMENT"
    
    print_status "Operation completed successfully!"
}

# Run main function
main "$@"
