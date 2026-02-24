#!/bin/bash

echo "=== Installing MT7921 Auto-Fix for Dual Boot ==="
echo ""

# Create the fix script in /usr/local/bin
echo "Creating fix script..."
sudo tee /usr/local/bin/mt7921-pci-reset.sh > /dev/null << 'SCRIPT'
#!/bin/bash

# Find MT7921 PCI address
MT7921_PCI=$(lspci -nn | grep -i "MT7921\|14c3:7961" | cut -d' ' -f1)

if [ -z "$MT7921_PCI" ]; then
    exit 0
fi

# Unload modules
modprobe -r mt7921e mt792x_lib mt7921_common mt76_connac_lib mt76 2>/dev/null
sleep 2

# PCI reset
echo 1 > /sys/bus/pci/devices/0000:${MT7921_PCI}/reset 2>/dev/null
sleep 2

# Remove and rescan
echo 1 > /sys/bus/pci/devices/0000:${MT7921_PCI}/remove 2>/dev/null
sleep 1
echo 1 > /sys/bus/pci/rescan 2>/dev/null
sleep 3

# Reload driver
modprobe mt7921e
sleep 2

exit 0
SCRIPT

sudo chmod +x /usr/local/bin/mt7921-pci-reset.sh

# Create systemd service
echo "Creating systemd service..."
sudo tee /etc/systemd/system/mt7921-pci-reset.service > /dev/null << 'SERVICE'
[Unit]
Description=MT7921 PCI Reset (fixes Windows dual-boot corruption)
DefaultDependencies=no
After=systemd-modules-load.service
Before=NetworkManager.service
Before=bluetooth.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/mt7921-pci-reset.sh
RemainAfterExit=yes

[Install]
WantedBy=sysinit.target
SERVICE

# Enable the service
sudo systemctl daemon-reload
sudo systemctl enable mt7921-pci-reset.service

echo ""
echo "==================================================================="
echo "                    INSTALLATION COMPLETE                           "
echo "==================================================================="
echo ""
echo "✅ Auto-fix service installed and enabled"
echo ""
echo "What happens now:"
echo "  • Every boot, the MT7921 gets a PCI-level reset"
echo "  • This clears Windows firmware corruption"
echo "  • WiFi and Bluetooth will work after Windows boots"
echo ""
echo "==================================================================="
echo "                         IMPORTANT                                  "
echo "==================================================================="
echo ""
echo "Reboot now to test:"
echo ""
echo "    sudo reboot"
echo ""
echo "After reboot, WiFi should work even after booting from Windows!"
echo ""
echo "If you want to disable this service later:"
echo "    sudo systemctl disable mt7921-pci-reset.service"
echo ""
echo "==================================================================="
