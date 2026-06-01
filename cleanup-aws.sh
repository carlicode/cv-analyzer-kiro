#!/bin/bash
# ========================================
# AWS Resources Cleanup Script
# ========================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
STACK_NAME="cv-analyzer-stack"
REGION="${AWS_REGION:-us-east-1}"
BUCKET_PREFIX="cv-analyzer-frontend"

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

confirm() {
    read -p "$(echo -e ${YELLOW}⚠ $1 [y/N]: ${NC})" -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

delete_lambda_stack() {
    log_info "Checking for Lambda stack..."

    if aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION &>/dev/null; then
        log_warning "Found stack: $STACK_NAME"

        if confirm "Delete Lambda stack and API Gateway?"; then
            log_info "Deleting stack..."
            sam delete --stack-name $STACK_NAME --region $REGION --no-prompts
            log_success "Lambda stack deleted"
        else
            log_info "Skipping Lambda stack deletion"
        fi
    else
        log_info "No Lambda stack found"
    fi
}

delete_s3_buckets() {
    log_info "Searching for frontend buckets..."

    # Find all buckets with the prefix
    BUCKETS=$(aws s3 ls | grep "$BUCKET_PREFIX" | awk '{print $3}' || echo "")

    if [ -z "$BUCKETS" ]; then
        log_info "No frontend buckets found"
        return
    fi

    echo ""
    log_warning "Found buckets:"
    echo "$BUCKETS" | while read bucket; do
        echo "  - $bucket"
    done
    echo ""

    if confirm "Delete all these buckets?"; then
        echo "$BUCKETS" | while read bucket; do
            log_info "Deleting bucket: $bucket"

            # Empty bucket first
            aws s3 rm s3://$bucket --recursive --region $REGION

            # Delete bucket
            aws s3 rb s3://$bucket --region $REGION

            log_success "Deleted: $bucket"
        done
    else
        log_info "Skipping bucket deletion"
    fi
}

delete_cloudfront() {
    log_info "Checking for CloudFront distributions..."

    # Find distributions with CV Analyzer origin
    DISTRIBUTIONS=$(aws cloudfront list-distributions \
        --query "DistributionList.Items[?contains(Origins.Items[0].DomainName, '$BUCKET_PREFIX')].{Id:Id,Status:Status,DomainName:DomainName}" \
        --output json 2>/dev/null || echo "[]")

    if [ "$DISTRIBUTIONS" = "[]" ]; then
        log_info "No CloudFront distributions found"
        return
    fi

    echo ""
    log_warning "Found CloudFront distributions:"
    echo "$DISTRIBUTIONS" | jq -r '.[] | "  - \(.Id) (\(.Status)) - \(.DomainName)"'
    echo ""

    if confirm "Disable and delete CloudFront distributions?"; then
        echo "$DISTRIBUTIONS" | jq -r '.[].Id' | while read dist_id; do
            log_info "Processing distribution: $dist_id"

            # Get current config
            ETAG=$(aws cloudfront get-distribution-config --id $dist_id --query 'ETag' --output text)
            CONFIG=$(aws cloudfront get-distribution-config --id $dist_id --query 'DistributionConfig')

            # Disable distribution
            log_info "Disabling distribution..."
            echo "$CONFIG" | jq '.Enabled = false' > /tmp/dist-config.json

            aws cloudfront update-distribution \
                --id $dist_id \
                --distribution-config file:///tmp/dist-config.json \
                --if-match $ETAG

            log_warning "Distribution disabled. It may take 15-30 minutes to propagate."
            log_info "Run this script again later to delete the disabled distribution."

            rm /tmp/dist-config.json
        done
    else
        log_info "Skipping CloudFront deletion"
    fi
}

show_cost_summary() {
    log_info "Checking recent costs..."

    # This requires AWS Cost Explorer API enabled
    if aws ce get-cost-and-usage --help &>/dev/null; then
        START_DATE=$(date -v-7d +%Y-%m-%d 2>/dev/null || date -d '7 days ago' +%Y-%m-%d)
        END_DATE=$(date +%Y-%m-%d)

        COST=$(aws ce get-cost-and-usage \
            --time-period Start=$START_DATE,End=$END_DATE \
            --granularity DAILY \
            --metrics "UnblendedCost" \
            --filter file://<(cat <<EOF
{
  "Tags": {
    "Key": "aws:cloudformation:stack-name",
    "Values": ["$STACK_NAME"]
  }
}
EOF
) \
            --query 'ResultsByTime[*].Total.UnblendedCost.Amount' \
            --output text 2>/dev/null || echo "0")

        if [ "$COST" != "0" ]; then
            echo ""
            log_info "Estimated costs (last 7 days): \$$(echo $COST | awk '{sum+=$1} END {print sum}')"
        fi
    fi
}

main() {
    echo ""
    echo "=========================================="
    echo "  AWS Resources Cleanup Script"
    echo "=========================================="
    echo ""

    log_warning "This script will DELETE AWS resources!"
    echo ""

    if ! confirm "Continue with cleanup?"; then
        log_info "Cleanup cancelled"
        exit 0
    fi

    echo ""

    # Show cost summary
    show_cost_summary

    # Delete resources
    echo ""
    delete_lambda_stack

    echo ""
    delete_s3_buckets

    echo ""
    delete_cloudfront

    echo ""
    echo "=========================================="
    log_success "Cleanup Complete!"
    echo "=========================================="
    echo ""
    log_info "Remaining manual steps (if any):"
    echo "  1. Check AWS Console for any remaining resources"
    echo "  2. Wait for CloudFront distributions to fully delete (if applicable)"
    echo "  3. Check CloudWatch Logs for any log groups to delete"
    echo ""
}

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    log_error "AWS CLI not found"
    exit 1
fi

# Check credentials
if ! aws sts get-caller-identity &> /dev/null; then
    log_error "AWS credentials not configured"
    exit 1
fi

main

exit 0
