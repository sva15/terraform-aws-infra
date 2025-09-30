#!/bin/sh

# Entrypoint script for dynamic UI path setup and S3 content download

set -e

echo "Starting UI container setup..."

# Validate required environment variables
if [ -z "$UI_PATH" ]; then
    echo "ERROR: UI_PATH environment variable is required"
    echo "Usage: docker run -e UI_PATH=ui -e BASE_URL=/ui/ your-image"
    exit 1
fi

if [ -z "$BASE_URL" ]; then
    echo "ERROR: BASE_URL environment variable is required"
    echo "Usage: docker run -e UI_PATH=ui -e BASE_URL=/ui/ your-image"
    exit 1
fi

echo "UI_PATH: $UI_PATH"
echo "BASE_URL: $BASE_URL"
echo "S3_BUCKET: $S3_BUCKET"
echo "S3_KEY_PREFIX: $S3_KEY_PREFIX"

# Create the target directory inside nginx html root
TARGET_DIR="/usr/share/nginx/html/$UI_PATH"
echo "Creating target directory: $TARGET_DIR"
mkdir -p "$TARGET_DIR"

# Download UI build files from S3
echo "Downloading UI build files from S3..."
echo "Source: s3://$S3_BUCKET/$S3_KEY_PREFIX"
echo "Target: $TARGET_DIR"

# Use AWS CLI to sync the S3 content to the target directory
if aws s3 sync "s3://$S3_BUCKET/$S3_KEY_PREFIX" "$TARGET_DIR" --delete; then
    echo "Successfully downloaded UI build files from S3"
else
    echo "ERROR: Failed to download UI build files from S3"
    echo "Please check:"
    echo "1. AWS credentials are properly configured"
    echo "2. S3 bucket '$S3_BUCKET' exists and is accessible"
    echo "3. S3 key prefix '$S3_KEY_PREFIX' contains the UI build files"
    exit 1
fi

# Verify that files were downloaded
if [ ! "$(ls -A $TARGET_DIR)" ]; then
    echo "ERROR: No files found in target directory after S3 download"
    echo "Please verify that S3 path s3://$S3_BUCKET/$S3_KEY_PREFIX contains UI build files"
    exit 1
fi

echo "Files downloaded successfully:"
ls -la "$TARGET_DIR"

# Update nginx configuration to handle the dynamic base URL
# Create a temporary nginx config with the correct base URL
TEMP_NGINX_CONF="/tmp/nginx_dynamic.conf"
cat > "$TEMP_NGINX_CONF" << EOF
server {
    listen 80;
    server_name localhost;
    
    # Root location for health checks
    location / {
        return 301 $BASE_URL;
    }
    
    # Dynamic UI path location
    location $BASE_URL {
        alias $TARGET_DIR/;
        try_files \$uri \$uri/ $BASE_URL/index.html;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
        
        # Security headers
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
    }
    
    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Replace the default nginx configuration
cp "$TEMP_NGINX_CONF" /etc/nginx/conf.d/default.conf

echo "Nginx configuration updated for UI_PATH: $UI_PATH and BASE_URL: $BASE_URL"

# Test nginx configuration
if nginx -t; then
    echo "Nginx configuration is valid"
else
    echo "ERROR: Invalid nginx configuration"
    exit 1
fi

echo "Setup completed successfully!"
echo "UI will be available at: http://localhost$BASE_URL"

# Execute the main command (nginx)
exec "$@"
