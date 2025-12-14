#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="wmn-agent"
BIN_SRC="./wmn"
BIN_DST="/usr/local/bin/wmn"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root"
  exit 1
fi

if [[ ! -f "$BIN_SRC" ]]; then
  echo "Binary '$BIN_SRC' not found in current directory"
  exit 1
fi

echo "Installing binary..."
install -m 0755 "$BIN_SRC" "$BIN_DST"

echo "Creating systemd service..."

cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Watch My Network Agent
After=network-online.target docker.service
Wants=network-online.target
Requires=docker.service

[Service]
Type=simple
ExecStart=$BIN_DST
Restart=always
RestartSec=5
# Optional but recommended
Environment=RUST_LOG=info
# Uncomment if you want to limit privileges
# NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

echo "Reloading systemd..."
systemctl daemon-reload

echo "Enabling service..."
systemctl enable "$SERVICE_NAME"

echo "Starting service..."
systemctl restart "$SERVICE_NAME"

echo
echo "Installation complete"
echo "Service status:"
systemctl status "$SERVICE_NAME" --no-pager
