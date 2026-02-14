#!/bin/bash

echo "=== Restoring Network - Undoing MT7921 Changes ==="
echo ""

# 1. Remove the problematic modprobe config
echo "Removing /etc/modprobe.d/mt7921.conf..."
sudo rm -f /etc/modprobe.d/mt7921.conf

# 2. Restore NetworkManager config
echo "Removing NetworkManager wifi-powersave config..."
sudo rm -f /etc/NetworkManager/conf.d/wifi-powersave.conf

# 3. Disable the reset service
echo "Disabling mt7921-reset service..."
sudo systemctl disable mt7921-reset.service 2>/dev/null
sudo systemctl stop mt7921-reset.service 2>/dev/null
sudo rm -f /etc/systemd/system/mt7921-reset.service
sudo systemctl daemon-reload

# 4. Remove udev rules
echo "Removing udev rules..."
sudo rm -f /etc/udev/rules.d/50-mt7921-no-autosuspend.rules
sudo udevadm control --reload-rules

# 5. Restore Bluetooth config (backup the new one first)
echo "Backing up Bluetooth config..."
sudo mv /etc/bluetooth/main.conf /etc/bluetooth/main.conf.backup 2>/dev/null

# 6. Reload the driver
echo "Reloading MT7921 driver..."
sudo modprobe -r mt7921e
sleep 2
sudo modprobe mt7921e
sleep 2

# 7. Restart NetworkManager
echo "Restarting NetworkManager..."
sudo systemctl restart NetworkManager

# 8. Restart Bluetooth
echo "Restarting Bluetooth..."
sudo systemctl restart bluetooth

echo ""
echo "=== Restoration Complete! ==="
echo ""
echo "Your network should be restored now."
echo ""
echo "IMPORTANT: Reboot your system for full restoration:"
echo "sudo reboot"
echo ""
echo "After reboot, your WiFi and Bluetooth should work normally again."
