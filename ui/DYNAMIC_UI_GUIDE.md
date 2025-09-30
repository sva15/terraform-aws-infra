# 🚀 **Dynamic UI Container Guide**

## 📋 **Overview**

This guide explains how to use the new dynamic UI container that downloads build files from S3 at runtime and serves them at a configurable path.

### **Key Features:**
- ✅ **Dynamic Path**: UI path configurable at runtime
- ✅ **S3 Integration**: Downloads build files from S3 automatically
- ✅ **No Build Stage**: Uses pre-built files from S3
- ✅ **Runtime Configuration**: Base URL and path set via environment variables
- ✅ **AWS CLI Integration**: Built-in S3 download capabilities

---

## 🏗️ **Architecture**

### **Container Flow:**
1. **Container Starts** → Entrypoint script runs
2. **Environment Check** → Validates required variables
3. **Directory Creation** → Creates `/usr/share/nginx/html/{UI_PATH}/`
4. **S3 Download** → Downloads files from S3 to target directory
5. **Nginx Config** → Generates dynamic nginx configuration
6. **Service Start** → Starts nginx with custom config

### **S3 Structure:**
```
s3://insightgen-us-east-1-uploads/
├── ifrs-ui-build/           # UI build files
│   ├── index.html
│   ├── main.js
│   ├── styles.css
│   └── assets/
└── postgres/backups/        # Database backups
    └── postgres_backup_20250930_030232.sql
```

---

## ⚙️ **Configuration**

### **Required Environment Variables:**
- `UI_PATH`: Directory name inside nginx html root (e.g., "ui", "app", "dashboard")
- `BASE_URL`: URL path with leading/trailing slashes (e.g., "/ui/", "/app/")

### **Optional Environment Variables:**
- `S3_BUCKET`: S3 bucket name (default: "insightgen-us-east-1-uploads")
- `S3_KEY_PREFIX`: S3 key prefix (default: "ifrs-ui-build/")
- `AWS_DEFAULT_REGION`: AWS region (default: "us-east-1")

### **AWS Credentials:**
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN` (if using temporary credentials)

---

## 🚀 **Usage Examples**

### **Example 1: UI at /ui/ path**
```bash
docker run -d \
  --name ifrs-ui \
  -p 8080:80 \
  -e UI_PATH=ui \
  -e BASE_URL=/ui/ \
  -e AWS_ACCESS_KEY_ID=your_key \
  -e AWS_SECRET_ACCESS_KEY=your_secret \
  ifrs-ui-dynamic:latest
```

**Result:** UI available at `http://localhost:8080/ui/`

### **Example 2: UI at /dashboard/ path**
```bash
docker run -d \
  --name ifrs-dashboard \
  -p 9090:80 \
  -e UI_PATH=dashboard \
  -e BASE_URL=/dashboard/ \
  -e AWS_ACCESS_KEY_ID=your_key \
  -e AWS_SECRET_ACCESS_KEY=your_secret \
  ifrs-ui-dynamic:latest
```

**Result:** UI available at `http://localhost:9090/dashboard/`

### **Example 3: Using PowerShell Script**
```powershell
# Windows PowerShell
.\build-and-run.ps1 -UIPath "app" -BaseURL "/app/" -Port "3000"
```

### **Example 4: Using Bash Script**
```bash
# Linux/Mac
export UI_PATH=ui
export BASE_URL=/ui/
export PORT=8080
./build-and-run.sh
```

---

## 🔧 **Build and Run Scripts**

### **PowerShell Script (Windows)**
```powershell
# Build and run with custom parameters
.\build-and-run.ps1 `
  -UIPath "ui" `
  -BaseURL "/ui/" `
  -Port "8080" `
  -S3Bucket "your-bucket" `
  -S3KeyPrefix "your-prefix/"
```

### **Bash Script (Linux/Mac)**
```bash
# Set environment variables
export UI_PATH=ui
export BASE_URL=/ui/
export PORT=8080
export S3_BUCKET=insightgen-us-east-1-uploads
export S3_KEY_PREFIX=ifrs-ui-build/

# Run the script
./build-and-run.sh
```

---

## 🗂️ **File Structure**

```
ui/
├── Dockerfile              # Dynamic container definition
├── entrypoint.sh           # Runtime setup script
├── default.conf            # Base nginx configuration (template)
├── build-and-run.sh        # Linux/Mac build script
├── build-and-run.ps1       # Windows PowerShell script
├── build-and-push.ps1      # Original ECR push script (legacy)
└── DYNAMIC_UI_GUIDE.md     # This guide
```

---

## 🔍 **Troubleshooting**

### **Common Issues:**

#### **1. Container Fails to Start**
```bash
# Check logs
docker logs ifrs-ui-container

# Common causes:
# - Missing UI_PATH or BASE_URL environment variables
# - Invalid AWS credentials
# - S3 bucket/key doesn't exist
```

#### **2. S3 Download Fails**
```bash
# Verify S3 access
aws s3 ls s3://insightgen-us-east-1-uploads/ifrs-ui-build/

# Check AWS credentials
aws sts get-caller-identity
```

#### **3. UI Not Loading**
```bash
# Check if files were downloaded
docker exec ifrs-ui-container ls -la /usr/share/nginx/html/ui/

# Check nginx configuration
docker exec ifrs-ui-container cat /etc/nginx/conf.d/default.conf
```

#### **4. Health Check Failing**
```bash
# Test health endpoint
curl http://localhost:8080/health

# Test UI endpoint
curl http://localhost:8080/ui/
```

### **Debug Commands:**
```bash
# Enter container for debugging
docker exec -it ifrs-ui-container sh

# View nginx logs
docker exec ifrs-ui-container tail -f /var/log/nginx/access.log
docker exec ifrs-ui-container tail -f /var/log/nginx/error.log

# Test nginx configuration
docker exec ifrs-ui-container nginx -t
```

---

## 🌐 **Nginx Configuration**

The container dynamically generates nginx configuration based on environment variables:

```nginx
server {
    listen 80;
    server_name localhost;
    
    # Root location redirects to UI path
    location / {
        return 301 /ui/;
    }
    
    # Dynamic UI path location
    location /ui/ {
        alias /usr/share/nginx/html/ui/;
        try_files $uri $uri/ /ui/index.html;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # Health check endpoint
    location /health {
        return 200 "healthy\n";
    }
}
```

---

## 🔐 **Security Considerations**

### **AWS Credentials:**
- Use IAM roles when running in AWS (ECS, EC2, etc.)
- Use least-privilege policies for S3 access
- Avoid hardcoding credentials in containers

### **S3 Permissions:**
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

---

## 🚀 **Production Deployment**

### **Docker Compose Example:**
```yaml
version: '3.8'
services:
  ifrs-ui:
    build: .
    ports:
      - "80:80"
    environment:
      - UI_PATH=ui
      - BASE_URL=/ui/
      - S3_BUCKET=insightgen-us-east-1-uploads
      - S3_KEY_PREFIX=ifrs-ui-build/
      - AWS_DEFAULT_REGION=us-east-1
    env_file:
      - .env  # Contains AWS credentials
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

### **Kubernetes Deployment:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ifrs-ui
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ifrs-ui
  template:
    metadata:
      labels:
        app: ifrs-ui
    spec:
      containers:
      - name: ifrs-ui
        image: ifrs-ui-dynamic:latest
        ports:
        - containerPort: 80
        env:
        - name: UI_PATH
          value: "ui"
        - name: BASE_URL
          value: "/ui/"
        - name: S3_BUCKET
          value: "insightgen-us-east-1-uploads"
        - name: S3_KEY_PREFIX
          value: "ifrs-ui-build/"
        # Use AWS IAM roles for service accounts (IRSA) for credentials
```

---

## ✅ **Summary**

This dynamic UI container solution provides:

1. **✅ Runtime Flexibility**: UI path configurable at container startup
2. **✅ S3 Integration**: Automatic download of build files from S3
3. **✅ No Build Stage**: Uses pre-built files, reducing image size
4. **✅ Dynamic Routing**: Nginx configuration generated at runtime
5. **✅ Production Ready**: Includes health checks, security headers, and caching

**Perfect for scenarios where:**
- UI path needs to be determined at deployment time
- Build files are stored in S3
- Multiple environments need different URL structures
- Container images should be environment-agnostic

🎉 **Your dynamic UI container is ready for deployment!**
