#!/usr/bin/env bash
# Prints the state of the connection pool once per second. Stop with Ctrl+C.
# Usage: ./scripts/pool_monitor.sh

BASE_URL="${BASE_URL:-http://localhost:8080}"

while true; do
  pool=$(curl -s -m 2 "$BASE_URL/api/health" | jq -c '.pool' 2>/dev/null)
  echo "$(date +%H:%M:%S)  ${pool:-no answer}"
  sleep 1
done
