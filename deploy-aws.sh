#!/bin/bash
# ========================================
# AWS Lambda + S3 Automated Deployment
# ========================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
STACK_NAME="cv-analyzer-stack"
REGION="${AWS_REGION:-us-east-1}"
BUCKET_PREFIX="cv-analyzer-frontend"

# Functions
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

check_dependencies() {
    log_info "Checking dependencies..."

    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI not found. Install it from: https://aws.amazon.com/cli/"
        exit 1
    fi

    if ! command -v sam &> /dev/null; then
        log_error "SAM CLI not found. Install it from: https://aws.amazon.com/serverless/sam/"
        exit 1
    fi

    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured. Run: aws configure"
        exit 1
    fi

    log_success "All dependencies installed"
}

deploy_backend() {
    log_info "Building Lambda function..."

    # Build with SAM
    sam build
    log_success "Build complete"

    log_info "Deploying to AWS Lambda..."

    # Deploy (use --no-confirm-changeset for non-interactive)
    if [ -f samconfig.toml ]; then
        sam deploy --no-confirm-changeset
    else
        log_warning "No samconfig.toml found, running guided deploy..."
        sam deploy --guided
    fi

    log_success "Lambda deployed successfully"
}

get_api_url() {
    log_info "Retrieving API Gateway URL..."

    API_URL=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`CVAnalyzerApi`].OutputValue' \
        --output text 2>/dev/null || echo "")

    if [ -z "$API_URL" ]; then
        log_error "Could not retrieve API URL. Check CloudFormation stack."
        exit 1
    fi

    # Remove trailing slash if present
    API_URL="${API_URL%/}"

    log_success "API URL: $API_URL"
    echo "$API_URL"
}

update_frontend_config() {
    local api_url=$1
    log_info "Updating frontend configuration..."

    # Create a backup
    cp frontend/app.js frontend/app.js.backup

    # Replace the DEPLOY_API_URL token with the real API Gateway URL
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|DEPLOY_API_URL|${api_url}|g" frontend/app.js
    else
        sed -i "s|DEPLOY_API_URL|${api_url}|g" frontend/app.js
    fi

    # Verify replacement succeeded
    if grep -q "${api_url}" frontend/app.js; then
        log_success "Frontend config updated → ${api_url}/analyze"
    else
        log_error "sed replacement failed — check app.js for the DEPLOY_API_URL token"
        restore_frontend_config
        exit 1
    fi
}

create_s3_bucket() {
    log_info "Setting up S3 bucket for frontend..."

    # Reuse existing bucket name from previous deploy if saved
    BUCKET_CACHE_FILE=".frontend-bucket-name"
    if [ -f "$BUCKET_CACHE_FILE" ]; then
        SAVED_BUCKET=$(cat "$BUCKET_CACHE_FILE")
        if aws s3 ls "s3://$SAVED_BUCKET" 2>/dev/null; then
            log_warning "Reusing existing bucket: $SAVED_BUCKET"
            echo "$SAVED_BUCKET"
            return
        fi
    fi

    # Generate unique bucket name for new deploy
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    BUCKET_NAME="${BUCKET_PREFIX}-${ACCOUNT_ID}"

    if aws s3 ls "s3://$BUCKET_NAME" 2>/dev/null; then
        log_warning "Bucket already exists: $BUCKET_NAME"
    else
        log_info "Creating bucket: $BUCKET_NAME"

        if [ "$REGION" = "us-east-1" ]; then
            aws s3 mb s3://$BUCKET_NAME
        else
            aws s3 mb s3://$BUCKET_NAME --region $REGION
        fi

        aws s3 website s3://$BUCKET_NAME \
            --index-document index.html \
            --error-document index.html

        log_success "Bucket created: $BUCKET_NAME"
    fi

    # Save bucket name for future redeploys
    echo "$BUCKET_NAME" > "$BUCKET_CACHE_FILE"
    echo "$BUCKET_NAME"
}

configure_bucket_public() {
    local bucket_name=$1
    log_info "Configuring public access..."

    # Disable block public access
    aws s3api put-public-access-block \
        --bucket $bucket_name \
        --public-access-block-configuration \
            "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

    # Create bucket policy
    cat > /tmp/bucket-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${bucket_name}/*"
    }
  ]
}
EOF

    # Apply policy
    aws s3api put-bucket-policy \
        --bucket $bucket_name \
        --policy file:///tmp/bucket-policy.json

    rm /tmp/bucket-policy.json

    log_success "Public access configured"
}

deploy_frontend() {
    local bucket_name=$1
    log_info "Uploading frontend files to S3..."

    # Sync files
    aws s3 sync frontend/ s3://$bucket_name/ \
        --exclude "*.md" \
        --exclude "*.sh" \
        --exclude "*.backup" \
        --exclude "DEPLOYMENT.md" \
        --exclude "README.md" \
        --delete

    # Set correct content types
    aws s3 cp s3://$bucket_name/index.html s3://$bucket_name/index.html \
        --content-type "text/html" \
        --metadata-directive REPLACE \
        --cache-control "max-age=300"

    aws s3 cp s3://$bucket_name/app.js s3://$bucket_name/app.js \
        --content-type "application/javascript" \
        --metadata-directive REPLACE \
        --cache-control "max-age=300"

    aws s3 cp s3://$bucket_name/styles.css s3://$bucket_name/styles.css \
        --content-type "text/css" \
        --metadata-directive REPLACE \
        --cache-control "max-age=300"

    log_success "Frontend deployed to S3"
}

get_website_url() {
    local bucket_name=$1

    if [ "$REGION" = "us-east-1" ]; then
        echo "http://${bucket_name}.s3-website-${REGION}.amazonaws.com"
    else
        echo "http://${bucket_name}.s3-website.${REGION}.amazonaws.com"
    fi
}

test_deployment() {
    local api_url=$1
    local website_url=$2

    log_info "Testing deployment..."

    # Test API
    log_info "Testing API endpoint..."
    if curl -f -s -o /dev/null "$api_url"; then
        log_success "API is responding"
    else
        log_warning "API test failed, but deployment may still work"
    fi

    # Test frontend
    log_info "Testing frontend..."
    if curl -f -s -o /dev/null "$website_url"; then
        log_success "Frontend is accessible"
    else
        log_warning "Frontend test failed, check S3 configuration"
    fi
}

restore_frontend_config() {
    if [ -f frontend/app.js.backup ]; then
        log_info "Restoring original frontend config..."
        mv frontend/app.js.backup frontend/app.js
        log_success "Config restored"
    fi
}

# Main execution
main() {
    echo ""
    echo "=========================================="
    echo "  AWS Lambda + S3 Deployment Script"
    echo "=========================================="
    echo ""

    # Check dependencies
    check_dependencies

    # Deploy backend
    echo ""
    log_info "📦 Step 1: Deploying Backend (Lambda + API Gateway)"
    deploy_backend

    # Get API URL
    echo ""
    log_info "🔍 Step 2: Retrieving API Configuration"
    API_URL=$(get_api_url)

    # Update frontend config
    echo ""
    log_info "⚙️  Step 3: Configuring Frontend"
    update_frontend_config "$API_URL"

    # Create S3 bucket
    echo ""
    log_info "🪣 Step 4: Setting up S3 Bucket"
    BUCKET_NAME=$(create_s3_bucket)
    configure_bucket_public "$BUCKET_NAME"

    # Deploy frontend
    echo ""
    log_info "🌐 Step 5: Deploying Frontend"
    deploy_frontend "$BUCKET_NAME"

    # Get website URL
    WEBSITE_URL=$(get_website_url "$BUCKET_NAME")

    # Test deployment
    echo ""
    log_info "🧪 Step 6: Testing Deployment"
    test_deployment "$API_URL" "$WEBSITE_URL"

    # Restore original config
    restore_frontend_config

    # Summary
    echo ""
    echo "=========================================="
    echo -e "${GREEN}✅ Deployment Complete!${NC}"
    echo "=========================================="
    echo ""
    echo "📊 Deployment Summary:"
    echo "  Stack Name:    $STACK_NAME"
    echo "  Region:        $REGION"
    echo "  Bucket:        $BUCKET_NAME"
    echo ""
    echo "🔗 URLs:"
    echo "  Frontend:      $WEBSITE_URL"
    echo "  API:           $API_URL"
    echo ""
    echo "📝 Next Steps:"
    echo "  1. Open frontend: $WEBSITE_URL"
    echo "  2. Upload a CV to test the integration"
    echo "  3. (Optional) Configure CloudFront for HTTPS"
    echo ""
    echo "💡 To update the deployment:"
    echo "   ./deploy-aws.sh"
    echo ""
    echo "🗑️  To clean up resources:"
    echo "   sam delete --stack-name $STACK_NAME"
    echo "   aws s3 rb s3://$BUCKET_NAME --force"
    echo ""
}

# Trap errors
trap 'log_error "Deployment failed!"; restore_frontend_config; exit 1' ERR

# Run main
main

exit 0
