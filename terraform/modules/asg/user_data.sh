#!/bin/bash
yum update -y
yum install -y docker

# Start Docker service
systemctl start docker
systemctl enable docker

# Add ec2-user to docker group
usermod -a -G docker ec2-user

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Login to ECR
aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin ${ecr_repository_url}

# Get database password from Secrets Manager
DB_PASSWORD=$(aws secretsmanager get-secret-value --secret-id ${project_name}-${environment}-db-password --query SecretString --output text --region ${aws_region})

# Create environment file for the application
cat > /home/ec2-user/.env << EOF
DB_HOST=${db_endpoint}
DB_NAME=${db_name}
DB_USER=${db_username}
DB_PASSWORD=$DB_PASSWORD
EOF

# Pull and run the application container
docker pull ${ecr_repository_url}:latest
docker run -d --name safle-app --env-file /home/ec2-user/.env -p 80:3000 ${ecr_repository_url}:latest

# Create a simple health check endpoint (if not provided by the app)
mkdir -p /var/www/html/health
echo "OK" > /var/www/html/health/index.html

# Setup log rotation
echo '#!/bin/bash
docker logs safle-app > /var/log/safle-app.log 2>&1
find /var/log -name "*.log" -mtime +7 -delete
' > /etc/cron.daily/docker-logs
chmod +x /etc/cron.daily/docker-logs

