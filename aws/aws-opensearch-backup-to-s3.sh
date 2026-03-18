#!/bin/bash

set -euo pipefail

REGION="[ENTER_REGION]"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
S3_BUCKET="[ENTER_S3_BUCKET]"
S3_PREFIX="[ENTER_PREFIX]/opensearch-backups"
TMP_DIR=$(mktemp -d)
MANIFEST_FILE="$TMP_DIR/manifest.json"

DOMAINS=(
  "[ENTER_OPENSEARCH_DOMAIN_1]"
  "[ENTER_OPENSEARCH_DOMAIN_2]"
)

echo "==> Starting OpenSearch backup: $TIMESTAMP"
echo "    S3 Target: s3://$S3_BUCKET/$S3_PREFIX/"
echo ""

echo '{"backup_timestamp":"'"$TIMESTAMP"'","domains":[]}' > "$MANIFEST_FILE"

for DOMAIN in "${DOMAINS[@]}"; do
  echo "==> Backing up domain: $DOMAIN"

  # Domain config
  echo "    Fetching domain config..."
  DOMAIN_CONFIG=$(aws opensearch describe-domain \
    --region "$REGION" \
    --domain-name "$DOMAIN" \
    --output json)
  echo "$DOMAIN_CONFIG" | aws s3 cp - "s3://$S3_BUCKET/$S3_PREFIX/$DOMAIN/domain.json" --quiet
  echo "    s3://$S3_BUCKET/$S3_PREFIX/$DOMAIN/domain.json"

  # Domain config (restore-ready)
  echo "    Fetching domain config (restore-ready)..."
  aws opensearch describe-domain-config \
    --region "$REGION" \
    --domain-name "$DOMAIN" \
    --output json | aws s3 cp - "s3://$S3_BUCKET/$S3_PREFIX/$DOMAIN/domain-config.json" --quiet
  echo "    s3://$S3_BUCKET/$S3_PREFIX/$DOMAIN/domain-config.json"

  # Access policies
  echo "    Fetching access policy..."
  echo "$DOMAIN_CONFIG" | jq '.DomainStatus.AccessPolicies | fromjson' | \
    aws s3 cp - "s3://$S3_BUCKET/$S3_PREFIX/$DOMAIN/access-policy.json" --quiet
  echo "    s3://$S3_BUCKET/$S3_PREFIX/$DOMAIN/access-policy.json"

  # Snapshot repositories (manual snapshots)
  echo "    Fetching snapshot options..."
  aws opensearch describe-domain \
    --region "$REGION" \
    --domain-name "$DOMAIN" \
    --query 'DomainStatus.SnapshotOptions' \
    --output json | aws s3 cp - "s3://$S3_BUCKET/$S3_PREFIX/$DOMAIN/snapshot-options.json" --quiet
  echo "    s3://$S3_BUCKET/$S3_PREFIX/$DOMAIN/snapshot-options.json"

  # Tags
  echo "    Fetching tags..."
  DOMAIN_ARN=$(echo "$DOMAIN_CONFIG" | jq -r '.DomainStatus.ARN')
  aws opensearch list-tags \
    --arn "$DOMAIN_ARN" \
    --output json | aws s3 cp - "s3://$S3_BUCKET/$S3_PREFIX/$DOMAIN/tags.json" --quiet
  echo "    s3://$S3_BUCKET/$S3_PREFIX/$DOMAIN/tags.json"

  # Maintenance schedules / advanced options
  echo "    Fetching advanced options..."
  aws opensearch describe-domain \
    --region "$REGION" \
    --domain-name "$DOMAIN" \
    --query 'DomainStatus.AdvancedOptions' \
    --output json | aws s3 cp - "s3://$S3_BUCKET/$S3_PREFIX/$DOMAIN/advanced-options.json" --quiet
  echo "    s3://$S3_BUCKET/$S3_PREFIX/$DOMAIN/advanced-options.json"

  # Append to manifest
  jq ".domains += [{\"domain\":\"$DOMAIN\",\"arn\":\"$DOMAIN_ARN\",\"s3_prefix\":\"$S3_PREFIX/$DOMAIN\"}]" \
    "$MANIFEST_FILE" > "$TMP_DIR/tmp.json" && mv "$TMP_DIR/tmp.json" "$MANIFEST_FILE"

  echo ""
done

# Upload manifest
echo "==> Uploading manifest..."
aws s3 cp "$MANIFEST_FILE" "s3://$S3_BUCKET/$S3_PREFIX/manifest.json" --quiet
echo "    s3://$S3_BUCKET/$S3_PREFIX/manifest.json"

rm -rf "$TMP_DIR"
echo ""
echo "==> OpenSearch backup complete!"
echo "    All files under: s3://$S3_BUCKET/$S3_PREFIX/"
