#!/usr/bin/env bash
set -euo pipefail

# Install a root LaunchDaemon that watches WireGuard up/down and switches DNS.
#
# It installs:
#   /usr/local/self-vpn/macos-dns-up.sh
#   /usr/local/self-vpn/macos-dns-down.sh
#   /usr/local/self-vpn/wg-dns-watcher.sh
#   /Library/LaunchDaemons/com.selfvpn.wg-dns-watcher.plist
#
# Usage:
#   sudo ./scripts/install-macos-wireguard-dns-watcher.sh \
#     Ethernet macbook 1.1.1.1 8.8.8.8 fallback 192.168.1.1 223.5.5.5

SERVICE_NAME="${1:-Ethernet}"
TUNNEL_NAME="${2:-macbook}"
DNS_UP_1="${3:-1.1.1.1}"
DNS_UP_2="${4:-8.8.8.8}"
RESTORE_MODE="${5:-fallback}"
FALLBACK_DNS1="${6:-192.168.1.1}"
FALLBACK_DNS2="${7:-223.5.5.5}"

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_DIR="/usr/local/self-vpn"
PLIST_PATH="/Library/LaunchDaemons/com.selfvpn.wg-dns-watcher.plist"
LOG_DIR="/var/log/self-vpn"

log() { printf "[install] %s\n" "$*"; }

require_root() {
	if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
		log "ERROR: must run as root (use sudo)"
		exit 1
	fi
}

main() {
	require_root

	log "Installing to $INSTALL_DIR"
	mkdir -p "$INSTALL_DIR" "$LOG_DIR"

	install -m 0755 "$REPO_DIR/scripts/macos-dns-up.sh" "$INSTALL_DIR/macos-dns-up.sh"
	install -m 0755 "$REPO_DIR/scripts/macos-dns-down.sh" "$INSTALL_DIR/macos-dns-down.sh"
	install -m 0755 "$REPO_DIR/scripts/macos-wireguard-dns-watcher.sh" "$INSTALL_DIR/wg-dns-watcher.sh"

	log "Writing LaunchDaemon plist: $PLIST_PATH"
	cat > "$PLIST_PATH" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>com.selfvpn.wg-dns-watcher</string>

	<key>ProgramArguments</key>
	<array>
		<string>$INSTALL_DIR/wg-dns-watcher.sh</string>
		<string>$SERVICE_NAME</string>
		<string>$TUNNEL_NAME</string>
		<string>$DNS_UP_1</string>
		<string>$DNS_UP_2</string>
		<string>$RESTORE_MODE</string>
		<string>$FALLBACK_DNS1</string>
		<string>$FALLBACK_DNS2</string>
	</array>

	<key>RunAtLoad</key>
	<true/>
	<key>KeepAlive</key>
	<true/>

	<key>StandardOutPath</key>
	<string>$LOG_DIR/wg-dns-watcher.out.log</string>
	<key>StandardErrorPath</key>
	<string>$LOG_DIR/wg-dns-watcher.err.log</string>
</dict>
</plist>
PLIST

	chmod 0644 "$PLIST_PATH"
	chown root:wheel "$PLIST_PATH"

	log "Reloading LaunchDaemon"
	launchctl bootout system "$PLIST_PATH" >/dev/null 2>&1 || true
	launchctl bootstrap system "$PLIST_PATH"
	launchctl enable system/com.selfvpn.wg-dns-watcher || true
	launchctl kickstart -k system/com.selfvpn.wg-dns-watcher || true

	log "Installed. Logs: $LOG_DIR"
}

main "$@"
