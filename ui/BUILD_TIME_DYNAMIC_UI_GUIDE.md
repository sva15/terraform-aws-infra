# 🚀 **Build-Time Dynamic UI Container Guide**

## 📋 **Overview**

This guide explains the updated approach where:
- ✅ **S3 content downloaded on EC2** (not inside container)
- ✅ **Docker build uses local content** (no S3 download in container)
- ✅ **UI path set at build time** via Docker build arguments
- ✅ **Uses existing replace-env.sh** for runtime BASE_URL replacement
- ✅ **Dynamic path support** for both COPY and replace-env.sh

---

## 🏗️ **Architecture Flow**

### **Step 1: Download from S3 (on EC2)**
```bash
# Download UI build files from S3 to local directory
./download-s3-content.sh
# Creates: ./ifrs-ui-build/ with all UI assets
```

### **Step 2: Build Docker Image (with build args)**
```bash
# Build with dynamic UI path
docker build --build-arg UI_PATH=ui --build-arg BASE_URL=/ui/ -t ifrs-ui .
```

### **Step 3: Container Runtime**
```bash
# Container starts and runs replace-env.sh for BASE_URL replacement
docker run -e BASE_URL=/ui/ ifrs-ui
```

---

## 📁 **File Structure**

```
ui/
├── Dockerfile                      # Build-time dynamic container
├── default.conf                    # Nginx configuration template
├── replace-env.sh                  # Runtime env replacement script
├── download-s3-content.sh           # S3 download script (Linux/Mac)
├── download-s3-content.ps1         # S3 download script (Windows)
├── build-and-run.sh                # Build script (Linux/Mac)
├── build-and-run.ps1               # Build script (Windows)
├── ifrs-ui-build/                  # Downloaded UI files (created by download script)
│   ├── index.html
│   ├── main.js
│   ├── styles.css
│   └── assets/
│       └── env.js                  # Contains ${BASE_URL} placeholders
└── BUILD_TIME_DYNAMIC_UI_GUIDE.md  # This guide
```

---

## ⚙️ **Docker Build Arguments**

### **Build Arguments:**
- `UI_PATH`: Directory name inside nginx html root (default: "ui")
- `BASE_URL`: URL path with slashes (default: "/ui/")

### **Runtime Environment Variables:**
- `BASE_URL`: Used by replace-env.sh for runtime replacement

---

## 🚀 **Usage Examples**

### **Example 1: UI at /ui/ path**

#### **Step 1: Download S3 Content**
```bash
# Linux/Mac
./download-s3-content.sh

# Windows
.\download-s3-content.ps1
```

#### **Step 2: Build and Run**
```bash
# Linux/Mac
export UI_PATH=ui
export BASE_URL=/ui/
./build-and-run.sh

# Windows
.\build-and-run.ps1 -UIPath "ui" -BaseURL "/ui/"
```

### **Example 2: UI at /dashboard/ path**

#### **Step 1: Download S3 Content**
```bash
./download-s3-content.sh
```

#### **Step 2: Build and Run**
```bash
# Linux/Mac
export UI_PATH=dashboard
export BASE_URL=/dashboard/
./build-and-run.sh

# Windows
.\build-and-run.ps1 -UIPath "dashboard" -BaseURL "/dashboard/"
```

### **Example 3: Manual Docker Commands**

```bash
# Download content
./download-s3-content.sh

# Build with custom path
docker build \
  --build-arg UI_PATH=app \
  --build-arg BASE_URL=/app/ \
  -t ifrs-ui-app .

# Run with runtime BASE_URL
docker run -d \
  --name ifrs-app \
  -p 8080:80 \
  -e BASE_URL=/app/ \
  ifrs-ui-app
```

---

## 🔧 **How It Works**

### **1. Dockerfile Build Process**
```dockerfile
# Build arguments define the UI path
ARG UI_PATH=ui
ARG BASE_URL=/ui/

# Create directory based on build arg
RUN mkdir -p /usr/share/nginx/html/${UI_PATH}

# Copy local content to dynamic path
COPY ifrs-ui-build/ /usr/share/nginx/html/${UI_PATH}/

# Update replace-env.sh to use dynamic path
COPY replace-env.sh /usr/share/nginx/html/${UI_PATH}/replace-env.sh
RUN sed -i "s|/usr/share/nginx/html/ui/|/usr/share/nginx/html/${UI_PATH}/|g" \
    /usr/share/nginx/html/${UI_PATH}/replace-env.sh

# Update nginx config for dynamic path
RUN sed -i "s|/ui/|/${UI_PATH}/|g" /etc/nginx/conf.d/default.conf
```

### **2. Runtime Process**
```bash
# Container starts and runs:
/usr/share/nginx/html/${UI_PATH}/replace-env.sh && nginx -g 'daemon off;'

# replace-env.sh replaces ${BASE_URL} in:
# - assets/env.js
# - index.html
# - Any other JS files containing ${BASE_URL}
```

### **3. Nginx Configuration**
```nginx
# Root redirects to UI path
location = / {
    return 301 /ui/;  # Updated to /${UI_PATH}/ during build
}

# UI path location
location /ui/ {  # Updated to /${UI_PATH}/ during build
    alias /usr/share/nginx/html/ui/;  # Updated during build
    try_files $uri $uri/ /ui/index.html;
}
```

---

## 📋 **Step-by-Step Workflow**

### **On EC2 Instance:**

#### **1. Download S3 Content**
```bash
# Set environment variables (optional)
export S3_BUCKET=insightgen-us-east-1-uploads
export S3_KEY_PREFIX=ifrs-ui-build/
export LOCAL_DIR=./ifrs-ui-build

# Download content
./download-s3-content.sh
```

#### **2. Build Docker Image**
```bash
# Set UI path and base URL
export UI_PATH=ui
export BASE_URL=/ui/

# Build and run
./build-and-run.sh
```

#### **3. Access Application**
```
http://ec2-instance-ip:8080/ui/
```

---

## 🔍 **Script Details**

### **download-s3-content.sh**
- ✅ Checks AWS CLI installation
- ✅ Verifies AWS credentials
- ✅ Validates S3 bucket access
- ✅ Downloads content with `aws s3 sync`
- ✅ Verifies essential files exist

### **build-and-run.sh**
- ✅ Checks for `ifrs-ui-build/` directory
- ✅ Builds Docker image with build arguments
- ✅ Runs container with runtime environment variables
- ✅ Provides health check and access URLs

### **replace-env.sh**
- ✅ Dynamically updated during build for correct UI path
- ✅ Replaces `${BASE_URL}` in assets/env.js
- ✅ Replaces environment variables in HTML and JS files
- ✅ Supports runtime BASE_URL changes

---

## 🔐 **Security & Best Practices**

### **S3 Permissions (EC2 IAM Role)**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::insightgen-us-east-1-uploads",
                "arn:aws:s3:::insightgen-us-east-1-uploads/ifrs-ui-build/*"
            ]
        }
    ]
}
```

### **Environment Variables in UI**
```javascript
// assets/env.js - Template with placeholders
window.env = {
    BASE_URL: '${BASE_URL}',
    API_URL: '${BASE_URL}api/',
    VERSION: '1.0.0'
};

// After replace-env.sh runs:
window.env = {
    BASE_URL: '/ui/',
    API_URL: '/ui/api/',
    VERSION: '1.0.0'
};
```

---

## 🚀 **Production Deployment**

### **EC2 User Data Script**
```bash
#!/bin/bash
cd /opt/ifrs-ui

# Download S3 content
./download-s3-content.sh

# Build and run with production settings
export UI_PATH=ui
export BASE_URL=/ui/
export PORT=80
./build-and-run.sh
```

### **Docker Compose**
```yaml
version: '3.8'
services:
  ifrs-ui:
    build:
      context: .
      args:
        UI_PATH: ui
        BASE_URL: /ui/
    ports:
      - "80:80"
    environment:
      - BASE_URL=/ui/
    restart: unless-stopped
```

---

## 🔧 **Troubleshooting**

### **Common Issues:**

#### **1. ifrs-ui-build directory not found**
```bash
# Solution: Run download script first
./download-s3-content.sh
```

#### **2. S3 access denied**
```bash
# Check AWS credentials
aws sts get-caller-identity

# Check S3 access
aws s3 ls s3://insightgen-us-east-1-uploads/ifrs-ui-build/
```

#### **3. BASE_URL not replaced**
```bash
# Check if replace-env.sh is executable
docker exec container-name ls -la /usr/share/nginx/html/ui/replace-env.sh

# Check replace-env.sh content
docker exec container-name cat /usr/share/nginx/html/ui/replace-env.sh
```

#### **4. Wrong UI path in nginx**
```bash
# Check nginx configuration
docker exec container-name cat /etc/nginx/conf.d/default.conf
```

---

## ✅ **Benefits of This Approach**

### **✅ Build-Time Optimization**
- UI path determined at build time (not runtime)
- Nginx configuration optimized for specific path
- No runtime directory creation overhead

### **✅ S3 Integration**
- Content downloaded once on EC2 (not per container start)
- Faster container startup (no S3 download delay)
- Better error handling for S3 issues

### **✅ Existing Script Compatibility**
- Uses your existing replace-env.sh approach
- Maintains runtime BASE_URL flexibility
- No changes to UI build process

### **✅ Production Ready**
- Optimized for EC2 deployment
- Supports multiple UI paths
- Health checks and monitoring included

---

## 🎉 **Summary**

This approach provides the best of both worlds:

1. **✅ Build-Time Path Configuration**: UI path set during Docker build
2. **✅ Runtime BASE_URL Flexibility**: BASE_URL can still be changed at runtime
3. **✅ S3 Download on EC2**: Content downloaded once, not per container
4. **✅ Existing Script Compatibility**: Uses your replace-env.sh approach
5. **✅ Production Optimized**: Fast startup, efficient resource usage

**Perfect for your use case where the UI path needs to be configurable but you want to avoid runtime S3 downloads!** 🚀
