#!/bin/bash

# Log all output
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "Starting user-data script execution..."

# Update system
apt-get update -y
apt-get upgrade -y

# Install required packages
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    unzip \
    postgresql-client

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Start and enable Docker
systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Configure AWS CLI to use instance profile
export AWS_DEFAULT_REGION=${aws_region}

# Create application directory
mkdir -p /opt/app
cd /opt/app

# Create environment file for Docker Compose
cat > .env << EOF
POSTGRES_DB_NAME=${postgres_db_name}
POSTGRES_USER=${postgres_user}
POSTGRES_PASSWORD=${postgres_password}
PGADMIN_EMAIL=${pgadmin_email}
PGADMIN_PASSWORD=${pgadmin_password}
POSTGRES_PORT=${postgres_port}
PGADMIN_PORT=${pgadmin_port}
ECR_REPOSITORY_URL=${ecr_repository_url}
UI_CONTAINER_PORT=${container_port}
EOF

# Copy Docker Compose configuration for UI application only
cat > docker-compose.yml << 'COMPOSE_EOF'
version: '3.8'

services:
  ui-app:
    image: $${ECR_REPOSITORY_URL}:latest
    container_name: ui-app
    restart: unless-stopped
    ports:
      - "80:$${UI_CONTAINER_PORT}"
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:$${UI_CONTAINER_PORT}/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s

networks:
  app-network:
    driver: bridge
COMPOSE_EOF

# Create directories for application
mkdir -p logs

# Login to ECR and start UI application
echo "Starting UI application deployment..."
aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin ${ecr_repository_url}

# Start UI application using Docker Compose
echo "Starting UI application..."
docker-compose up -d ui-app

# Create health check script
cat > /home/ubuntu/health-check.sh << 'HEALTH_EOF'
#!/bin/bash
LOG_FILE="/var/log/health-check.log"

check_service() {
    local service_name=$1
    local url=$2
    
    if curl -f $url > /dev/null 2>&1; then
        echo "$(date): $service_name is healthy" >> $LOG_FILE
        return 0
    else
        echo "$(date): $service_name is not responding, restarting..." >> $LOG_FILE
        docker restart $service_name
        return 1
    fi
}

# Check UI application
check_service "ui-app" "http://localhost:80/health"
HEALTH_EOF

chmod +x /home/ubuntu/health-check.sh
chown ubuntu:ubuntu /home/ubuntu/health-check.sh

# Add health check to crontab (every 5 minutes)
(crontab -l 2>/dev/null; echo "*/5 * * * * /home/ubuntu/health-check.sh") | crontab -

# Create log rotation for health check logs
cat > /etc/logrotate.d/health-check << 'LOGROTATE_EOF'
/var/log/health-check.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 ubuntu ubuntu
}
LOGROTATE_EOF

# Set proper ownership
chown -R ubuntu:ubuntu /opt/app

echo "Setup completed successfully!" 
echo "Services available:"
echo "- UI Application: http://$(curl -s http://169.254.169.254/latest/meta-data/private-ipv4) (private IP)"
echo "- Instance has no public IP address - access via private network only"
