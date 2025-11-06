#!/bin/bash
set -e

echo "🧹 Cleaning up AWS resources for QuakeWatch..."

cd "$(dirname "$0")"

echo "Destroying Terraform resources..."
terraform destroy -auto-approve || true

echo "Deleting orphaned EBS volumes..."
aws ec2 describe-volumes --region us-east-1 --query "Volumes[?State=='available'].VolumeId" --output text | while read vol; do
  echo "Deleting volume: $vol"
  aws ec2 delete-volume --volume-id "$vol" --region us-east-1
done

echo "Deleting snapshots..."
aws ec2 describe-snapshots --owner-ids self --query "Snapshots[].SnapshotId" --output text | while read snap; do
  echo "Deleting snapshot: $snap"
  aws ec2 delete-snapshot --snapshot-id "$snap" --region us-east-1
done

echo "✅ Cleanup complete. All AWS resources have been removed."
