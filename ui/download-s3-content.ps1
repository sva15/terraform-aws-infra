# PowerShell script to download UI build content from S3 to local machine
# This should be run before building Docker image

param(
    [string]$S3Bucket = "insightgen-us-east-1-uploads",
    [string]$S3KeyPrefix = "ifrs-ui-build/",
    [string]$LocalDir = ".\ifrs-ui-build",
    [string]$AWSRegion = "us-east-1"
)

Write-Host "=== Downloading UI Build Content from S3 ===" -ForegroundColor Green
Write-Host "S3 Bucket: $S3Bucket" -ForegroundColor Yellow
Write-Host "S3 Key Prefix: $S3KeyPrefix" -ForegroundColor Yellow
Write-Host "Local Directory: $LocalDir" -ForegroundColor Yellow
Write-Host "AWS Region: $AWSRegion" -ForegroundColor Yellow
Write-Host ""

# Check if AWS CLI is installed
try {
    $awsVersion = aws --version 2>$null
    Write-Host "✅ AWS CLI found: $awsVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ AWS CLI is not installed!" -ForegroundColor Red
    Write-Host "Please install AWS CLI from: https://aws.amazon.com/cli/" -ForegroundColor Yellow
    exit 1
}

# Verify AWS credentials
Write-Host "Verifying AWS credentials..." -ForegroundColor Green
try {
    $identity = aws sts get-caller-identity 2>$null | ConvertFrom-Json
    Write-Host "✅ AWS credentials verified for account: $($identity.Account)" -ForegroundColor Green
} catch {
    Write-Host "❌ AWS credentials not configured!" -ForegroundColor Red
    Write-Host "Please configure AWS credentials using one of:" -ForegroundColor Yellow
    Write-Host "  1. aws configure"
    Write-Host "  2. Environment variables (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)"
    exit 1
}

# Check if S3 bucket exists and is accessible
Write-Host "Checking S3 bucket access..." -ForegroundColor Green
try {
    aws s3 ls "s3://$S3Bucket" 2>$null | Out-Null
    Write-Host "✅ S3 bucket accessible" -ForegroundColor Green
} catch {
    Write-Host "❌ Cannot access S3 bucket: $S3Bucket" -ForegroundColor Red
    Write-Host "Please check:" -ForegroundColor Yellow
    Write-Host "  1. Bucket name is correct"
    Write-Host "  2. Bucket exists"
    Write-Host "  3. IAM permissions allow s3:ListBucket"
    exit 1
}

# Check if S3 key prefix exists
Write-Host "Checking S3 key prefix..." -ForegroundColor Green
try {
    $s3Objects = aws s3 ls "s3://$S3Bucket/$S3KeyPrefix" 2>$null
    if (-not $s3Objects) {
        throw "No objects found"
    }
    Write-Host "✅ S3 key prefix found" -ForegroundColor Green
} catch {
    Write-Host "❌ S3 key prefix not found: s3://$S3Bucket/$S3KeyPrefix" -ForegroundColor Red
    Write-Host "Please check:" -ForegroundColor Yellow
    Write-Host "  1. Key prefix is correct"
    Write-Host "  2. UI build files exist at this location"
    exit 1
}

# Create local directory
Write-Host "Creating local directory: $LocalDir" -ForegroundColor Green
if (Test-Path $LocalDir) {
    Write-Host "Directory already exists, cleaning..." -ForegroundColor Yellow
    Remove-Item -Path $LocalDir -Recurse -Force
}
New-Item -ItemType Directory -Path $LocalDir -Force | Out-Null

# Download content from S3
Write-Host "Downloading content from S3..." -ForegroundColor Green
Write-Host "Source: s3://$S3Bucket/$S3KeyPrefix" -ForegroundColor Yellow
Write-Host "Target: $LocalDir" -ForegroundColor Yellow

try {
    aws s3 sync "s3://$S3Bucket/$S3KeyPrefix" $LocalDir --delete
    if ($LASTEXITCODE -ne 0) {
        throw "AWS S3 sync failed"
    }
    Write-Host "✅ Successfully downloaded UI build files from S3" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to download UI build files from S3" -ForegroundColor Red
    exit 1
}

# Verify download
Write-Host ""
Write-Host "Verifying downloaded content..." -ForegroundColor Green
$downloadedFiles = Get-ChildItem -Path $LocalDir -Recurse -File
if ($downloadedFiles.Count -eq 0) {
    Write-Host "❌ No files found in $LocalDir after download" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Download verification successful" -ForegroundColor Green
Write-Host ""
Write-Host "Downloaded files:" -ForegroundColor Yellow
$downloadedFiles | Select-Object Name, Length, LastWriteTime | Format-Table
Write-Host ""

# Check for essential files
$essentialFiles = @("index.html")
foreach ($file in $essentialFiles) {
    $filePath = Join-Path $LocalDir $file
    if (Test-Path $filePath) {
        Write-Host "✅ Found essential file: $file" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Warning: Essential file not found: $file" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "🎉 S3 content download completed successfully!" -ForegroundColor Green
Write-Host "You can now build the Docker image using:" -ForegroundColor Yellow
Write-Host "  .\build-and-run.ps1" -ForegroundColor Cyan
