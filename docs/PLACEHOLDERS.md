# Placeholders Reference

This document lists all placeholders that need to be replaced before deployment.

## Parameter Files

### environments/staging/parameters.json

| Placeholder | Description | Example |
|-------------|-------------|---------|
| `PLACEHOLDER_DB_USERNAME` | Database admin username | `dbadmin` |
| `PLACEHOLDER_DB_PASSWORD` | Database admin password (min 8 chars) | `MySecurePass123!` |
| `PLACEHOLDER_GITHUB_OWNER` | GitHub organization or username | `my-company` |
| `arn:aws:codestar-connections:REGION:ACCOUNT_ID:connection/PLACEHOLDER_CONNECTION_ID` | CodeStar Connection ARN | `arn:aws:codestar-connections:us-east-1:123456789012:connection/abc-123` |
| `PLACEHOLDER_MODULE1_REPO_NAME` | GitHub repo name for Module 1 | `frontend-app` |
| `PLACEHOLDER_MODULE2_REPO_NAME` | GitHub repo name for Module 2 | `api-gateway` |
| `PLACEHOLDER_MODULE3_REPO_NAME` | GitHub repo name for Module 3 | `auth-service` |
| `PLACEHOLDER_MODULE4_REPO_NAME` | GitHub repo name for Module 4 | `worker-service` |
| `PLACEHOLDER_S3_BUCKET_NAME` | S3 bucket for CloudFormation templates | `my-company-cfn-templates` |

### environments/production/parameters.json

Same as staging, plus:

| Placeholder | Description | Example |
|-------------|-------------|---------|
| `arn:aws:acm:REGION:ACCOUNT_ID:certificate/PLACEHOLDER_CERTIFICATE_ID` | ACM certificate ARN | `arn:aws:acm:us-east-1:123456789012:certificate/xyz-789` |

## CloudFormation Templates

### cloudformation/cicd/codepipeline.yaml

| Placeholder | Description | Example |
|-------------|-------------|---------|
| `PLACEHOLDER_GITHUB_OWNER` | GitHub organization or username | `my-company` |
| `PLACEHOLDER_REPO_NAME` | GitHub repository name | `my-app` |
| `PLACEHOLDER_CODESTAR_CONNECTION_ARN` | CodeStar Connection ARN | `arn:aws:codestar-connections:...` |

## AWS Resources to Create

Before deployment, you need to create these AWS resources:

### 1. S3 Bucket
```bash
aws s3 mb s3://YOUR_BUCKET_NAME --region YOUR_REGION
```

### 2. CodeStar Connection
- AWS Console → Developer Tools → Settings → Connections
- Create connection for GitHub
- Authorize AWS to access your GitHub organization

### 3. Secrets Manager Secrets
```bash
# Staging database password
aws secretsmanager create-secret \
    --name staging/database-password \
    --secret-string "YOUR_PASSWORD"

# Production database password
aws secretsmanager create-secret \
    --name production/database-password \
    --secret-string "YOUR_PASSWORD"
```

### 4. ACM Certificate (Production)
- AWS Console → Certificate Manager
- Request public certificate
- Validate via DNS
- Note the ARN

## Quick Find & Replace

### For Staging

```bash
# In environments/staging/parameters.json, replace:
PLACEHOLDER_DB_USERNAME        → your_db_username
PLACEHOLDER_DB_PASSWORD        → your_secure_password
PLACEHOLDER_GITHUB_OWNER       → your_github_org
PLACEHOLDER_CONNECTION_ID      → actual_connection_id
PLACEHOLDER_MODULE1_REPO_NAME  → module1_repo
PLACEHOLDER_MODULE2_REPO_NAME  → module2_repo
PLACEHOLDER_MODULE3_REPO_NAME  → module3_repo
PLACEHOLDER_MODULE4_REPO_NAME  → module4_repo
PLACEHOLDER_S3_BUCKET_NAME     → your_s3_bucket
REGION                         → us-east-1 (or your region)
ACCOUNT_ID                     → your_aws_account_id
```

### For Production

Same as staging, plus:
```bash
PLACEHOLDER_CERTIFICATE_ID     → your_acm_certificate_id
```

## Validation Checklist

Before deploying, verify:

- [ ] All PLACEHOLDER values replaced in staging/parameters.json
- [ ] All PLACEHOLDER values replaced in production/parameters.json
- [ ] S3 bucket created and accessible
- [ ] CodeStar Connection created and authorized
- [ ] Secrets created in Secrets Manager
- [ ] (Production) ACM certificate validated and ready
- [ ] Templates uploaded to S3 bucket
- [ ] GitHub repositories exist with Dockerfile in each

## Common Mistakes

1. **Forgetting REGION in ARNs**: Replace `REGION` with actual region (e.g., `us-east-1`)
2. **Forgetting ACCOUNT_ID in ARNs**: Replace with your 12-digit AWS account ID
3. **Using weak passwords**: Database passwords must be at least 8 characters
4. **Branch name mismatch**: Staging uses `develop`, Production uses `main`
5. **Missing Dockerfile**: Each repository needs a Dockerfile in the root
