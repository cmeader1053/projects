#!/bin/bash

CLUSTER="[ENTER_CLUSTER_NAME_HERE]"
S3_BUCKET="s3://[ENTER_S3_BUCKET_HERE]"
BACKUP_DIR="./ecs-backup-$(date +%Y%m%d_%H%M%S)"

mkdir -p "$BACKUP_DIR/task-definitions"

# Cluster details
echo "Exporting cluster..."
aws ecs describe-clusters \
  --clusters "$CLUSTER" \
  --include ATTACHMENTS CONFIGURATIONS SETTINGS STATISTICS TAGS \
  > "$BACKUP_DIR/cluster.json"

# All task definitions
echo "Exporting task definitions..."
TASK_DEF_ARNS=$(aws ecs list-task-definitions --query 'taskDefinitionArns' --output text)
for ARN in $TASK_DEF_ARNS; do
  SAFE_NAME=$(echo "$ARN" | sed 's|.*/||' | tr ':' '_')
  aws ecs describe-task-definition \
    --task-definition "$ARN" \
    --include TAGS \
    > "$BACKUP_DIR/task-definitions/${SAFE_NAME}.json"
done

# Service
echo "Exporting service..."
SERVICE_ARNS=$(aws ecs list-services --cluster "$CLUSTER" --query 'serviceArns[]' --output text)
aws ecs describe-services \
  --cluster "$CLUSTER" \
  --services $SERVICE_ARNS \
  --include TAGS \
  > "$BACKUP_DIR/services.json"

# Running task
echo "Exporting running task..."
TASK_ARNS=$(aws ecs list-tasks --cluster "$CLUSTER" --desired-status RUNNING --query 'taskArns[]' --output text)
aws ecs describe-tasks \
  --cluster "$CLUSTER" \
  --tasks $TASK_ARNS \
  --include TAGS \
  > "$BACKUP_DIR/tasks.json"

# Upload to S3
echo "Uploading to S3..."
aws s3 cp "$BACKUP_DIR" "$S3_BUCKET/ecs-backups/$(basename $BACKUP_DIR)/" --recursive

echo ""
echo "Backup complete and uploaded to $S3_BUCKET/ecs-backups/$(basename $BACKUP_DIR)/"
