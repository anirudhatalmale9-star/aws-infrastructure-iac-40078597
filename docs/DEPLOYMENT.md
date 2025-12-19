# Deployment Guide

This guide provides step-by-step instructions for deploying the infrastructure.

## Prerequisites

### 1. AWS Account Setup
- AWS account with administrative access
- AWS CLI installed and configured
- Region selected (recommended: us-east-1 or your preferred region)

### 2. Create S3 Bucket for Templates
```bash
# Replace PLACEHOLDER values
aws s3 mb s3://YOUR_BUCKET_NAME --region YOUR_REGION
```

### 3. Create GitHub CodeStar Connection

1. Go to AWS Console → Developer Tools → Settings → Connections
2. Click "Create connection"
3. Select "GitHub" as the provider
4. Name the connection (e.g., "github-connection")
5. Click "Connect to GitHub" and authorize AWS
6. Note the Connection ARN for later use

### 4. Create Secrets in AWS Secrets Manager

```bash
# Database password secret (staging)
aws secretsmanager create-secret \
    --name staging/database-password \
    --secret-string "YOUR_STAGING_DB_PASSWORD" \
    --region YOUR_REGION

# Database password secret (production)
aws secretsmanager create-secret \
    --name production/database-password \
    --secret-string "YOUR_PRODUCTION_DB_PASSWORD" \
    --region YOUR_REGION
```

### 5. (Production Only) Create SSL Certificate

1. Go to AWS Console → Certificate Manager
2. Click "Request a certificate"
3. Select "Request a public certificate"
4. Enter your domain name
5. Complete DNS validation
6. Note the Certificate ARN

## Deployment Steps

### Step 1: Update Parameter Files

Edit the parameter files and replace all placeholders:

**environments/staging/parameters.json:**
```json
[
  {"ParameterKey": "DBMasterUsername", "ParameterValue": "dbadmin"},
  {"ParameterKey": "DBMasterPassword", "ParameterValue": "your-secure-password"},
  {"ParameterKey": "GitHubOwner", "ParameterValue": "your-github-org"},
  {"ParameterKey": "GitHubConnectionArn", "ParameterValue": "arn:aws:codestar-connections:..."},
  {"ParameterKey": "Module1Repo", "ParameterValue": "module-1-repo"},
  {"ParameterKey": "Module2Repo", "ParameterValue": "module-2-repo"},
  {"ParameterKey": "Module3Repo", "ParameterValue": "module-3-repo"},
  {"ParameterKey": "Module4Repo", "ParameterValue": "module-4-repo"},
  {"ParameterKey": "CertificateArn", "ParameterValue": ""},
  {"ParameterKey": "TemplateS3Bucket", "ParameterValue": "your-s3-bucket"}
]
```

### Step 2: Upload Templates to S3

```bash
# From the project root directory
aws s3 sync cloudformation/ s3://YOUR_BUCKET_NAME/cloudformation/ --region YOUR_REGION
```

### Step 3: Deploy Staging Environment

```bash
# Deploy the staging master stack
aws cloudformation create-stack \
    --stack-name staging-infrastructure \
    --template-body file://environments/staging/main.yaml \
    --parameters file://environments/staging/parameters.json \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
    --region YOUR_REGION

# Monitor stack creation
aws cloudformation wait stack-create-complete \
    --stack-name staging-infrastructure \
    --region YOUR_REGION

# Get stack outputs
aws cloudformation describe-stacks \
    --stack-name staging-infrastructure \
    --query 'Stacks[0].Outputs' \
    --region YOUR_REGION
```

### Step 4: Push Initial Docker Images

Before the ECS services can start, you need to push initial Docker images:

```bash
# Login to ECR
aws ecr get-login-password --region YOUR_REGION | docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.YOUR_REGION.amazonaws.com

# For each module, build and push (example for module-1)
cd /path/to/module-1
docker build -t YOUR_ACCOUNT_ID.dkr.ecr.YOUR_REGION.amazonaws.com/staging/module-1:latest .
docker push YOUR_ACCOUNT_ID.dkr.ecr.YOUR_REGION.amazonaws.com/staging/module-1:latest
```

### Step 5: Verify Deployment

```bash
# Check ECS services
aws ecs list-services --cluster staging-cluster --region YOUR_REGION

# Check ALB DNS
aws cloudformation describe-stacks \
    --stack-name staging-infrastructure \
    --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' \
    --output text \
    --region YOUR_REGION
```

### Step 6: Deploy Production Environment

```bash
# Update production parameters first!
# Then deploy
aws cloudformation create-stack \
    --stack-name production-infrastructure \
    --template-body file://environments/production/main.yaml \
    --parameters file://environments/production/parameters.json \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
    --region YOUR_REGION
```

## Post-Deployment Configuration

### Configure DNS

Point your domain to the ALB DNS name using a CNAME or Route 53 alias record.

### Set Up Monitoring (Optional)

The infrastructure includes CloudWatch Container Insights. For additional monitoring:

1. Create CloudWatch Dashboards
2. Set up SNS topics for alerts
3. Configure CloudWatch Alarms for:
   - ECS CPU/Memory utilization
   - RDS connections and storage
   - ALB response times and error rates

## Updating Infrastructure

### Update Stack

```bash
aws cloudformation update-stack \
    --stack-name staging-infrastructure \
    --template-body file://environments/staging/main.yaml \
    --parameters file://environments/staging/parameters.json \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
    --region YOUR_REGION
```

### View Change Set (Safe Update)

```bash
aws cloudformation create-change-set \
    --stack-name staging-infrastructure \
    --template-body file://environments/staging/main.yaml \
    --parameters file://environments/staging/parameters.json \
    --change-set-name my-changes \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
    --region YOUR_REGION

# Review changes
aws cloudformation describe-change-set \
    --stack-name staging-infrastructure \
    --change-set-name my-changes \
    --region YOUR_REGION

# Execute if satisfied
aws cloudformation execute-change-set \
    --stack-name staging-infrastructure \
    --change-set-name my-changes \
    --region YOUR_REGION
```

## Cleanup

### Delete Stack

```bash
# WARNING: This will delete all resources!

# For staging (no deletion protection)
aws cloudformation delete-stack \
    --stack-name staging-infrastructure \
    --region YOUR_REGION

# For production, first disable deletion protection on RDS
# Then delete the stack
```

## Troubleshooting

### Stack Creation Failed

1. Check CloudFormation events:
```bash
aws cloudformation describe-stack-events \
    --stack-name staging-infrastructure \
    --region YOUR_REGION
```

2. Common issues:
   - Missing IAM permissions
   - S3 bucket not accessible
   - Invalid parameter values
   - Resource limits reached

### ECS Service Not Starting

1. Check ECS service events:
```bash
aws ecs describe-services \
    --cluster staging-cluster \
    --services staging-module-1 \
    --region YOUR_REGION
```

2. Check task logs in CloudWatch:
```bash
aws logs get-log-events \
    --log-group-name /ecs/staging \
    --log-stream-prefix module-1 \
    --region YOUR_REGION
```

### Pipeline Not Triggering

1. Verify GitHub connection is authorized
2. Check CodePipeline execution history
3. Ensure branch name matches configuration
