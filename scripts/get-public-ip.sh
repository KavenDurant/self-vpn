#!/usr/bin/env bash
set -euo pipefail

# Try several public IP services in order, return the first succesful IPv4
# Usage: ./get-public-ip.sh [timeout_seconds]
TIMEOUT="${1:-3}"
SERVICES=(
  "https://ifconfig.me"
  "https://ipinfo.io/ip"
  "https://icanhazip.com"
  "https://api.ip.sb/ip"
)

for url in "${SERVICES[@]}"; do
  ip=$(curl -sS --max-time "$TIMEOUT" "$url" || true)
  # Trim
  ip="$(echo "$ip" | tr -d ' \r\n')"
  # Basic IPv4 validation
  if [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    printf "%s" "$ip"
    exit 0
  fi
done

# Nothing found
exit 1
