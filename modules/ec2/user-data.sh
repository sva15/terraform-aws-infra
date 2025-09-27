#!/bin/bash

# Update system
yum update -y

# Install Docker
amazon-linux-extras install docker -y
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Configure AWS CLI to use instance profile
export AWS_DEFAULT_REGION=${aws_region}

# Login to ECR
aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin ${ecr_repository_url}

# Pull and run the UI container
docker pull ${ecr_repository_url}:latest
docker run -d --name ui-app --restart unless-stopped -p 80:${container_port} ${ecr_repository_url}:latest

# Create a simple health check script
cat > /home/ec2-user/health-check.sh << 'EOF'
#!/bin/bash
if curl -f http://localhost:80 > /dev/null 2>&1; then
    echo "$(date): UI application is healthy"
else
    echo "$(date): UI application is not responding, restarting container..."
    docker restart ui-app
fi
EOF

chmod +x /home/ec2-user/health-check.sh

# Add health check to crontab (every 5 minutes)
echo "*/5 * * * * /home/ec2-user/health-check.sh >> /var/log/ui-health.log 2>&1" | crontab -

# Create log rotation for health check logs
cat > /etc/logrotate.d/ui-health << 'EOF'
/var/log/ui-health.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
}
EOF

echo "UI server setup completed" > /var/log/user-data.log
