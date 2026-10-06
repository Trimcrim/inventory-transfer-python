#!/usr/bin/env bash
# Compares the total quantity of each SKU with the value from the seed data.
# Usage: ./scripts/consistency_check.sh
# Exit code is 0 when every SKU matches, 1 otherwise.

BASE_URL="${BASE_URL:-http://localhost:8080}"
EXPECTED="SKU-001:1800 SKU-002:3500 SKU-003:700"

failed=0
for entry in $EXPECTED; do
  sku="${entry%%:*}"
  expected="${entry##*:}"

  body=$(curl -s -m 10 "$BASE_URL/api/inventory/$sku")
  total=$(echo "$body" | jq -r '.total // empty' 2>/dev/null)
  if [ -z "$total" ]; then
    echo "FAIL  $sku  no answer from $BASE_URL/api/inventory/$sku"
    failed=1
    continue
  fi

  locations=$(echo "$body" | jq -r '[.locations[] | "\(.location)=\(.quantity)"] | join("  ")')
  if [ "$total" = "$expected" ]; then
    printf "OK    %s  total=%-6s expected=%-6s %s\n" "$sku" "$total" "$expected" "$locations"
  else
    printf "FAIL  %s  total=%-6s expected=%-6s %s\n" "$sku" "$total" "$expected" "$locations"
    failed=1
  fi
done

exit $failed
