#!/bin/bash
set -e
GIT_REPO_URL="https://github.com/vonnue/watchmynetwork.git"
INSTALL_DIR="/opt/watchmynetwork"
SERVICE_NAME="watchmynetwork"
POST_START_SCRIPT="/usr/local/bin/wmn"
TMP_DIR=$(mktemp -d)
git clone "$GIT_REPO_URL" "$TMP_DIR"

install -d "$INSTALL_DIR"

cp -r "$TMP_DIR"/* "$INSTALL_DIR"/

if [ -f "$INSTALL_DIR/wmn" ]; then
    install "$INSTALL_DIR/wmn" "$POST_START_SCRIPT"
    chmod +x "$POST_START_SCRIPT"
fi
APP_DIR="$HOME/watchmynetwork"

cat >/etc/systemd/system/$SERVICE_NAME.service <<EOF
[Unit]
Description=Watch My Network
Requires=docker.service
After=docker.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
RemainAfterExit=yes
TimeoutStartSec=0

# Run custom binary/script after containers start
ExecStartPost=$POST_START_SCRIPT

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable $SERVICE_NAME.service

echo "Installation complete. Start service with:"
echo "  systemctl start $SERVICE_NAME.service"
