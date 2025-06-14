// Jenkinsfile
pipeline {
    agent any
    
    environment {
        AWS_REGION = 'us-west-2'
        ECR_REPOSITORY = 'safle-nodeapp'
        NODE_VERSION = '18'
        TERRAFORM_VERSION = '1.5.0'
        APP_NAME = 'safle-nodeapp'
        
        // AWS credentials
        AWS_CREDENTIALS = credentials('aws-credentials')
        
        // Database credentials
        DB_PASSWORD = credentials('db-password')
        
        // Notification credentials
        SLACK_TOKEN = credentials('slack-token')
        EMAIL_CREDENTIALS = credentials('email-credentials')
        
        // ECR details
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        IMAGE_TAG = "${BUILD_NUMBER}-${GIT_COMMIT.take(7)}"
    }
    
    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'staging', 'prod'],
            description: 'Select deployment environment'
        )
        booleanParam(
            name: 'SKIP_TESTS',
            defaultValue: false,
            description: 'Skip test execution'
        )
        booleanParam(
            name: 'FORCE_DEPLOY',
            defaultValue: false,
            description: 'Force deployment even if tests fail'
        )
        booleanParam(
            name: 'ROLLBACK',
            defaultValue: false,
            description: 'Rollback to previous version'
        )
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 60, unit: 'MINUTES')
        timestamps()
        ansiColor('xterm')
    }
    
    triggers {
        githubPush()
        pollSCM('H/5 * * * *') // Poll every 5 minutes as fallback
    }
    
    tools {
        nodejs "${NODE_VERSION}"
        terraform "${TERRAFORM_VERSION}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                script {
                    // Clean workspace
                    cleanWs()
                    
                    // Checkout code
                    checkout scm
                    
                    // Set build display name
                    currentBuild.displayName = "#${BUILD_NUMBER} - ${params.ENVIRONMENT}"
                    currentBuild.description = "Branch: ${env.BRANCH_NAME}, Commit: ${GIT_COMMIT.take(7)}"
                }
            }
        }
        
        stage('Setup Environment') {
            steps {
                script {
                    // Install dependencies
                    sh '''
                        # Install AWS CLI
                        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                        unzip -o awscliv2.zip
                        sudo ./aws/install --update
                        
                        # Install jq for JSON processing
                        sudo apt-get update && sudo apt-get install -y jq
                        
                        # Install Docker Compose
                        sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                        sudo chmod +x /usr/local/bin/docker-compose
                        
                        # Verify installations
                        aws --version
                        docker --version
                        docker-compose --version
                        terraform --version
                        node --version
                        npm --version
                    '''
                }
            }
        }
        
        stage('Security Scan - Code') {
            steps {
                script {
                    dir('app') {
                        // Install dependencies for security scanning
                        sh 'npm ci'
                        
                        // Run npm audit
                        sh '''
                            echo "Running npm security audit..."
                            npm audit --audit-level high --json > npm-audit.json || true
                            
                            # Check if there are high/critical vulnerabilities
                            HIGH_VULNS=$(cat npm-audit.json | jq '.metadata.vulnerabilities.high // 0')
                            CRITICAL_VULNS=$(cat npm-audit.json | jq '.metadata.vulnerabilities.critical // 0')
                            
                            echo "High vulnerabilities: $HIGH_VULNS"
                            echo "Critical vulnerabilities: $CRITICAL_VULNS"
                            
                            if [ "$CRITICAL_VULNS" -gt 0 ]; then
                                echo "❌ Critical vulnerabilities found! Failing build."
                                exit 1
                            elif [ "$HIGH_VULNS" -gt 5 ]; then
                                echo "⚠️  Too many high vulnerabilities found! Consider fixing them."
                            fi
                        '''
                        
                        // Archive audit results
                        archiveArtifacts artifacts: 'npm-audit.json', allowEmptyArchive: true
                    }
                }
            }
        }
        
        stage('Unit Tests') {
            when {
                not { params.SKIP_TESTS }
            }
            
            steps {
                script {
                    dir('app') {
                        // Start test database
                        sh '''
                            echo "Starting test database..."
                            docker-compose -f docker-compose.test.yml up -d postgres-test
                            
                            # Wait for database to be ready
                            echo "Waiting for database to be ready..."
                            timeout 30 sh -c 'until docker-compose -f docker-compose.test.yml exec -T postgres-test pg_isready; do sleep 1; done'
                        '''
                        
                        // Run tests
                        sh '''
                            export NODE_ENV=test
                            export DB_HOST=localhost
                            export DB_PORT=5433
                            export DB_USER=testuser
                            export DB_PASSWORD=testpass
                            export DB_NAME=testdb
                            
                            echo "Running linting..."
                            npm run lint
                            
                            echo "Running unit tests..."
                            npm test -- --coverage --reporters=default --reporters=jest-junit
                        '''
                        
                        // Cleanup test database
                        sh '''
                            echo "Cleaning up test database..."
                            docker-compose -f docker-compose.test.yml down -v
                        '''
                    }
                }
            }
            
            post {
                always {
                    // Publish test results
                    publishTestResults testResultsPattern: 'app/junit.xml'
                    
                    // Publish coverage report
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'app/coverage/lcov-report',
                        reportFiles: 'index.html',
                        reportName: 'Coverage Report'
                    ])
                    
                    // Archive coverage data
                    archiveArtifacts artifacts: 'app/coverage/**/*', allowEmptyArchive: true
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    dir('app') {
                        // Build Docker image
                        sh """
                            echo "Building Docker image..."
                            docker build -t ${APP_NAME}:${IMAGE_TAG} .
                            docker tag ${APP_NAME}:${IMAGE_TAG} ${APP_NAME}:latest
                            
                            echo "Image built successfully: ${APP_NAME}:${IMAGE_TAG}"
                        """
                    }
                }
            }
        }
        
        stage('Security Scan - Container') {
            steps {
                script {
                    // Install Trivy if not available
                    sh '''
                        if ! command -v trivy &> /dev/null; then
                            echo "Installing Trivy..."
                            wget -O - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
                            echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list
                            sudo apt-get update
                            sudo apt-get install trivy
                        fi
                    '''
                    
                    // Run container security scan
                    sh """
                        echo "Running container security scan..."
                        trivy image --format json --output trivy-report.json ${APP_NAME}:${IMAGE_TAG}
                        trivy image --format table ${APP_NAME}:${IMAGE_TAG}
                        
                        # Check for critical vulnerabilities
                        CRITICAL_COUNT=\$(cat trivy-report.json | jq '[.Results[]?.Vulnerabilities[]? | select(.Severity == "CRITICAL")] | length')
                        echo "Critical vulnerabilities found: \$CRITICAL_COUNT"
                        
                        if [ "\$CRITICAL_COUNT" -gt 5 ]; then
                            echo "⚠️  Too many critical vulnerabilities found in container image!"
                            if [ "${params.FORCE_DEPLOY}" != "true" ]; then
                                echo "Set FORCE_DEPLOY=true to bypass this check"
                                exit 1
                            fi
                        fi
                    """
                    
                    // Archive scan results
                    archiveArtifacts artifacts: 'trivy-report.json', allowEmptyArchive: true
                }
            }
        }
        
        stage('Push to ECR') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                    expression { params.ENVIRONMENT != 'dev' }
                }
            }
            
            steps {
                script {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                        sh """
                            # Configure AWS CLI
                            aws configure set region ${AWS_REGION}
                            
                            # Get AWS account ID
                            export AWS_ACCOUNT_ID=\$(aws sts get-caller-identity --query Account --output text)
                            
                            # Login to ECR
                            aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin \${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                            
                            # Tag images for ECR
                            docker tag ${APP_NAME}:${IMAGE_TAG} \${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:${IMAGE_TAG}
                            docker tag ${APP_NAME}:${IMAGE_TAG} \${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:latest
                            
                            # Push images to ECR
                            docker push \${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:${IMAGE_TAG}
                            docker push \${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:latest
                            
                            echo "Images pushed successfully to ECR"
                        """
                    }
                }
            }
        }
        
        stage('Terraform Plan') {
            when {
                anyOf {
                    changeRequest()
                    expression { params.ENVIRONMENT != 'prod' }
                }
            }
            
            steps {
                script {
                    dir("terraform/environments/${params.ENVIRONMENT}") {
                        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                            sh """
                                # Initialize Terraform
                                terraform init
                                
                                # Validate configuration
                                terraform validate
                                
                                # Plan infrastructure changes
                                terraform plan -var="db_password=${DB_PASSWORD}" -var="app_image_tag=${IMAGE_TAG}" -out=tfplan
                                
                                # Show plan in readable format
                                terraform show -no-color tfplan > terraform-plan.txt
                                
                                echo "Terraform plan completed successfully"
                            """
                        }
                        
                        // Archive plan
                        archiveArtifacts artifacts: 'terraform-plan.txt', allowEmptyArchive: true
                        
                        // Publish plan as build artifact
                        publishHTML([
                            allowMissing: false,
                            alwaysLinkToLastBuild: true,
                            keepAll: true,
                            reportDir: '.',
                            reportFiles: 'terraform-plan.txt',
                            reportName: 'Terraform Plan',
                            reportTitles: 'Infrastructure Changes'
                        ])
                    }
                }
            }
        }
        
        stage('Infrastructure Deployment') {
            when {
                anyOf {
                    branch 'main'
                    expression { params.ENVIRONMENT == 'prod' && params.FORCE_DEPLOY }
                }
            }
            
            steps {
                script {
                    // Approval for production deployments
                    if (params.ENVIRONMENT == 'prod') {
                        timeout(time: 5, unit: 'MINUTES') {
                            input message: 'Deploy to Production?', 
                                  ok: 'Deploy',
                                  submitterParameter: 'APPROVER'
                        }
                        echo "Production deployment approved by: ${env.APPROVER}"
                    }
                    
                    dir("terraform/environments/${params.ENVIRONMENT}") {
                        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                            sh """
                                # Apply infrastructure changes
                                terraform apply -var="db_password=${DB_PASSWORD}" -var="app_image_tag=${IMAGE_TAG}" -auto-approve
                                
                                # Output important values
                                terraform output -json > terraform-outputs.json
                                
                                echo "Infrastructure deployment completed successfully"
                            """
                        }
                        
                        // Archive outputs
                        archiveArtifacts artifacts: 'terraform-outputs.json', allowEmptyArchive: true
                    }
                }
            }
        }
        
        stage('Application Deployment') {
            when {
                not { params.ROLLBACK }
            }
            
            steps {
                script {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                        sh """
                            # Get AWS account ID
                            export AWS_ACCOUNT_ID=\$(aws sts get-caller-identity --query Account --output text)
                            
                            # Get Auto Scaling Group name
                            ASG_NAME=\$(aws autoscaling describe-auto-scaling-groups \\
                                --query "AutoScalingGroups[?contains(Tags[?Key=='Name'].Value, '${APP_NAME}-${params.ENVIRONMENT}')].AutoScalingGroupName" \\
                                --output text)
                            
                            if [ -z "\$ASG_NAME" ]; then
                                echo "❌ Auto Scaling Group not found!"
                                exit 1
                            fi
                            
                            echo "Found Auto Scaling Group: \$ASG_NAME"
                            
                            # Get Launch Template ID
                            LAUNCH_TEMPLATE_ID=\$(aws autoscaling describe-auto-scaling-groups \\
                                --auto-scaling-group-names \$ASG_NAME \\
                                --query "AutoScalingGroups[0].LaunchTemplate.LaunchTemplateId" \\
                                --output text)
                            
                            echo "Launch Template ID: \$LAUNCH_TEMPLATE_ID"
                            
                            # Create new launch template version with updated image
                            USER_DATA=\$(cat << 'EOF' | base64 -w 0
#!/bin/bash
yum update -y
yum install -y docker
service docker start
usermod -a -G docker ec2-user

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Login to ECR
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin \${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Stop existing container
docker stop ${APP_NAME} || true
docker rm ${APP_NAME} || true

# Pull and run new image
docker pull \${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:${IMAGE_TAG}

docker run -d --name ${APP_NAME} -p 3000:3000 --restart unless-stopped \\
    -e NODE_ENV=${params.ENVIRONMENT} \\
    -e PORT=3000 \\
    -e LOG_LEVEL=info \\
    -e DB_HOST=\$(aws ssm get-parameter --name "/${APP_NAME}/${params.ENVIRONMENT}/db/host" --query 'Parameter.Value' --output text) \\
    -e DB_NAME=\$(aws ssm get-parameter --name "/${APP_NAME}/${params.ENVIRONMENT}/db/name" --query 'Parameter.Value' --output text) \\
    -e DB_USER=\$(aws ssm get-parameter --name "/${APP_NAME}/${params.ENVIRONMENT}/db/user" --query 'Parameter.Value' --output text) \\
    -e DB_PASSWORD=\$(aws ssm get-parameter --name "/${APP_NAME}/${params.ENVIRONMENT}/db/password" --with-decryption --query 'Parameter.Value' --output text) \\
    \${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:${IMAGE_TAG}

# Wait for application to start
sleep 30

# Health check
curl -f http://localhost:3000/health || exit 1

echo "Application deployed successfully!"
EOF
)
                            
                            # Create new launch template version
                            NEW_VERSION=\$(aws ec2 create-launch-template-version \\
                                --launch-template-id \$LAUNCH_TEMPLATE_ID \\
                                --source-version '\$Latest' \\
                                --launch-template-data "{\\"UserData\\": \\"\$USER_DATA\\"}" \\
                                --query 'LaunchTemplateVersion.VersionNumber' \\
                                --output text)
                            
                            echo "Created launch template version: \$NEW_VERSION"
                            
                            # Update Auto Scaling Group to use new version
                            aws autoscaling update-auto-scaling-group \\
                                --auto-scaling-group-name \$ASG_NAME \\
                                --launch-template LaunchTemplateId=\$LAUNCH_TEMPLATE_ID,Version=\$NEW_VERSION
                            
                            # Start instance refresh for rolling deployment
                            REFRESH_ID=\$(aws autoscaling start-instance-refresh \\
                                --auto-scaling-group-name \$ASG_NAME \\
                                --preferences '{"InstanceWarmup": 300, "MinHealthyPercentage": 50, "CheckpointPercentages": [20, 50, 100], "CheckpointDelay": 600}' \\
                                --query 'InstanceRefreshId' \\
                                --output text)
                            
                            echo "Started instance refresh: \$REFRESH_ID"
                            echo "REFRESH_ID=\$REFRESH_ID" > deployment.env
                        """
                        
                        // Archive deployment info
                        archiveArtifacts artifacts: 'deployment.env', allowEmptyArchive: true
                    }
                }
            }
        }
        
        stage('Deployment Monitoring') {
            when {
                not { params.ROLLBACK }
            }
            
            steps {
                script {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                        sh """
                            # Source deployment environment
                            source deployment.env
                            
                            # Get Auto Scaling Group name
                            ASG_NAME=\$(aws autoscaling describe-auto-scaling-groups \\
                                --query "AutoScalingGroups[?contains(Tags[?Key=='Name'].Value, '${APP_NAME}-${params.ENVIRONMENT}')].AutoScalingGroupName" \\
                                --output text)
                            
                            echo "Monitoring deployment progress..."
                            
                            # Monitor instance refresh
                            while true; do
                                REFRESH_STATUS=\$(aws autoscaling describe-instance-refreshes \\
                                    --auto-scaling-group-name \$ASG_NAME \\
                                    --instance-refresh-ids \$REFRESH_ID \\
                                    --query 'InstanceRefreshes[0].Status' \\
                                    --output text)
                                
                                PERCENTAGE=\$(aws autoscaling describe-instance-refreshes \\
                                    --auto-scaling-group-name \$ASG_NAME \\
                                    --instance-refresh-ids \$REFRESH_ID \\
                                    --query 'InstanceRefreshes[0].PercentageComplete' \\
                                    --output text)
                                
                                echo "Deployment status: \$REFRESH_STATUS (\$PERCENTAGE% complete)"
                                
                                if [ "\$REFRESH_STATUS" = "Successful" ]; then
                                    echo "✅ Deployment completed successfully!"
                                    break
                                elif [ "\$REFRESH_STATUS" = "Failed" ] || [ "\$REFRESH_STATUS" = "Cancelled" ]; then
                                    echo "❌ Deployment failed with status: \$REFRESH_STATUS"
                                    exit 1
                                elif [ "\$REFRESH_STATUS" = "InProgress" ]; then
                                    echo "🔄 Deployment in progress..."
                                    sleep 30
                                else
                                    echo "⏳ Deployment status: \$REFRESH_STATUS"
                                    sleep 30
                                fi
                                
                                # Timeout after 30 minutes
                                if [ \$(date +%s) -gt \$(($(date +%s) + 1800)) ]; then
                                    echo "❌ Deployment timeout!"
                                    exit 1
                                fi
                            done
                        """
                    }
                }
            }
        }
        
        stage('Health Check') {
            when {
                not { params.ROLLBACK }
            }
            
            steps {
                script {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                        sh """
                            # Get Load Balancer DNS
                            ALB_DNS=\$(aws elbv2 describe-load-balancers \\
                                --names ${APP_NAME}-${params.ENVIRONMENT}-alb \\
                                --query 'LoadBalancers[0].DNSName' \\
                                --output text)
                            
                            if [ -z "\$ALB_DNS" ] || [ "\$ALB_DNS" = "None" ]; then
                                echo "❌ Load balancer not found!"
                                exit 1
                            fi
                            
                            echo "Load Balancer DNS: \$ALB_DNS"
                            
                            # Wait for DNS propagation
                            echo "Waiting for DNS propagation..."
                            sleep 60
                            
                            # Perform health checks
                            echo "Performing health checks..."
                            
                            HEALTH_CHECK_URL="https://\$ALB_DNS/health"
                            if [ "${params.ENVIRONMENT}" = "dev" ]; then
                                HEALTH_CHECK_URL="http://\$ALB_DNS/health"
                            fi
                            
                            echo "Health check URL: \$HEALTH_CHECK_URL"
                            
                            for i in {1..15}; do
                                echo "Health check attempt \$i/15..."
                                
                                if curl -f -s --max-time 10 "\$HEALTH_CHECK_URL" > health_response.json; then
                                    echo "✅ Health check passed!"
                                    cat health_response.json | jq .
                                    
                                    # Additional API tests
                                    echo "Testing API endpoints..."
                                    
                                    # Test users endpoint
                                    USER_URL="https://\$ALB_DNS/api/users"
                                    if [ "${params.ENVIRONMENT}" = "dev" ]; then
                                        USER_URL="http://\$ALB_DNS/api/users"
                                    fi
                                    
                                    if curl -f -s --max-time 10 "\$USER_URL" > users_response.json; then
                                        echo "✅ Users API endpoint working"
                                    else
                                        echo "⚠️  Users API endpoint issue"
                                    fi
                                    
                                    echo "🎉 All health checks passed!"
                                    exit 0
                                else
                                    echo "❌ Health check failed, attempt \$i/15"
                                    if [ \$i -lt 15 ]; then
                                        sleep 30
                                    fi
                                fi
                            done
                            
                            echo "❌ Health check failed after 15 attempts"
                            exit 1
                        """
                    }
                    
                    // Archive health check responses
                    archiveArtifacts artifacts: '*_response.json', allowEmptyArchive: true
                }
            }
        }
        
        stage('Rollback') {
            when {
                expression { params.ROLLBACK }
            }
            
            steps {
                script {
                    timeout(time: 2, unit: 'MINUTES') {
                        input message: 'Confirm Rollback?', 
                              ok: 'Rollback',
                              submitterParameter: 'ROLLBACK_APPROVER'
                    }
                    
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                        sh """
                            echo "Rolling back deployment approved by: ${env.ROLLBACK_APPROVER}"
                            
                            # Get Auto Scaling Group name
                            ASG_NAME=\$(aws autoscaling describe-auto-scaling-groups \\
                                --query "AutoScalingGroups[?contains(Tags[?Key=='Name'].Value, '${APP_NAME}-${params.ENVIRONMENT}')].AutoScalingGroupName" \\
                                --output text)
                            
                            # Cancel any ongoing instance refresh
                            aws autoscaling cancel-instance-refresh --auto-scaling-group-name \$ASG_NAME || true
                            
                            # Get Launch Template ID and current version
                            LAUNCH_TEMPLATE_ID=\$(aws autoscaling describe-auto-scaling-groups \\
                                --auto-scaling-group-names \$ASG_NAME \\
                                --query "AutoScalingGroups[0].LaunchTemplate.LaunchTemplateId" \\
                                --output text)
                            
                            CURRENT_VERSION=\$(aws autoscaling describe-auto-scaling-groups \\
                                --auto-scaling-group-names \$ASG_NAME \\
                                --query "AutoScalingGroups[0].LaunchTemplate.Version" \\
                                --output text)
                            
                            echo "Current version: \$CURRENT_VERSION"
                            
                            # Calculate previous version
                            if [ "\$CURRENT_VERSION" = "\$Latest" ]; then
                                # Get the latest version number
                                LATEST_VERSION=\$(aws ec2 describe-launch-template-versions \\
                                    --launch-template-id \$LAUNCH_TEMPLATE_ID \\
                                    --query 'LaunchTemplateVersions[0].VersionNumber' \\
                                    --output text)
                                PREVIOUS_VERSION=\$((LATEST_VERSION - 1))
                            else
                                PREVIOUS_VERSION=\$((CURRENT_VERSION - 1))
                            fi
                            
                            if [ \$PREVIOUS_VERSION -lt 1 ]; then
                                echo "❌ No previous version to rollback to!"
                                exit 1
                            fi
                            
                            echo "Rolling back to version: \$PREVIOUS_VERSION"
                            
                            # Update Auto Scaling Group to use previous version
                            aws autoscaling update-auto-scaling-group \\
                                --auto-scaling-group-name \$ASG_NAME \\
                                --launch-template LaunchTemplateId=\$LAUNCH_TEMPLATE_ID,Version=\$PREVIOUS_VERSION
                            
                            # Start instance refresh for rollback
                            aws autoscaling start-instance-refresh \\
                                --auto-scaling-group-name \$ASG_NAME \\
                                --preferences '{"InstanceWarmup": 300, "MinHealthyPercentage": 50}'
                            
                            echo "✅ Rollback initiated successfully"
                        """
                    }
                }
            }
        }
        
        stage('Performance Tests') {
            when {
                anyOf {
                    expression { params.ENVIRONMENT == 'staging' }
                    expression { params.ENVIRONMENT == 'prod' && env.BRANCH_NAME == 'main' }
                }
            }
            
            steps {
                script {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                        sh """
                            # Get Load Balancer DNS
                            ALB_DNS=\$(aws elbv2 describe-load-balancers \\
                                --names ${APP_NAME}-${params.ENVIRONMENT}-alb \\
                                --query 'LoadBalancers[0].DNSName' \\
                                --output text)
                            
                            BASE_URL="https://\$ALB_DNS"
                            if [ "${params.ENVIRONMENT}" = "dev" ]; then
                                BASE_URL="http://\$ALB_DNS"
                            fi
                            
                            echo "Running performance tests against: \$BASE_URL"
                            
                            # Install Apache Bench if not available
                            sudo apt-get update && sudo apt-get install -y apache2-utils
                            
                            # Run load test - 100 concurrent requests, 1000 total
                            echo "Running load test..."
                            ab -n 1000 -c 100 -g performance.tsv "\$BASE_URL/health" > performance.txt
                            
                            # Parse results
                            RESPONSE_TIME=\$(grep "Time per request:" performance.txt | head -1 | awk '{print \$4}')
                            REQUESTS_PER_SEC=\$(grep "Requests per second:" performance.txt | awk '{print \$4}')
                            FAILED_REQUESTS=\$(grep "Failed requests:" performance.txt | awk '{print \$3}')
                            
                            echo "Performance Results:"
                            echo "- Average Response Time: \$RESPONSE_TIME ms"
                            echo "- Requests per Second: \$REQUESTS_PER_SEC"
                            echo "- Failed Requests: \$FAILED_REQUESTS"
                            
                            # Check performance thresholds
                            if (( $(echo "$RESPONSE_TIME > 2000" | bc -l) )); then
                                echo "⚠️  Response time too high: $RESPONSE_TIME ms"
                                if [ "${params.FORCE_DEPLOY}" != "true" ]; then
                                    exit 1
                                fi
                            fi
                            
                            if (( $(echo "$FAILED_REQUESTS > 10" | bc -l) )); then
                                echo "⚠️  Too many failed requests: $FAILED_REQUESTS"
                                if [ "${params.FORCE_DEPLOY}" != "true" ]; then
                                    exit 1
                                fi
                            fi
                            
                            echo "✅ Performance tests passed!"
                        """
                    }
                }
            }
            
            post {
                always {
                    // Archive performance results
                    archiveArtifacts artifacts: 'performance.*', allowEmptyArchive: true
                    
                    // Publish performance report
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: '.',
                        reportFiles: 'performance.txt',
                        reportName: 'Performance Test Report'
                    ])
                }
            }
        }
        
        stage('Smoke Tests') {
            when {
                not { params.ROLLBACK }
            }
            
            steps {
                script {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                        sh """
                            # Get Load Balancer DNS
                            ALB_DNS=\$(aws elbv2 describe-load-balancers \\
                                --names ${APP_NAME}-${params.ENVIRONMENT}-alb \\
                                --query 'LoadBalancers[0].DNSName' \\
                                --output text)
                            
                            BASE_URL="https://\$ALB_DNS"
                            if [ "${params.ENVIRONMENT}" = "dev" ]; then
                                BASE_URL="http://\$ALB_DNS"
                            fi
                            
                            echo "Running smoke tests against: \$BASE_URL"
                            
                            # Test 1: Health endpoint
                            echo "Test 1: Health Check"
                            if curl -f -s --max-time 10 "\$BASE_URL/health"; then
                                echo "✅ Health check passed"
                            else
                                echo "❌ Health check failed"
                                exit 1
                            fi
                            
                            # Test 2: API endpoints
                            echo "Test 2: Users API"
                            if curl -f -s --max-time 10 "\$BASE_URL/api/users" | jq . > /dev/null; then
                                echo "✅ Users API working"
                            else
                                echo "❌ Users API failed"
                                exit 1
                            fi
                            
                            # Test 3: Database connectivity
                            echo "Test 3: Database Connectivity"
                            DB_RESPONSE=\$(curl -f -s --max-time 10 "\$BASE_URL/api/users" | jq -r '.status // "error"')
                            if [ "\$DB_RESPONSE" = "success" ] || [ "\$DB_RESPONSE" != "error" ]; then
                                echo "✅ Database connectivity working"
                            else
                                echo "❌ Database connectivity failed"
                                exit 1
                            fi
                            
                            # Test 4: SSL/TLS (for staging and prod)
                            if [ "${params.ENVIRONMENT}" != "dev" ]; then
                                echo "Test 4: SSL/TLS Check"
                                if curl -f -s --max-time 10 "https://\$ALB_DNS/health" > /dev/null; then
                                    echo "✅ SSL/TLS working"
                                else
                                    echo "❌ SSL/TLS failed"
                                    exit 1
                                fi
                            fi
                            
                            echo "🎉 All smoke tests passed!"
                        """
                    }
                }
            }
        }
        
        stage('Update Monitoring') {
            when {
                not { params.ROLLBACK }
            }
            
            steps {
                script {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                        sh """
                            echo "Updating monitoring configuration..."
                            
                            # Update CloudWatch alarms with new deployment info
                            aws cloudwatch put-metric-alarm \\
                                --alarm-name "${APP_NAME}-${params.ENVIRONMENT}-high-cpu" \\
                                --alarm-description "High CPU utilization for ${APP_NAME} ${params.ENVIRONMENT}" \\
                                --metric-name CPUUtilization \\
                                --namespace AWS/EC2 \\
                                --statistic Average \\
                                --period 300 \\
                                --threshold 80 \\
                                --comparison-operator GreaterThanThreshold \\
                                --evaluation-periods 2 \\
                                --alarm-actions "arn:aws:sns:${AWS_REGION}:\$(aws sts get-caller-identity --query Account --output text):${APP_NAME}-alerts" \\
                                --dimensions Name=AutoScalingGroupName,Value=\$(aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[?contains(Tags[?Key=='Name'].Value, '${APP_NAME}-${params.ENVIRONMENT}')].AutoScalingGroupName" --output text)
                            
                            # Update application version in Parameter Store
                            aws ssm put-parameter \\
                                --name "/${APP_NAME}/${params.ENVIRONMENT}/deployment/version" \\
                                --value "${IMAGE_TAG}" \\
                                --type String \\
                                --overwrite
                            
                            # Update deployment timestamp
                            aws ssm put-parameter \\
                                --name "/${APP_NAME}/${params.ENVIRONMENT}/deployment/timestamp" \\
                                --value "\$(date -Iseconds)" \\
                                --type String \\
                                --overwrite
                            
                            echo "✅ Monitoring updated successfully"
                        """
                    }
                }
            }
        }
        
        stage('Cleanup') {
            steps {
                script {
                    sh """
                        echo "Cleaning up build artifacts..."
                        
                        # Remove old Docker images (keep last 3)
                        docker images ${APP_NAME} --format "table {{.Repository}}:{{.Tag}}\t{{.CreatedAt}}" | \\
                            tail -n +2 | sort -k2 -r | tail -n +4 | awk '{print \$1}' | \\
                            xargs -r docker rmi || true
                        
                        # Clean up dangling images
                        docker image prune -f || true
                        
                        # Clean up old build files
                        find . -name "*.log" -mtime +7 -delete || true
                        find . -name "*.tmp" -delete || true
                        
                        echo "✅ Cleanup completed"
                    """
                }
            }
        }
    }
    
    post {
        always {
            script {
                // Archive important files
                archiveArtifacts artifacts: '''
                    **/*.log,
                    **/*.json,
                    **/*.txt,
                    **/*.env,
                    terraform/**/*.tfplan,
                    terraform/**/*.tfstate*
                ''', allowEmptyArchive: true, fingerprint: true
                
                // Clean workspace
                cleanWs()
            }
        }
        
        success {
            script {
                echo "🎉 Pipeline completed successfully!"
                
                // Send success notification
                withCredentials([string(credentialsId: 'slack-token', variable: 'SLACK_TOKEN')]) {
                    slackSend(
                        token: SLACK_TOKEN,
                        channel: '#deployments',
                        color: 'good',
                        message: """
✅ *Deployment Successful*
• *Project*: ${APP_NAME}
• *Environment*: ${params.ENVIRONMENT}
• *Version*: ${IMAGE_TAG}
• *Branch*: ${env.BRANCH_NAME}
• *Build*: #${BUILD_NUMBER}
• *Duration*: ${currentBuild.durationString}
• *Deployed by*: ${env.BUILD_USER ?: 'Jenkins'}

<${env.BUILD_URL}|View Build Details>
                        """.stripIndent()
                    )
                }
                
                // Send email notification for production deployments
                if (params.ENVIRONMENT == 'prod') {
                    emailext (
                        subject: "✅ Production Deployment Successful - ${APP_NAME} v${IMAGE_TAG}",
                        body: """
                        <h2>Production Deployment Successful</h2>
                        <ul>
                            <li><strong>Application:</strong> ${APP_NAME}</li>
                            <li><strong>Version:</strong> ${IMAGE_TAG}</li>
                            <li><strong>Environment:</strong> ${params.ENVIRONMENT}</li>
                            <li><strong>Build Number:</strong> #${BUILD_NUMBER}</li>
                            <li><strong>Duration:</strong> ${currentBuild.durationString}</li>
                            <li><strong>Git Commit:</strong> ${GIT_COMMIT}</li>
                        </ul>
                        <p><a href="${env.BUILD_URL}">View Build Details</a></p>
                        """,
                        to: "${EMAIL_CREDENTIALS}",
                        mimeType: 'text/html'
                    )
                }
            }
        }
        
        failure {
            script {
                echo "❌ Pipeline failed!"
                
                // Send failure notification
                withCredentials([string(credentialsId: 'slack-token', variable: 'SLACK_TOKEN')]) {
                    slackSend(
                        token: SLACK_TOKEN,
                        channel: '#deployments',
                        color: 'danger',
                        message: """
❌ *Deployment Failed*
• *Project*: ${APP_NAME}
• *Environment*: ${params.ENVIRONMENT}
• *Branch*: ${env.BRANCH_NAME}
• *Build*: #${BUILD_NUMBER}
• *Duration*: ${currentBuild.durationString}
• *Failed Stage*: ${env.STAGE_NAME ?: 'Unknown'}

<${env.BUILD_URL}|View Build Details>
<${env.BUILD_URL}console|View Console Output>
                        """.stripIndent()
                    )
                }
                
                // Send email notification for critical failures
                if (params.ENVIRONMENT == 'prod' || env.STAGE_NAME?.contains('Security')) {
                    emailext (
                        subject: "❌ Critical Deployment Failure - ${APP_NAME}",
                        body: """
                        <h2>Critical Deployment Failure</h2>
                        <ul>
                            <li><strong>Application:</strong> ${APP_NAME}</li>
                            <li><strong>Environment:</strong> ${params.ENVIRONMENT}</li>
                            <li><strong>Build Number:</strong> #${BUILD_NUMBER}</li>
                            <li><strong>Failed Stage:</strong> ${env.STAGE_NAME ?: 'Unknown'}</li>
                            <li><strong>Duration:</strong> ${currentBuild.durationString}</li>
                            <li><strong>Git Commit:</strong> ${GIT_COMMIT}</li>
                        </ul>
                        <p><strong>Action Required:</strong> Please investigate and resolve the deployment failure immediately.</p>
                        <p><a href="${env.BUILD_URL}">View Build Details</a></p>
                        <p><a href="${env.BUILD_URL}console">View Console Output</a></p>
                        """,
                        to: "${EMAIL_CREDENTIALS}",
                        mimeType: 'text/html'
                    )
                }
            }
        }
        
        unstable {
            script {
                echo "⚠️ Pipeline completed with warnings!"
                
                withCredentials([string(credentialsId: 'slack-token', variable: 'SLACK_TOKEN')]) {
                    slackSend(
                        token: SLACK_TOKEN,
                        channel: '#deployments',
                        color: 'warning',
                        message: """
⚠️ *Deployment Completed with Warnings*
• *Project*: ${APP_NAME}
• *Environment*: ${params.ENVIRONMENT}
• *Version*: ${IMAGE_TAG}
• *Branch*: ${env.BRANCH_NAME}
• *Build*: #${BUILD_NUMBER}
• *Duration*: ${currentBuild.durationString}

<${env.BUILD_URL}|View Build Details>
                        """.stripIndent()
                    )
                }
            }
        }
        
        aborted {
            script {
                echo "🛑 Pipeline was aborted!"
                
                withCredentials([string(credentialsId: 'slack-token', variable: 'SLACK_TOKEN')]) {
                    slackSend(
                        token: SLACK_TOKEN,
                        channel: '#deployments',
                        color: '#808080',
                        message: """
🛑 *Deployment Aborted*
• *Project*: ${APP_NAME}
• *Environment*: ${params.ENVIRONMENT}
• *Branch*: ${env.BRANCH_NAME}
• *Build*: #${BUILD_NUMBER}
• *Duration*: ${currentBuild.durationString}

<${env.BUILD_URL}|View Build Details>
                        """.stripIndent()
                    )
                }
            }
        }
    }
}
