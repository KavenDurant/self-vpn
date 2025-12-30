#!/usr/bin/env bash
set -euo pipefail

# macOS: set DNS servers for a given network service (e.g. Ethernet, Wi-Fi)
# Intended to run when VPN comes UP.

SERVICE_NAME="${1:-Ethernet}"
# Default: use overseas DNS while connected to VPN.
DNS1="${2:-1.1.1.1}"
DNS2="${3:-8.8.8.8}"

log() { printf "[macos-dns-up] %s\n" "$*"; }

detect_service() {
	# Verify service exists
	if ! networksetup -listallnetworkservices 2>/dev/null | tail -n +2 | grep -Fxq "$SERVICE_NAME"; then
		log "ERROR: network service not found: $SERVICE_NAME"
		log "Available services:"
		networksetup -listallnetworkservices 2>/dev/null | tail -n +2 | sed 's/^/  - /' || true
		exit 1
	fi
}

require_root() {
	if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
		log "ERROR: must run as root (use sudo)"
		exit 1
	fi
}

main() {
	require_root
	detect_service

	log "Setting DNS for '$SERVICE_NAME' to: $DNS1 ${DNS2:+$DNS2}"
	if [[ -n "${DNS2:-}" ]]; then
		networksetup -setdnsservers "$SERVICE_NAME" "$DNS1" "$DNS2"
	else
		networksetup -setdnsservers "$SERVICE_NAME" "$DNS1"
	fi

	log "Current DNS for '$SERVICE_NAME':"
	networksetup -getdnsservers "$SERVICE_NAME" || true
}

main "$@"
