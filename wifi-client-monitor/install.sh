#!/bin/bash
sudo mkdir -p /usr/local/bin
sudo cp wifi_monitor.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/wmn-wifi-client-monitor.sh

sudo tee /etc/systemd/system/wmn-wifi-client-monitor.service << 'SERVICE'
[Unit]
Description=Wmn wifi client monitor
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
sudo systemctl enable wifi-monitor.service
sudo systemctl start wifi-monitor.service
echo "Installation complete. Check status with: sudo systemctl status wifi-monitor"
EOF

chmod +x install_monitor.sh
