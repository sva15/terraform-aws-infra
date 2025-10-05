#!/bin/bash

# IFRS InsightGen Infrastructure Cleanup Script
# This script helps clean up Terraform resources and state files

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
    echo "Usage: $0 [OPTIONS] [ACTION]"
    echo ""
    echo "ACTION:"
    echo "  temp-files     Clean temporary files (.terraform, tfplan, etc.)"
    echo "  state-backup   Clean state backup files"
    echo "  all-files      Clean all temporary and backup files"
    echo "  destroy-all    Destroy all infrastructure (DANGEROUS!)"
    echo ""
    echo "OPTIONS:"
    echo "  -h, --help     Show this help message"
    echo "  -v, --verbose  Enable verbose output"
    echo "  -y, --yes      Auto-approve cleanup operations"
    echo "  --dry-run      Show what would be cleaned without actually doing it"
    echo ""
    echo "Examples:"
    echo "  $0 temp-files"
    echo "  $0 --dry-run all-files"
    echo "  $0 -y state-backup"
}

# Parse command line arguments
parse_args() {
    VERBOSE=false
    AUTO_APPROVE=false
    DRY_RUN=false
    ACTION="temp-files"
    
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
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            temp-files|state-backup|all-files|destroy-all)
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
}

# Clean temporary files
clean_temp_files() {
    print_header "Cleaning Temporary Files"
    
    local files_to_clean=(
        ".terraform"
        "tfplan"
        "*.tfplan"
        ".terraform.lock.hcl"
        "terraform.tfstate.d"
        "crash.log"
        "*.log"
    )
    
    for pattern in "${files_to_clean[@]}"; do
        print_status "Looking for: $pattern"
        
        if [ "$DRY_RUN" = true ]; then
            find . -name "$pattern" -type f -o -name "$pattern" -type d | while read -r file; do
                echo "Would remove: $file"
            done
        else
            find . -name "$pattern" -type f -delete 2>/dev/null || true
            find . -name "$pattern" -type d -exec rm -rf {} + 2>/dev/null || true
        fi
    done
    
    if [ "$DRY_RUN" != true ]; then
        print_status "Temporary files cleaned"
    fi
}

# Clean state backup files
clean_state_backups() {
    print_header "Cleaning State Backup Files"
    
    local backup_patterns=(
        "terraform.tfstate.backup"
        "*.tfstate.backup"
        "terraform.tfstate.*.backup"
    )
    
    for pattern in "${backup_patterns[@]}"; do
        print_status "Looking for backup files: $pattern"
        
        if [ "$DRY_RUN" = true ]; then
            find . -name "$pattern" -type f | while read -r file; do
                echo "Would remove: $file"
            done
        else
            find . -name "$pattern" -type f -delete 2>/dev/null || true
        fi
    done
    
    if [ "$DRY_RUN" != true ]; then
        print_status "State backup files cleaned"
    fi
}

# Clean all files
clean_all_files() {
    print_header "Cleaning All Temporary and Backup Files"
    clean_temp_files
    clean_state_backups
}

# Destroy all infrastructure
destroy_all_infrastructure() {
    print_header "DESTROYING ALL INFRASTRUCTURE"
    
    if [ "$AUTO_APPROVE" != true ]; then
        print_warning "⚠️  WARNING: This will DESTROY ALL infrastructure! ⚠️"
        print_warning "This includes:"
        print_warning "  - All environments (dev, staging, prod)"
        print_warning "  - All global resources"
        print_warning "  - All data and databases"
        print_warning "  - All S3 buckets and their contents"
        print_warning ""
        print_error "THIS ACTION CANNOT BE UNDONE!"
        print_warning ""
        read -p "Are you absolutely sure? Type 'DESTROY' to confirm: " -r
        if [ "$REPLY" != "DESTROY" ]; then
            print_status "Operation cancelled"
            exit 0
        fi
        
        read -p "Last chance! Type 'YES' to proceed with destruction: " -r
        if [ "$REPLY" != "YES" ]; then
            print_status "Operation cancelled"
            exit 0
        fi
    fi
    
    if [ "$DRY_RUN" = true ]; then
        print_status "DRY RUN: Would destroy all infrastructure"
        return 0
    fi
    
    # Destroy environments in reverse order (prod, staging, dev)
    for env in prod staging dev; do
        if [ -d "environments/$env" ]; then
            print_status "Destroying $env environment..."
            cd "environments/$env"
            
            if [ -d ".terraform" ]; then
                terraform destroy -auto-approve || print_warning "Failed to destroy $env environment"
            else
                print_warning "Terraform not initialized for $env, skipping..."
            fi
            
            cd ../..
        fi
    done
    
    # Destroy global resources
    local global_modules=("monitoring" "networking" "iam" "s3-backend")
    
    for module in "${global_modules[@]}"; do
        if [ -d "global/$module" ]; then
            print_status "Destroying global $module..."
            cd "global/$module"
            
            if [ -d ".terraform" ]; then
                terraform destroy -auto-approve || print_warning "Failed to destroy global $module"
            else
                print_warning "Terraform not initialized for global $module, skipping..."
            fi
            
            cd ../..
        fi
    done
    
    print_status "Infrastructure destruction completed"
}

# Confirm destructive actions
confirm_action() {
    local action=$1
    
    if [ "$action" = "destroy-all" ]; then
        return 0  # Confirmation handled in destroy_all_infrastructure
    fi
    
    if [ "$AUTO_APPROVE" != true ] && [ "$DRY_RUN" != true ]; then
        read -p "Are you sure you want to clean $action? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Operation cancelled"
            exit 0
        fi
    fi
}

# Show cleanup summary
show_cleanup_summary() {
    local action=$1
    
    if [ "$DRY_RUN" = true ]; then
        print_status "Dry run completed. No files were actually removed."
    else
        case $action in
            temp-files)
                print_status "Temporary files cleanup completed"
                ;;
            state-backup)
                print_status "State backup files cleanup completed"
                ;;
            all-files)
                print_status "All cleanup operations completed"
                ;;
            destroy-all)
                print_status "Infrastructure destruction completed"
                ;;
        esac
    fi
}

# Main execution
main() {
    print_header "IFRS InsightGen Infrastructure Cleanup"
    
    # Check if we're in the right directory
    if [ ! -f "README.md" ] || [ ! -d "modules" ]; then
        print_error "Please run this script from the terraform project root directory"
        exit 1
    fi
    
    # Parse arguments
    parse_args "$@"
    
    # Confirm action
    confirm_action "$ACTION"
    
    # Execute cleanup action
    case $ACTION in
        temp-files)
            clean_temp_files
            ;;
        state-backup)
            clean_state_backups
            ;;
        all-files)
            clean_all_files
            ;;
        destroy-all)
            destroy_all_infrastructure
            ;;
        *)
            print_error "Unknown action: $ACTION"
            exit 1
            ;;
    esac
    
    # Show summary
    show_cleanup_summary "$ACTION"
    
    print_status "Cleanup operation completed!"
}

# Run main function
main "$@"
