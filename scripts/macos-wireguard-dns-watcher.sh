#!/usr/bin/env bash
set -euo pipefail

# macOS launchd-friendly watcher:
# - Detects whether WireGuard full-tunnel VPN is up by comparing current public IP
#   with SERVER_IP from this repo's .env.
# - On transitions, it runs DNS up/down scripts to avoid the DNS-not-restored issue.
#
# Usage (manual foreground):
#   sudo ./scripts/macos-wireguard-dns-watcher.sh Ethernet macbook

SERVICE_NAME="${1:-Ethernet}"
TUNNEL_NAME="${2:-macbook}"
DNS_UP_1="${3:-1.1.1.1}"
DNS_UP_2="${4:-8.8.8.8}"
RESTORE_MODE="${5:-fallback}" # Empty|auto|fallback|<dns1,dns2>
FALLBACK_DNS1="${6:-192.168.1.1}"
FALLBACK_DNS2="${7:-223.5.5.5}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DNS_UP_SCRIPT="$SCRIPT_DIR/macos-dns-up.sh"
DNS_DOWN_SCRIPT="$SCRIPT_DIR/macos-dns-down.sh"

REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$REPO_DIR/.env"
ENV_EXAMPLE_FILE="$REPO_DIR/.env.example"
VPN_SERVER_IP=""
if [[ -f "$ENV_FILE" ]]; then
	VPN_SERVER_IP="$(grep -E '^SERVER_IP=' "$ENV_FILE" | head -n 1 | cut -d '=' -f2- | tr -d ' \t\r\n')"
elif [[ -f "$ENV_EXAMPLE_FILE" ]]; then
	VPN_SERVER_IP="$(grep -E '^SERVER_IP=' "$ENV_EXAMPLE_FILE" | head -n 1 | cut -d '=' -f2- | tr -d ' \t\r\n')"
fi

# Handle placeholders like YOUR_SERVER_IP_HERE
if [[ "${VPN_SERVER_IP:-}" == *"YOUR_SERVER_IP"* || "${VPN_SERVER_IP:-}" == "" ]]; then
	VPN_SERVER_IP=""
fi

# helper to get public ip robustly (tries multiple services)
GET_IP_SCRIPT="$REPO_DIR/scripts/get-public-ip.sh"
if [[ ! -x "$GET_IP_SCRIPT" ]]; then
	GET_IP_SCRIPT=""
fi

log() { printf "[wg-dns-watcher] %s\n" "$*"; }

require_root() {
	if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
		log "ERROR: must run as root (use sudo)"
		exit 1
	fi
}

vpn_is_up() {
	# Preferred: compare current public IP with VPN server public IP using multiple endpoints.
	if [[ -n "${VPN_SERVER_IP:-}" ]]; then
		local current_ip
		if [[ -n "$GET_IP_SCRIPT" ]]; then
			current_ip="$($GET_IP_SCRIPT 3 2>/dev/null || true)"
		else
			current_ip="$(curl -s --max-time 3 ifconfig.me || true)"
		fi
		[[ "$current_ip" == "$VPN_SERVER_IP" ]] && return 0 || return 1
	fi

	# Fallback: if `wg` is available, check for any WireGuard interface.
	if command -v wg >/dev/null 2>&1; then
		wg show 2>/dev/null | grep -q "interface:" && return 0 || true
	fi

	# Last resort: assume down (avoid flapping/false positives).
	return 1
}

run_up() {
	log "VPN detected UP -> set DNS"
	"$DNS_UP_SCRIPT" "$SERVICE_NAME" "$DNS_UP_1" "$DNS_UP_2" || true
}

run_down() {
	log "VPN detected DOWN -> restore DNS"
	"$DNS_DOWN_SCRIPT" "$SERVICE_NAME" "$RESTORE_MODE" "$FALLBACK_DNS1" "$FALLBACK_DNS2" || true
}

main() {
	require_root

	if [[ ! -x "$DNS_UP_SCRIPT" || ! -x "$DNS_DOWN_SCRIPT" ]]; then
		log "ERROR: required scripts not executable:"
		log " - $DNS_UP_SCRIPT"
		log " - $DNS_DOWN_SCRIPT"
		exit 1
	fi

	log "Watching tunnel='$TUNNEL_NAME' service='$SERVICE_NAME' restore='$RESTORE_MODE'"
	local last_state="unknown"

	while true; do
		if vpn_is_up; then
			if [[ "$last_state" != "up" ]]; then
				run_up
				last_state="up"
			fi
		else
			if [[ "$last_state" != "down" ]]; then
				run_down
				last_state="down"
			fi
		fi
		sleep 3
	done
}

main "$@"
