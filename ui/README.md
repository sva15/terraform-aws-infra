# IFRS UI Simplified Setup

This directory contains the minimal setup for the IFRS UI application focused on your specific use case: downloading UI assets from S3, building a Docker image, and running it on EC2.

## Overview

The setup has been streamlined to:
1. **Download UI assets from S3** - Supports both zip files and folder structures
2. **Build Docker image** - UI path configured at build time, BASE_URL at runtime
3. **Runtime environment replacement** - Uses replace-env.sh for BASE_URL only

## Files

- **`Dockerfile`** - Simplified Docker configuration with UI_PATH build argument
- **`default.conf`** - Nginx configuration template with UI_PATH placeholder
- **`replace-env.sh`** - Runtime script for BASE_URL replacement in env.js

## Configuration Variables

### Terraform Variables

Add these to your `terraform.tfvars`:

```hcl
# UI Configuration
ui_s3_bucket = "your-ui-build-bucket"     # S3 bucket containing UI assets
ui_s3_key    = "path/to/assets"           # S3 key (folder) or "build.zip" (zip file)
ui_path      = "ui"                       # UI routing path
BASE_URL     = "https://api.example.com"  # API base URL (runtime only)
```

### Build vs Runtime Configuration

- **`UI_PATH`** - Configured at Docker build time (from Terraform variable)
- **`BASE_URL`** - Configured at container runtime (environment variable)

## S3 Asset Types

The setup supports both:

### 1. Zip File
```hcl
ui_s3_key = "builds/ui-build.zip"
```

### 2. Folder Structure
```hcl
ui_s3_key = "static-assets/ui/"
```

## Usage Examples

### 1. Default Setup (UI at /ui/)
```hcl
ui_s3_bucket = "my-assets-bucket"
ui_s3_key    = "ui-builds/latest/"
ui_path      = "ui"
base_url     = "https://api.yourdomain.com"
```
Access: `http://your-ec2-ip/ui/`

### 2. Custom Path (UI at /app/)
```hcl
ui_s3_key = "app-build.zip"
ui_path   = "app"
base_url  = "https://api.yourdomain.com"
```
Access: `http://your-ec2-ip/app/`

## How It Works

1. **EC2 Instance Startup**:
   - Installs Docker and AWS CLI
   - Downloads UI assets from S3 (zip or folder)
   - Creates Docker configuration files

2. **Docker Build**:
   - UI_PATH configured at build time
   - replace-env.sh prepared with correct UI path
   - Nginx configured for the specified UI path

3. **Container Runtime**:
   - replace-env.sh runs and updates `/usr/share/nginx/html/{UI_PATH}/assets/env.js`
   - Only BASE_URL is replaced at runtime
   - Nginx serves UI at configured path

## Docker Commands

If you want to build and run manually:

```bash
# Build with custom UI path and base URL
docker build \
  --build-arg UI_PATH="dashboard" \
  --build-arg BASE_URL="https://api.example.com" \
  -t ifrs-ui .

# Run container
docker run -d \
  --name ifrs-ui-app \
  -p 80:80 \
  -e BASE_URL="https://api.example.com" \
  ifrs-ui
```

## Health Check

The container includes a health check accessible at:
- `http://your-ec2-ip/health` - Returns "healthy" status

## Nginx Configuration

The nginx configuration:
- ✅ Serves UI at configurable path
- ✅ Handles Angular SPA routing
- ✅ Includes security headers
- ✅ Enables gzip compression
- ✅ Caches static assets appropriately
- ❌ Removed API proxy (as requested)

## Troubleshooting

### Check Container Status
```bash
docker ps --filter name=ifrs-ui-app
docker logs ifrs-ui-app
```

### Check EC2 Setup Logs
```bash
sudo tail -f /var/log/user-data.log
```

### Verify S3 Access
```bash
aws s3 ls s3://your-bucket-name/
```

## Security Notes

- EC2 instance has IAM role with S3 read access to the specified bucket
- Container runs nginx on port 80
- Security headers are configured in nginx
- No API endpoints are exposed (as requested)

This simplified setup focuses exactly on your use case while maintaining flexibility through the configurable UI path and base URL parameters.
