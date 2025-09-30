# PowerShell script to build and run the UI container with build-time dynamic path

param(
    [string]$UIPath = "ui",
    [string]$BaseURL = "/ui/",
    [string]$Port = "8080",
    [string]$ImageName = "ifrs-ui-dynamic",
    [string]$ImageTag = "latest",
    [string]$ContainerName = "ifrs-ui-container"
)

Write-Host "=== Building IFRS UI Container with Build Args ===" -ForegroundColor Green
Write-Host "Image: $ImageName`:$ImageTag" -ForegroundColor Yellow
Write-Host "UI Path: $UIPath" -ForegroundColor Yellow
Write-Host "Base URL: $BaseURL" -ForegroundColor Yellow
Write-Host ""

# Check if ifrs-ui-build directory exists
if (-not (Test-Path "ifrs-ui-build")) {
    Write-Host "❌ Error: ifrs-ui-build directory not found!" -ForegroundColor Red
    Write-Host "Please ensure the UI build files are downloaded from S3 to .\ifrs-ui-build\" -ForegroundColor Red
    Write-Host ""
    Write-Host "Expected structure:" -ForegroundColor Yellow
    Write-Host "  .\ifrs-ui-build\"
    Write-Host "    ├── index.html"
    Write-Host "    ├── main.js"
    Write-Host "    ├── styles.css"
    Write-Host "    └── assets\"
    exit 1
}

Write-Host "✅ Found ifrs-ui-build directory" -ForegroundColor Green
Write-Host "Contents:" -ForegroundColor Yellow
Get-ChildItem ifrs-ui-build\ | Format-Table Name, Length, LastWriteTime
Write-Host ""

# Build the Docker image with build arguments
Write-Host "Building Docker image with build args..." -ForegroundColor Green
docker build --build-arg UI_PATH="$UIPath" --build-arg BASE_URL="$BaseURL" -t "$ImageName`:$ImageTag" .

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Docker build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Docker image built successfully!" -ForegroundColor Green

# Stop and remove existing container if it exists
Write-Host ""
Write-Host "Cleaning up existing container..." -ForegroundColor Green
docker stop $ContainerName 2>$null
docker rm $ContainerName 2>$null

# Run the container
Write-Host ""
Write-Host "Starting container..." -ForegroundColor Green
Write-Host "Container will be available at: http://localhost:$Port$BaseURL" -ForegroundColor Yellow

$dockerRunCmd = @(
    "run", "-d",
    "--name", $ContainerName,
    "-p", "$Port`:80",
    "-e", "UI_PATH=$UIPath",
    "-e", "BASE_URL=$BaseURL",
    "-e", "S3_BUCKET=$S3Bucket",
    "-e", "S3_KEY_PREFIX=$S3KeyPrefix",
    "-e", "AWS_DEFAULT_REGION=$AWSRegion"
)

# Add AWS credentials if they exist in environment
if ($env:AWS_ACCESS_KEY_ID) {
    $dockerRunCmd += "-e", "AWS_ACCESS_KEY_ID=$env:AWS_ACCESS_KEY_ID"
}
if ($env:AWS_SECRET_ACCESS_KEY) {
    $dockerRunCmd += "-e", "AWS_SECRET_ACCESS_KEY=$env:AWS_SECRET_ACCESS_KEY"
}
if ($env:AWS_SESSION_TOKEN) {
    $dockerRunCmd += "-e", "AWS_SESSION_TOKEN=$env:AWS_SESSION_TOKEN"
}

$dockerRunCmd += "$ImageName`:$ImageTag"

& docker @dockerRunCmd

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Container started successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Container Details:" -ForegroundColor Yellow
    Write-Host "  Name: $ContainerName"
    Write-Host "  Port: $Port"
    Write-Host "  UI URL: http://localhost:$Port$BaseURL"
    Write-Host "  Health Check: http://localhost:$Port/health"
    Write-Host ""
    Write-Host "To view logs: docker logs $ContainerName" -ForegroundColor Cyan
    Write-Host "To stop: docker stop $ContainerName" -ForegroundColor Cyan
    Write-Host ""
    
    # Wait a moment and check if container is still running
    Start-Sleep -Seconds 3
    $runningContainers = docker ps --format "table {{.Names}}" | Select-String $ContainerName
    
    if ($runningContainers) {
        Write-Host "✅ Container is running successfully!" -ForegroundColor Green
        
        # Show initial logs
        Write-Host ""
        Write-Host "=== Initial Container Logs ===" -ForegroundColor Yellow
        docker logs $ContainerName
    } else {
        Write-Host "❌ Container failed to start. Check logs:" -ForegroundColor Red
        docker logs $ContainerName
        exit 1
    }
} else {
    Write-Host "❌ Failed to start container!" -ForegroundColor Red
    exit 1
}
