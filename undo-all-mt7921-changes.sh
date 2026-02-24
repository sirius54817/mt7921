#!/bin/bash

echo "=== Undoing ALL MT7921 Configuration Changes ==="
echo ""

# 1. Remove modprobe config
echo "Removing /etc/modprobe.d/mt7921.conf..."
sudo rm -f /etc/modprobe.d/mt7921.conf
sudo rm -f /etc/modprobe.d/mt7921-alt.conf

# 2. Remove NetworkManager WiFi power save config
echo "Removing NetworkManager configs..."
sudo rm -f /etc/NetworkManager/conf.d/wifi-powersave.conf

# 3. Remove Bluetooth main.conf
echo "Removing Bluetooth configs..."
sudo rm -f /etc/bluetooth/main.conf
sudo rm -f /etc/bluetooth/main.conf.backup

# 4. Remove WirePlumber config
echo "Removing WirePlumber configs..."
rm -f ~/.config/wireplumber/wireplumber.conf.d/51-mt7921-bluetooth.conf
rm -f ~/.config/wireplumber/wireplumber.conf.d/51-bluetooth-stable.conf
rm -f ~/.config/wireplumber/wireplumber.conf.d/51-ldac-low.conf

# 5. Disable and remove systemd services
echo "Removing systemd services..."
sudo systemctl disable mt7921-reset.service 2>/dev/null
sudo systemctl stop mt7921-reset.service 2>/dev/null
sudo rm -f /etc/systemd/system/mt7921-reset.service

sudo systemctl disable mt7921-pci-reset.service 2>/dev/null
sudo systemctl stop mt7921-pci-reset.service 2>/dev/null
sudo rm -f /etc/systemd/system/mt7921-pci-reset.service

sudo systemctl disable mt7921-slow-init.service 2>/dev/null
sudo systemctl stop mt7921-slow-init.service 2>/dev/null
sudo rm -f /etc/systemd/system/mt7921-slow-init.service

sudo systemctl daemon-reload

# 6. Remove udev rules
echo "Removing udev rules..."
sudo rm -f /etc/udev/rules.d/50-mt7921-no-autosuspend.rules
sudo udevadm control --reload-rules

# 7. Remove custom scripts
echo "Removing custom scripts..."
sudo rm -f /usr/local/bin/mt7921-pci-reset.sh
sudo rm -f /usr/local/bin/deep-shutdown.sh
rm -f ~/reset-bt-wifi.sh

# 8. Reload driver to default state
echo "Reloading MT7921 driver to default state..."
sudo modprobe -r mt7921e 2>/dev/null
sleep 2
sudo modprobe mt7921e
sleep 2

# 9. Restart services
echo "Restarting NetworkManager and Bluetooth..."
sudo systemctl restart NetworkManager
sudo systemctl restart bluetooth
systemctl --user restart wireplumber 2>/dev/null

echo ""
echo "==================================================================="
echo "                    CLEANUP COMPLETE                                "
echo "==================================================================="
echo ""
echo "✅ All MT7921 custom configurations removed"
echo "✅ Driver restored to default state"
echo "✅ Services restarted"
echo ""
echo "Your system is now back to default MT7921 configuration."
echo ""
echo "Reboot recommended:"
echo "    sudo reboot"
echo ""
echo "==================================================================="
