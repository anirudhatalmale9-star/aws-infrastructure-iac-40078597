#!/bin/bash

# AWS Infrastructure Deployment Script
# Usage: ./deploy.sh [staging|production] [create|update|delete]

set -e

ENVIRONMENT=${1:-staging}
ACTION=${2:-create}
REGION=${AWS_REGION:-us-east-1}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validate environment
if [[ "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "production" ]]; then
    log_error "Invalid environment. Use 'staging' or 'production'"
    exit 1
fi

# Validate action
if [[ "$ACTION" != "create" && "$ACTION" != "update" && "$ACTION" != "delete" ]]; then
    log_error "Invalid action. Use 'create', 'update', or 'delete'"
    exit 1
fi

STACK_NAME="${ENVIRONMENT}-infrastructure"
TEMPLATE_FILE="environments/${ENVIRONMENT}/main.yaml"
PARAMS_FILE="environments/${ENVIRONMENT}/parameters.json"

log_info "Environment: $ENVIRONMENT"
log_info "Action: $ACTION"
log_info "Region: $REGION"
log_info "Stack Name: $STACK_NAME"

# Check if parameter file has placeholders
if grep -q "PLACEHOLDER" "$PARAMS_FILE"; then
    log_error "Parameter file contains PLACEHOLDER values!"
    log_error "Please update $PARAMS_FILE before deploying."
    exit 1
fi

case $ACTION in
    create)
        log_info "Creating stack $STACK_NAME..."
        aws cloudformation create-stack \
            --stack-name "$STACK_NAME" \
            --template-body "file://$TEMPLATE_FILE" \
            --parameters "file://$PARAMS_FILE" \
            --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
            --region "$REGION"

        log_info "Waiting for stack creation to complete..."
        aws cloudformation wait stack-create-complete \
            --stack-name "$STACK_NAME" \
            --region "$REGION"

        log_info "Stack created successfully!"
        ;;

    update)
        log_info "Updating stack $STACK_NAME..."
        aws cloudformation update-stack \
            --stack-name "$STACK_NAME" \
            --template-body "file://$TEMPLATE_FILE" \
            --parameters "file://$PARAMS_FILE" \
            --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
            --region "$REGION"

        log_info "Waiting for stack update to complete..."
        aws cloudformation wait stack-update-complete \
            --stack-name "$STACK_NAME" \
            --region "$REGION"

        log_info "Stack updated successfully!"
        ;;

    delete)
        log_warn "This will DELETE the $ENVIRONMENT infrastructure!"
        read -p "Are you sure? (yes/no): " confirm

        if [[ "$confirm" != "yes" ]]; then
            log_info "Deletion cancelled."
            exit 0
        fi

        log_info "Deleting stack $STACK_NAME..."
        aws cloudformation delete-stack \
            --stack-name "$STACK_NAME" \
            --region "$REGION"

        log_info "Waiting for stack deletion to complete..."
        aws cloudformation wait stack-delete-complete \
            --stack-name "$STACK_NAME" \
            --region "$REGION"

        log_info "Stack deleted successfully!"
        ;;
esac

# Show outputs for create/update
if [[ "$ACTION" != "delete" ]]; then
    log_info "Stack Outputs:"
    aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --query 'Stacks[0].Outputs' \
        --output table \
        --region "$REGION"
fi
