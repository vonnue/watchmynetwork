#!/bin/bash

REPO_URL="https://raw.githubusercontent.com/vonnue/watchmynetwork/main/wifi-client-monitor/wmn-wifi-client-monitor.sh"
INSTALL_PATH="/usr/local/bin/wmn-wifi-client-monitor.sh"
SERVICE_NAME="wmn-wifi-client-monitor"
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}.service"

echo "Installing WMN WiFi Client Monitor..."

echo "Cleaning up any existing installation..."

sudo systemctl stop $SERVICE_NAME 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✓ Service stopped"
fi

sudo systemctl disable $SERVICE_NAME 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✓ Service disabled"
fi

if [ -f "$SERVICE_PATH" ]; then
    sudo rm -f "$SERVICE_PATH"
    echo "✓ Service file removed"
fi

if [ -f "$INSTALL_PATH" ]; then
    sudo rm -f "$INSTALL_PATH"
    echo "✓ Script removed"
fi

sudo systemctl daemon-reload
echo "✓ Cleanup complete"
echo "

# Download the monitoring script
echo "Downloading monitoring script..."
sudo curl -sSL "$REPO_URL" -o "$INSTALL_PATH"

if [ $? -ne 0 ]; then
    echo "Error: Failed to download monitoring script"
    exit 1
fi

sudo chmod +x "$INSTALL_PATH"
echo "✓ Script downloaded and made executable"

# Create systemd service
echo "Creating systemd service..."
sudo tee "$SERVICE_PATH" > /dev/null << 'SERVICE'
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

# Reload systemd, enable and start service
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl start $SERVICE_NAME

echo ""
echo "✓ Installation complete!"
echo ""
echo "Check status with: sudo systemctl status $SERVICE_NAME"
echo "View logs with: sudo journalctl -u $SERVICE_NAME -f"
echo "Once debugging is over, disable service with: sudo systemctl disable $SERVICE_NAME"
echo "Once debugging is over, stop service with: sudo systemctl stop $SERVICE_NAME"
