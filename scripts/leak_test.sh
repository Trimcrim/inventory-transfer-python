#!/usr/bin/env bash
# Sends transfers that cannot succeed (too little stock, unknown location,
# zero quantity) and then prints the state of the connection pool.
# Usage: ./scripts/leak_test.sh [count]

BASE_URL="${BASE_URL:-http://localhost:8080}"
COUNT="${1:-10}"

echo "Pool before:"
curl -s -m 5 "$BASE_URL/api/health" | jq -c '.pool'
echo

body_for() {
  case $(($1 % 3)) in
    0) echo '{"sku":"SKU-003","fromLocation":"WAREHOUSE-C","toLocation":"WAREHOUSE-A","quantity":100000}' ;;
    1) echo '{"sku":"SKU-003","fromLocation":"WAREHOUSE-X","toLocation":"WAREHOUSE-A","quantity":10}' ;;
    2) echo '{"sku":"SKU-003","fromLocation":"WAREHOUSE-C","toLocation":"WAREHOUSE-A","quantity":0}' ;;
  esac
}

tmp=$(mktemp -d)
echo "Sending $COUNT failing transfers..."
for i in $(seq 1 "$COUNT"); do
  (
    curl -s -o /dev/null -m 30 -w "%{http_code} %{time_total}s" \
      -X POST "$BASE_URL/api/transfer" \
      -H "Content-Type: application/json" \
      -d "$(body_for "$i")" > "$tmp/$i"
  ) &
  sleep 0.2
done

echo
echo "Pool while the requests are running:"
curl -s -m 5 "$BASE_URL/api/health" | jq -c '.pool'

wait
echo
echo "Responses (status, time):"
for i in $(seq 1 "$COUNT"); do
  echo "  #$i  $(cat "$tmp/$i")"
done
rm -rf "$tmp"

echo
echo "Pool after:"
curl -s -m 5 "$BASE_URL/api/health" | jq -c '.pool'
