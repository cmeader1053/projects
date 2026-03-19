#!/bin/bash
# DynamoDB Backup to S3

set -euo pipefail

REGION="[ENTER_REGION]"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
S3_BUCKET="[ENTER_S3_BUCKET]"
S3_PREFIX="[ENTER_PREFIX]/dynamodb-backup"
TMP_DIR=$(mktemp -d)
MANIFEST_FILE="$TMP_DIR/manifest.json"

TABLES=(
[ENTER_DB_TABLE_1]
[ENTER_DB_TABLE_2]
[ENTER_DB_TABLE_3]
)

echo "Starting DynamoDB backup: $TIMESTAMP"
echo "    S3 Target: s3://$S3_BUCKET/$S3_PREFIX/"
echo ""

echo '{"backup_timestamp":"'"$TIMESTAMP"'","tables":[]}' > "$MANIFEST_FILE"

for TABLE in "${TABLES[@]}"; do
  echo "Backing up table: $TABLE"

  # Table metadata/description
  TABLE_DESC=$(aws dynamodb describe-table \
    --region "$REGION" \
    --table-name "$TABLE" \
    --query 'Table' \
    --output json)

  # Export full table data via scan (paginated)
  ITEMS_FILE="$TMP_DIR/${TABLE}.json"
  echo '{"table":"'"$TABLE"'","items":[]}' > "$ITEMS_FILE"

  LAST_KEY=""
  PAGE=0
  TOTAL_ITEMS=0

  while true; do
    PAGE=$((PAGE + 1))

    if [[ -z "$LAST_KEY" ]]; then
      RESPONSE=$(aws dynamodb scan \
        --region "$REGION" \
        --table-name "$TABLE" \
        --output json)
    else
      RESPONSE=$(aws dynamodb scan \
        --region "$REGION" \
        --table-name "$TABLE" \
        --exclusive-start-key "$LAST_KEY" \
        --output json)
    fi

    # Append items to file
    PAGE_ITEMS=$(echo "$RESPONSE" | jq '.Items')
    PAGE_COUNT=$(echo "$PAGE_ITEMS" | jq 'length')
    TOTAL_ITEMS=$((TOTAL_ITEMS + PAGE_COUNT))

    jq ".items += $PAGE_ITEMS" "$ITEMS_FILE" > "$TMP_DIR/tmp.json" && \
      mv "$TMP_DIR/tmp.json" "$ITEMS_FILE"

    echo "    Page $PAGE: $PAGE_COUNT items"

    # Check for more pages
    LAST_KEY=$(echo "$RESPONSE" | jq -c '.LastEvaluatedKey // empty')
    [[ -z "$LAST_KEY" ]] && break
  done

  echo "    Total items: $TOTAL_ITEMS"

  # Upload table data JSON
  DATA_KEY="$S3_PREFIX/${TABLE}/data.json"
  aws s3 cp "$ITEMS_FILE" "s3://$S3_BUCKET/$DATA_KEY" --quiet
  echo "    Data    : s3://$S3_BUCKET/$DATA_KEY"

  # Upload table description JSON
  DESC_KEY="$S3_PREFIX/${TABLE}/description.json"
  echo "$TABLE_DESC" | aws s3 cp - "s3://$S3_BUCKET/$DESC_KEY" --quiet
  echo "    Schema  : s3://$S3_BUCKET/$DESC_KEY"

  # Append to manifest
  jq ".tables += [{\"table\":\"$TABLE\",\"item_count\":$TOTAL_ITEMS,\"data_key\":\"$DATA_KEY\",\"description_key\":\"$DESC_KEY\"}]" \
    "$MANIFEST_FILE" > "$TMP_DIR/tmp.json" && mv "$TMP_DIR/tmp.json" "$MANIFEST_FILE"

  rm -f "$ITEMS_FILE"
  echo ""
done

# Upload manifest
echo "Uploading manifest..."
aws s3 cp "$MANIFEST_FILE" "s3://$S3_BUCKET/$S3_PREFIX/manifest.json"
echo "    s3://$S3_BUCKET/$S3_PREFIX/manifest.json"

rm -rf "$TMP_DIR"
echo ""
echo "DynamoDB backup complete!"
echo "    All files under: s3://$S3_BUCKET/$S3_PREFIX/"
