#!/bin/bash

set -euo pipefail

DISTRIBUTION_ID="[ENTER_CLOUDFRONT_DISTRIBUTION]"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
S3_BUCKET="[ENTER_S3_BUCKET]"
S3_PREFIX="[ENTER_PREFIX]/cloudfront-backups"
TMP_DIR=$(mktemp -d)

echo "Starting CloudFront backup: $TIMESTAMP"
echo "    Distribution: $DISTRIBUTION_ID"
echo "    S3 Target   : s3://$S3_BUCKET/$S3_PREFIX/"
echo ""

# 1. Full distribution config
echo "Fetching distribution config..."
aws cloudfront get-distribution \
  --id "$DISTRIBUTION_ID" \
  --output json | aws s3 cp - "s3://$S3_BUCKET/$S3_PREFIX/distribution.json" --quiet
echo "    s3://$S3_BUCKET/$S3_PREFIX/distribution.json"

# 2. Distribution config only (restore-ready)
echo "Fetching distribution config (restore-ready)..."
aws cloudfront get-distribution-config \
  --id "$DISTRIBUTION_ID" \
  --output json | aws s3 cp - "s3://$S3_BUCKET/$S3_PREFIX/distribution-config.json" --quiet
echo "    s3://$S3_BUCKET/$S3_PREFIX/distribution-config.json"

# 3. Cache policies
echo "Fetching cache policies..."
aws cloudfront list-cache-policies \
  --type custom \
  --output json | aws s3 cp - "s3://$S3_BUCKET/$S3_PREFIX/cache-policies.json" --quiet
echo "    s3://$S3_BUCKET/$S3_PREFIX/cache-policies.json"

# 4. Invalidation history (last 100)
echo "Fetching invalidation history..."
aws cloudfront list-invalidations \
  --distribution-id "$DISTRIBUTION_ID" \
  --max-items 100 \
  --output json | aws s3 cp - "s3://$S3_BUCKET/$S3_PREFIX/invalidations.json" --quiet
echo "    s3://$S3_BUCKET/$S3_PREFIX/invalidations.json"

# 5. Tags
echo "Fetching tags..."
DIST_ARN=$(aws cloudfront get-distribution \
  --id "$DISTRIBUTION_ID" \
  --query 'Distribution.ARN' \
  --output text)
aws cloudfront list-tags-for-resource \
  --resource "$DIST_ARN" \
  --output json | aws s3 cp - "s3://$S3_BUCKET/$S3_PREFIX/tags.json" --quiet
echo "    s3://$S3_BUCKET/$S3_PREFIX/tags.json"

# 6. Manifest
echo "Writing manifest..."
jq -n \
  --arg ts "$TIMESTAMP" \
  --arg dist_id "$DISTRIBUTION_ID" \
  --arg dist_arn "$DIST_ARN" \
  --arg prefix "$S3_PREFIX" \
  '{
    backup_timestamp: $ts,
    distribution_id: $dist_id,
    distribution_arn: $dist_arn,
    files: {
      full_distribution: "\($prefix)/distribution.json",
      restore_config: "\($prefix)/distribution-config.json",
      cache_policies: "\($prefix)/cache-policies.json",
      invalidations: "\($prefix)/invalidations.json",
      tags: "\($prefix)/tags.json"
    }
  }' | aws s3 cp - "s3://$S3_BUCKET/$S3_PREFIX/manifest.json" --quiet
echo "    s3://$S3_BUCKET/$S3_PREFIX/manifest.json"

rm -rf "$TMP_DIR"
echo ""
echo "CloudFront backup complete!"
echo "    All files under: s3://$S3_BUCKET/$S3_PREFIX/"
