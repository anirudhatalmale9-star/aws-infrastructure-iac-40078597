# Deployment Guide

This guide explains how to deploy the complete infrastructure using the **single root CloudFormation template** (`main.yaml`).

## Key Feature: Single Stack Deployment

The entire infrastructure is deployed via **ONE** CloudFormation stack using nested stacks. No manual stack ordering or sequencing is required.

## Prerequisites

### 1. AWS Account Setup
- AWS account with appropriate permissions
- AWS CLI installed and configured (optional, for CLI deployment)
- Region: us-west-2 (or your preferred region)

### 2. Create S3 Bucket for Templates
```bash
aws s3 mb s3://my-cfn-templates-ACCOUNT_ID --region us-west-2
```

### 3. Create GitHub CodeStar Connection
1. Go to AWS Console → Developer Tools → Settings → Connections
2. Click "Create connection"
3. Select "GitHub" as the provider
4. Name the connection (e.g., "github-connection")
5. Click "Connect to GitHub" and authorize AWS
6. Note the Connection ARN

### 4. (Optional) Create Route53 Hosted Zone
If you want DNS records and SSL:
1. Go to Route53 Console → Hosted Zones
2. Create a hosted zone for your domain
3. Note the Hosted Zone ID

## Deployment via Console (Recommended)

### Step 1: Upload Templates to S3

1. Download/clone this repository
2. Go to S3 Console → your bucket
3. Click "Upload" → "Add folder" → select the `cloudformation/` folder
4. Upload the `main.yaml` file to the bucket root
5. Click "Upload"

### Step 2: Create Stack

1. Go to CloudFormation Console: https://console.aws.amazon.com/cloudformation
2. Click **"Create stack"** → **"With new resources (standard)"**
3. Select **"Amazon S3 URL"**
4. Enter: `https://YOUR_BUCKET.s3.YOUR_REGION.amazonaws.com/main.yaml`
5. Click **"Next"**

### Step 3: Configure Parameters

**Stack name:** `my-app-staging` (or your preferred name)

**Required Parameters:**

| Parameter | Description | Example |
|-----------|-------------|---------|
| EnvironmentName | `staging` or `production` | `staging` |
| TemplateS3Bucket | S3 bucket name (no s3://) | `my-cfn-templates-123456789012` |
| DBMasterUsername | Database admin username | `dbadmin` |
| DBMasterPassword | Database password (min 8 chars) | `MySecurePass123!` |
| GitHubOwner | GitHub org or username | `my-company` |
| GitHubConnectionArn | CodeStar Connection ARN | `arn:aws:codestar-connections:...` |
| Module1Repo | Repository name for Module 1 | `module-1-service` |
| Module2Repo | Repository name for Module 2 | `module-2-service` |
| Module3Repo | Repository name for Module 3 | `module-3-service` |
| Module4Repo | Repository name for Module 4 | `module-4-service` |

**Optional Parameters (DNS/SSL):**

| Parameter | Description | Default |
|-----------|-------------|---------|
| HostedZoneId | Route53 Hosted Zone ID | (empty - skip DNS) |
| DomainName | Base domain (e.g., example.com) | (empty) |
| CertificateArn | Existing ACM Certificate ARN | (empty) |
| CreateCertificate | Create new ACM certificate | `false` |
| AlarmEmail | Email for CloudWatch alerts | (empty) |

6. Click **"Next"**

### Step 4: Configure Stack Options

1. **Permissions**: Select your IAM role (e.g., `Freelancer-Cfn-Execution-Role`)
2. Scroll down and check: ✅ **"I acknowledge that AWS CloudFormation might create IAM resources with custom names"**
3. Click **"Next"**

### Step 5: Review and Create

1. Review all settings
2. Click **"Submit"**

### Step 6: Wait for Completion

The stack will automatically create all resources in the correct order:
- VPC with subnets, NAT gateways, route tables (~3 min)
- Security Groups (~1 min)
- ECS Cluster, ECR Repositories, IAM Roles (~2 min)
- RDS PostgreSQL Database (~10-15 min)
- ElastiCache Redis Cluster (~5-10 min)
- Application Load Balancer with Target Groups (~2 min)
- 4 ECS Services (~5 min)
- 4 CI/CD Pipelines (~3 min)
- CloudWatch Alarms and Dashboard (~1 min)
- (Optional) ACM Certificate (~5-10 min for validation)
- (Optional) Route53 DNS Records (~1 min)

**Total deployment time: ~25-35 minutes**

## Deployment via CLI

```bash
# 1. Upload templates
aws s3 sync cloudformation/ s3://YOUR_BUCKET/cloudformation/
aws s3 cp main.yaml s3://YOUR_BUCKET/main.yaml

# 2. Deploy staging environment
aws cloudformation create-stack \
  --stack-name my-app-staging \
  --template-url https://YOUR_BUCKET.s3.us-west-2.amazonaws.com/main.yaml \
  --parameters \
    ParameterKey=EnvironmentName,ParameterValue=staging \
    ParameterKey=TemplateS3Bucket,ParameterValue=YOUR_BUCKET \
    ParameterKey=DBMasterUsername,ParameterValue=dbadmin \
    ParameterKey=DBMasterPassword,ParameterValue=YOUR_PASSWORD \
    ParameterKey=GitHubOwner,ParameterValue=YOUR_ORG \
    ParameterKey=GitHubConnectionArn,ParameterValue=YOUR_CONNECTION_ARN \
    ParameterKey=Module1Repo,ParameterValue=module-1-repo \
    ParameterKey=Module2Repo,ParameterValue=module-2-repo \
    ParameterKey=Module3Repo,ParameterValue=module-3-repo \
    ParameterKey=Module4Repo,ParameterValue=module-4-repo \
  --capabilities CAPABILITY_NAMED_IAM \
  --role-arn arn:aws:iam::ACCOUNT_ID:role/YOUR_CFN_ROLE \
  --region us-west-2

# 3. Wait for completion
aws cloudformation wait stack-create-complete \
  --stack-name my-app-staging \
  --region us-west-2

# 4. Get outputs
aws cloudformation describe-stacks \
  --stack-name my-app-staging \
  --query 'Stacks[0].Outputs' \
  --output table \
  --region us-west-2
```

## Deploy Production

Use the same process with `EnvironmentName=production`:

Production environment automatically gets:
- **Larger instances**: db.t3.small (RDS), cache.t3.small (Redis)
- **Multi-AZ**: RDS deployed across availability zones
- **Higher capacity**: 2 ECS tasks per service (vs 1 for staging)
- **More storage**: 50GB RDS (vs 20GB for staging)
- **Production branch**: CI/CD uses `main` branch (vs `develop`)
- **Deletion protection**: Enabled on RDS

## Deploy with DNS and SSL

```bash
aws cloudformation create-stack \
  --stack-name my-app-staging \
  --template-url https://YOUR_BUCKET.s3.us-west-2.amazonaws.com/main.yaml \
  --parameters \
    ParameterKey=EnvironmentName,ParameterValue=staging \
    ParameterKey=TemplateS3Bucket,ParameterValue=YOUR_BUCKET \
    ParameterKey=HostedZoneId,ParameterValue=Z1234567890ABC \
    ParameterKey=DomainName,ParameterValue=example.com \
    ParameterKey=CreateCertificate,ParameterValue=true \
    ... other parameters ... \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-west-2
```

This will create:
- ACM certificate with DNS validation
- Route53 A records: `staging.example.com`, `m1-staging.example.com`, etc.
- ALB HTTPS listener (port 443) with TLS 1.3

## Stack Outputs

After deployment, check the Outputs tab for:

| Output | Description |
|--------|-------------|
| LoadBalancerDNS | ALB DNS name |
| LoadBalancerUrl | Application URL |
| DatabaseEndpoint | RDS connection endpoint |
| CacheEndpoint | Redis connection endpoint |
| ECSClusterName | ECS cluster name |
| Module1-4ECRRepository | ECR repository URIs |
| CloudWatchDashboardUrl | Monitoring dashboard link |

## Post-Deployment: Push Initial Docker Images

ECS services will fail health checks until you push images:

```bash
# Login to ECR
aws ecr get-login-password --region us-west-2 | \
  docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com

# Build and push each module
docker build -t ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com/staging/module-1:latest ./module-1
docker push ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com/staging/module-1:latest

# Repeat for module-2, module-3, module-4
```

Or trigger CI/CD pipelines by pushing code to your GitHub repositories.

## Cleanup

```bash
# Delete the stack (all resources deleted automatically)
aws cloudformation delete-stack --stack-name my-app-staging --region us-west-2

# Wait for deletion
aws cloudformation wait stack-delete-complete --stack-name my-app-staging --region us-west-2
```

**Note:** RDS creates a final snapshot before deletion (DeletionPolicy: Snapshot).

## Troubleshooting

### Stack Creation Failed

1. Go to CloudFormation Console → your stack → Events tab
2. Find the red "CREATE_FAILED" event
3. Check the "Status reason" column

### Nested Stack Failed

1. In Events tab, find the failed nested stack (e.g., "DatabaseStack")
2. Click on the Physical ID link to go to the nested stack
3. Check that stack's Events tab for the actual error

### Common Issues

| Issue | Solution |
|-------|----------|
| S3 access denied | Verify bucket policy allows CloudFormation access |
| IAM role invalid | Ensure the role has CloudFormation and required service permissions |
| Parameter validation failed | Check parameter values match constraints |
| Resource limit exceeded | Request limit increase via AWS Support |
| Certificate validation timeout | Ensure HostedZoneId matches DomainName |
