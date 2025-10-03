#!/bin/bash

# EC2 User Data Script for IFRS UI Setup

set -e

# Log all output
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "=== Starting IFRS UI Setup ==="
date

# Configuration variables (replaced by Terraform)
export S3_BUCKET="${s3_bucket}"
export S3_KEY="${s3_key}"
export UI_PATH="${ui_path}"
export BASE_URL="${BASE_URL}"

echo "Configuration:"
echo "  S3_BUCKET: $S3_BUCKET"
echo "  S3_KEY: $S3_KEY"
echo "  UI_PATH: $UI_PATH"
echo "  BASE_URL: $BASE_URL"

# Install prerequisites
echo "Installing prerequisites..."
apt-get update -y
apt-get install -y curl unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# Create working directory
mkdir -p /opt/ifrs-ui
cd /opt/ifrs-ui

# Download UI assets from S3 FIRST (handle both zip files and folders)
echo "Downloading UI assets from S3..."
rm -rf ifrs-ui-build
mkdir -p ifrs-ui-build

# Check if S3_KEY ends with .zip (zip file) or not (folder)
if [[ "$S3_KEY" == *.zip ]]; then
    echo "Downloading zip file: $S3_KEY"
    aws s3 cp "s3://$S3_BUCKET/$S3_KEY" ./ui-build.zip
    unzip -o ui-build.zip
    
    # Handle different zip structures
    if [ -d "dist" ]; then
        mv dist/* ifrs-ui-build/
    elif [ -d "build" ]; then
        mv build/* ifrs-ui-build/
    else
        find . -maxdepth 1 -type f \( -name "*.html" -o -name "*.js" -o -name "*.css" -o -name "*.json" -o -name "*.ico" -o -name "*.png" -o -name "*.jpg" -o -name "*.svg" \) -exec mv {} ifrs-ui-build/ \; 2>/dev/null || true
        find . -maxdepth 1 -type d ! -name "." ! -name "ifrs-ui-build" ! -name "lost+found" -exec mv {} ifrs-ui-build/ \; 2>/dev/null || true
    fi
else
    echo "Downloading folder: $S3_KEY"
    aws s3 sync "s3://$S3_BUCKET/$S3_KEY" ./ifrs-ui-build/
fi

echo "UI build contents:"
ls -la ifrs-ui-build/

# NOW create Docker files AFTER downloading the assets
echo "Creating Docker configuration..."
cat > Dockerfile << 'EOF'
FROM nginx:alpine
RUN apk add --no-cache curl
ARG UI_PATH=ui
RUN rm -rf /usr/share/nginx/html/*
RUN mkdir -p /usr/share/nginx/html/$${UI_PATH}
COPY ifrs-ui-build/ /usr/share/nginx/html/$${UI_PATH}/
COPY replace-env.sh /tmp/replace-env.sh
RUN sed "s|UI_PATH_PLACEHOLDER|$${UI_PATH}|g" /tmp/replace-env.sh > /usr/local/bin/replace-env.sh && \
    chmod +x /usr/local/bin/replace-env.sh && rm /tmp/replace-env.sh
COPY default.conf /tmp/default.conf.template
RUN sed "s|UI_PATH_PLACEHOLDER|$${UI_PATH}|g" /tmp/default.conf.template > /etc/nginx/conf.d/default.conf && \
    rm /tmp/default.conf.template
ENV UI_PATH=$${UI_PATH}
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/$${UI_PATH}/ || exit 1
CMD ["/bin/sh", "-c", "/usr/local/bin/replace-env.sh && exec nginx -g 'daemon off;'"]
EOF

cat > replace-env.sh << 'EOF'
#!/bin/sh
echo "Starting BASE_URL replacement..."
echo "BASE_URL: ${BASE_URL}"
if [ -f "/usr/share/nginx/html/UI_PATH_PLACEHOLDER/assets/env.js" ]; then
    echo "Replacing BASE_URL in env.js..."
    sed -i "s|\${BASE_URL}|${BASE_URL}|g" /usr/share/nginx/html/UI_PATH_PLACEHOLDER/assets/env.js
    echo "BASE_URL replacement completed"
else
    echo "Warning: env.js file not found at /usr/share/nginx/html/UI_PATH_PLACEHOLDER/assets/env.js"
fi
echo "BASE_URL replacement completed successfully!"
EOF

cat > default.conf << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html index.htm;
    
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private must-revalidate auth;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
    
    location = / {
        return 301 /UI_PATH_PLACEHOLDER/;
    }
    
    location /UI_PATH_PLACEHOLDER/ {
        alias /usr/share/nginx/html/UI_PATH_PLACEHOLDER/;
        try_files $uri $uri/ /UI_PATH_PLACEHOLDER/index.html;
        
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
        
        location ~* \.html$ {
            expires -1;
            add_header Cache-Control "no-cache, no-store, must-revalidate";
        }
    }
    
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
    
    error_page 404 /UI_PATH_PLACEHOLDER/index.html;
    error_page 500 502 503 504 /50x.html;
    
    location = /50x.html {
        root /usr/share/nginx/html;
    }
    
    location ~ /\.ht { deny all; }
    location ~ /\. { deny all; access_log off; log_not_found off; }
}
EOF

# Build and run Docker container
echo "Building Docker image..."
docker build --build-arg UI_PATH="$UI_PATH" -t ifrs-ui .

echo "Starting container..."
docker stop ifrs-ui-app 2>/dev/null || true
docker rm ifrs-ui-app 2>/dev/null || true

docker run -d \
    --name ifrs-ui-app \
    --restart unless-stopped \
    -p 80:80 \
    -e BASE_URL="$BASE_URL" \
    ifrs-ui

sleep 5
docker ps --filter name=ifrs-ui-app

echo "=== Setup Complete ==="
echo "UI accessible at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/$UI_PATH/"
echo "Completed: $(date)"
