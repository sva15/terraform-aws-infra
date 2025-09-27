# Build and Push Script for Angular UI

param(
    [Parameter(Mandatory=$true)]
    [string]$ECRRepository,
    
    [Parameter(Mandatory=$true)]
    [string]$AWSRegion,
    
    [Parameter(Mandatory=$false)]
    [string]$ImageTag = "latest",
    
    [Parameter(Mandatory=$false)]
    [switch]$BuildAngular = $false
)

Write-Host "Building and pushing Angular UI to ECR..." -ForegroundColor Green

# Build Angular application (if requested)
if ($BuildAngular) {
    Write-Host "Building Angular application..." -ForegroundColor Yellow
    npm run build
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Angular build failed!" -ForegroundColor Red
        exit 1
    }
}

# Check if dist folder exists
if (-not (Test-Path "dist")) {
    Write-Host "Error: dist folder not found. Please run 'ng build' first or use -BuildAngular flag." -ForegroundColor Red
    exit 1
}

# Login to ECR
Write-Host "Logging in to ECR..." -ForegroundColor Yellow
aws ecr get-login-password --region $AWSRegion | docker login --username AWS --password-stdin $ECRRepository
if ($LASTEXITCODE -ne 0) {
    Write-Host "ECR login failed!" -ForegroundColor Red
    exit 1
}

# Build Docker image
Write-Host "Building Docker image..." -ForegroundColor Yellow
docker build -t angular-ui .
if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker build failed!" -ForegroundColor Red
    exit 1
}

# Tag image for ECR
Write-Host "Tagging image for ECR..." -ForegroundColor Yellow
docker tag angular-ui:latest "$ECRRepository`:$ImageTag"

# Push to ECR
Write-Host "Pushing image to ECR..." -ForegroundColor Yellow
docker push "$ECRRepository`:$ImageTag"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker push failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Successfully built and pushed Angular UI to ECR!" -ForegroundColor Green
Write-Host "Image: $ECRRepository`:$ImageTag" -ForegroundColor Cyan
