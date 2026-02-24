#!/bin/bash

echo "=== MT7921 Slow Initialization Fix ==="
echo "Adding delays to give the card time to initialize properly"
echo ""

# Create a service with longer delays
sudo tee /etc/systemd/system/mt7921-slow-init.service > /dev/null << 'EOF'
[Unit]
Description=MT7921 Slow Initialization (fixes timing issues)
After=multi-user.target
Before=NetworkManager.service
Before=bluetooth.service

[Service]
Type=oneshot
ExecStartPre=/usr/bin/sleep 5
ExecStart=/usr/bin/modprobe -r mt7921e
ExecStart=/usr/bin/sleep 3
ExecStart=/usr/bin/modprobe mt7921e
ExecStart=/usr/bin/sleep 5
ExecStartPost=/usr/bin/sleep 3
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Disable the old service
sudo systemctl disable mt7921-pci-reset.service 2>/dev/null

# Enable new service
sudo systemctl daemon-reload
sudo systemctl enable mt7921-slow-init.service

echo ""
echo "✅ Installed slow initialization service"
echo ""
echo "This gives the MT7921 more time to initialize properly."
echo ""
echo "Reboot and test:"
echo "  sudo reboot"
echo ""
