#!/bin/bash
set -e

REGION="us-east-1"
PREFIX="quakewatch-k3s"

echo "🧹 Cleaning AWS resources in $REGION for prefix $PREFIX..."

# Destroy Terraform resources first
echo "➡️  Running Terraform destroy..."
terraform destroy -auto-approve || true

# Then forcibly terminate any stray EC2 instances
echo "➡️  Terminating stray EC2 instances..."
aws ec2 describe-instances   --region $REGION   --query "Reservations[].Instances[?State.Name=='running' && contains(Tags[?Key=='Name'].Value | [0], '$PREFIX')].[InstanceId]"   --output text | while read id; do
  if [ -n "$id" ]; then
    echo "Terminating $id..."
    aws ec2 terminate-instances --instance-ids "$id" --region $REGION
  fi
done

# Remove the generated key pair
echo "➡️  Deleting SSH key pair..."
aws ec2 delete-key-pair --key-name "${PREFIX}-key" --region $REGION || true

echo "✅ Cleanup complete! All related AWS resources have been removed."
