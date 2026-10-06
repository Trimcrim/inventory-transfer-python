#!/usr/bin/env bash
# Sends many valid transfers of SKU-001 at the same time, alternating
# WAREHOUSE-A -> WAREHOUSE-B and WAREHOUSE-B -> WAREHOUSE-A.
# Usage: ./scripts/burst_test.sh [concurrency] [total]

BASE_URL="${BASE_URL:-http://localhost:8080}"
CONCURRENCY="${1:-20}"
TOTAL="${2:-100}"
SKU="${SKU:-SKU-001}"
QUANTITY="${QUANTITY:-10}"

echo "Sending $TOTAL transfers of $SKU ($QUANTITY units each), $CONCURRENCY at a time, to $BASE_URL"

send_transfer() {
  i="$1"
  if [ $((i % 2)) -eq 0 ]; then
    from="WAREHOUSE-A"; to="WAREHOUSE-B"
  else
    from="WAREHOUSE-B"; to="WAREHOUSE-A"
  fi
  curl -s -o /dev/null -m 30 -w "%{http_code}\n" \
    -X POST "$BASE_URL/api/transfer" \
    -H "Content-Type: application/json" \
    -d "{\"sku\":\"$SKU\",\"fromLocation\":\"$from\",\"toLocation\":\"$to\",\"quantity\":$QUANTITY}"
}
export -f send_transfer
export BASE_URL SKU QUANTITY

start=$(date +%s)
results=$(seq 1 "$TOTAL" | xargs -P "$CONCURRENCY" -I{} bash -c 'send_transfer {}')
end=$(date +%s)

echo "Finished in $((end - start))s. HTTP status codes:"
echo "$results" | sort | uniq -c | sed 's/^/  /'
echo
echo "Run ./scripts/consistency_check.sh to compare the totals."
