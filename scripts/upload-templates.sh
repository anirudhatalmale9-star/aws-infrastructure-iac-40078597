#!/bin/bash

# Script to upload CloudFormation templates to S3
# Usage: ./upload-templates.sh <s3-bucket-name> [region]

set -e

S3_BUCKET=$1
REGION=${2:-us-east-1}

if [[ -z "$S3_BUCKET" ]]; then
    echo "Usage: ./upload-templates.sh <s3-bucket-name> [region]"
    exit 1
fi

echo "Uploading templates to s3://$S3_BUCKET..."

# Upload all CloudFormation templates
aws s3 sync cloudformation/ "s3://$S3_BUCKET/cloudformation/" \
    --region "$REGION" \
    --exclude "*.template" \
    --exclude ".DS_Store"

echo "Templates uploaded successfully!"
echo ""
echo "Template URLs:"
echo "  - https://$S3_BUCKET.s3.amazonaws.com/cloudformation/networking/vpc.yaml"
echo "  - https://$S3_BUCKET.s3.amazonaws.com/cloudformation/networking/security-groups.yaml"
echo "  - https://$S3_BUCKET.s3.amazonaws.com/cloudformation/database/rds.yaml"
echo "  - https://$S3_BUCKET.s3.amazonaws.com/cloudformation/cache/elasticache.yaml"
echo "  - https://$S3_BUCKET.s3.amazonaws.com/cloudformation/compute/ecs-cluster.yaml"
echo "  - https://$S3_BUCKET.s3.amazonaws.com/cloudformation/compute/ecs-service.yaml"
echo "  - https://$S3_BUCKET.s3.amazonaws.com/cloudformation/loadbalancer/alb.yaml"
echo "  - https://$S3_BUCKET.s3.amazonaws.com/cloudformation/cicd/codepipeline.yaml"
