#!/usr/bin/env bash
# Run this ONCE to create the S3 bucket for remote state.
# After running, uncomment the backend block in terraform/provider.tf
# and run: terraform init -migrate-state
set -euo pipefail

AWS_REGION="${1:-us-east-1}"
BUCKET_NAME="${2:-enterprise-vpn-tfstate-$(aws sts get-caller-identity --query Account --output text)}"

echo ""
echo "====================================================="
echo "       Terraform Remote Backend Setup (S3 only)"
echo "====================================================="
echo "Region      : $AWS_REGION"
echo "S3 Bucket   : $BUCKET_NAME"
echo "====================================================="
echo ""

echo "[+] Creating S3 bucket for remote state..."
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "[!] Bucket already exists, skipping creation."
else
    aws s3api create-bucket \
        --bucket "$BUCKET_NAME" \
        --region "$AWS_REGION" \
        $([ "$AWS_REGION" != "us-east-1" ] && echo "--create-bucket-configuration LocationConstraint=$AWS_REGION")

    echo "[+] Enabling versioning..."
    aws s3api put-bucket-versioning \
        --bucket "$BUCKET_NAME" \
        --versioning-configuration Status=Enabled

    echo "[+] Enabling encryption..."
    aws s3api put-bucket-encryption \
        --bucket "$BUCKET_NAME" \
        --server-side-encryption-configuration '{
            "Rules": [{
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }]
        }'

    echo "[+] Blocking public access..."
    aws s3api put-public-access-block \
        --bucket "$BUCKET_NAME" \
        --public-access-block-configuration \
            "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
fi

echo ""
echo "====================================================="
echo "              Backend Setup Complete"
echo "====================================================="
echo ""
echo "Next steps:"
echo ""
echo "  1. Update terraform/provider.tf — set bucket = \"$BUCKET_NAME\""
echo "  2. Uncomment the backend \"s3\" block"
echo "  3. Run: cd terraform && terraform init -migrate-state"
echo ""
echo "Note: state locking isn't enabled (no DynamoDB)."
echo "Fine for solo use — just don't run 'terraform apply'"
echo "from two terminals at the same time."
echo ""