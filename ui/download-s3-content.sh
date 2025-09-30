#!/bin/bash

# Script to download UI build content from S3 to EC2
# This should be run on EC2 before building Docker image

set -e

# Configuration
S3_BUCKET="${S3_BUCKET:-insightgen-us-east-1-uploads}"
S3_KEY_PREFIX="${S3_KEY_PREFIX:-ifrs-ui-build/}"
LOCAL_DIR="${LOCAL_DIR:-./ifrs-ui-build}"
AWS_REGION="${AWS_REGION:-us-east-1}"

echo "=== Downloading UI Build Content from S3 ==="
echo "S3 Bucket: $S3_BUCKET"
echo "S3 Key Prefix: $S3_KEY_PREFIX"
echo "Local Directory: $LOCAL_DIR"
echo "AWS Region: $AWS_REGION"
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed!"
    echo "Installing AWS CLI..."
    
    # Install AWS CLI based on OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Ubuntu/Debian
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y awscli
        # Amazon Linux/CentOS/RHEL
        elif command -v yum &> /dev/null; then
            sudo yum install -y awscli
        else
            echo "❌ Unsupported Linux distribution"
            exit 1
        fi
    else
        echo "❌ Unsupported operating system: $OSTYPE"
        exit 1
    fi
fi

# Verify AWS credentials
echo "Verifying AWS credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured!"
    echo "Please configure AWS credentials using one of:"
    echo "  1. aws configure"
    echo "  2. IAM role (recommended for EC2)"
    echo "  3. Environment variables (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)"
    exit 1
fi

echo "✅ AWS credentials verified"

# Check if S3 bucket exists and is accessible
echo "Checking S3 bucket access..."
if ! aws s3 ls "s3://$S3_BUCKET" &> /dev/null; then
    echo "❌ Cannot access S3 bucket: $S3_BUCKET"
    echo "Please check:"
    echo "  1. Bucket name is correct"
    echo "  2. Bucket exists"
    echo "  3. IAM permissions allow s3:ListBucket"
    exit 1
fi

echo "✅ S3 bucket accessible"

# Check if S3 key prefix exists
echo "Checking S3 key prefix..."
if ! aws s3 ls "s3://$S3_BUCKET/$S3_KEY_PREFIX" &> /dev/null; then
    echo "❌ S3 key prefix not found: s3://$S3_BUCKET/$S3_KEY_PREFIX"
    echo "Please check:"
    echo "  1. Key prefix is correct"
    echo "  2. UI build files exist at this location"
    exit 1
fi

echo "✅ S3 key prefix found"

# Create local directory
echo "Creating local directory: $LOCAL_DIR"
mkdir -p "$LOCAL_DIR"

# Download content from S3
echo "Downloading content from S3..."
echo "Source: s3://$S3_BUCKET/$S3_KEY_PREFIX"
echo "Target: $LOCAL_DIR"

if aws s3 sync "s3://$S3_BUCKET/$S3_KEY_PREFIX" "$LOCAL_DIR" --delete; then
    echo "✅ Successfully downloaded UI build files from S3"
else
    echo "❌ Failed to download UI build files from S3"
    exit 1
fi

# Verify download
echo ""
echo "Verifying downloaded content..."
if [ ! "$(ls -A $LOCAL_DIR)" ]; then
    echo "❌ No files found in $LOCAL_DIR after download"
    exit 1
fi

echo "✅ Download verification successful"
echo ""
echo "Downloaded files:"
find "$LOCAL_DIR" -type f | head -20
echo ""

# Check for essential files
ESSENTIAL_FILES=("index.html")
for file in "${ESSENTIAL_FILES[@]}"; do
    if [ ! -f "$LOCAL_DIR/$file" ]; then
        echo "⚠️  Warning: Essential file not found: $file"
    else
        echo "✅ Found essential file: $file"
    fi
done

echo ""
echo "🎉 S3 content download completed successfully!"
echo "You can now build the Docker image using:"
echo "  ./build-and-run.sh"
echo "or"
echo "  ./build-and-run.ps1"
