#!/bin/bash

REPO_URL="https://raw.githubusercontent.com/vonnue/watchmynetwork/main/wifi-client-monitor/wmn-wifi-client-monitor.sh"
INSTALL_PATH="/usr/local/bin/wmn-wifi-client-monitor.sh"

echo "Installing WMN WiFi Client Monitor..."

echo "Downloading monitoring script..."
sudo curl -sSL "$REPO_URL" -o "$INSTALL_PATH"

if [ $? -ne 0 ]; then
    echo "Error: Failed to download monitoring script"
    exit 1
fi

sudo chmod +x "$INSTALL_PATH"

echo "Creating systemd service..."
sudo tee /etc/systemd/system/wmn-wifi-client-monitor.service > /dev/null << 'SERVICE'
[Unit]
Description=WMN WiFi Client Monitor
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/wmn-wifi-client-monitor.sh
Restart=always
RestartSec=10
User=root

[Install]
WantedBy=multi-user.target
SERVICE

sudo systemctl daemon-reload
sudo systemctl enable wmn-wifi-client-monitor.service
sudo systemctl start wmn-wifi-client-monitor.service

echo ""
echo "✓ Installation complete!"
echo ""
echo "Check status with: sudo systemctl status wmn-wifi-client-monitor"
echo "View logs with: sudo journalctl -u wmn-wifi-client-monitor -f"
echo "Once the debugging is over disable service with: sudo systemctl disable wmn-wifi-client-monitor to prevent it from running on restart"
echo "Once the debugging is over stop service with: sudo systemctl stop wmn-wifi-client-monitor"
