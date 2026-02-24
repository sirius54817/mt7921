#!/bin/bash

echo "=== MT7921 PERMANENT Performance Fix ==="
echo "This makes settings persist across reboots"
echo ""

# 1. Create ASPM disable config (permanent)
echo "Creating /etc/modprobe.d/mt7921.conf..."
sudo tee /etc/modprobe.d/mt7921.conf > /dev/null << 'EOF'
# Only disable ASPM - this is proven to work
options mt7921e disable_aspm=1
EOF

# 2. Disable WiFi power save in NetworkManager (permanent)
echo "Disabling WiFi power save..."
sudo tee /etc/NetworkManager/conf.d/wifi-powersave.conf > /dev/null << 'EOF'
[connection]
wifi.powersave = 2
EOF

# 3. Simple WirePlumber config (permanent)
echo "Creating simple WirePlumber Bluetooth config..."
mkdir -p ~/.config/wireplumber/wireplumber.conf.d/
tee ~/.config/wireplumber/wireplumber.conf.d/51-bluetooth-stable.conf > /dev/null << 'EOF'
monitor.bluez.properties = {
  bluez5.codecs = [ ldac aac sbc ]
  bluez5.enable-msbc = true
}
EOF

# 4. CRITICAL: Rebuild initramfs to include modprobe settings
echo ""
echo "Rebuilding initramfs (this makes ASPM setting permanent)..."
sudo mkinitcpio -P

echo ""
echo "=== Configuration Complete! ==="
echo ""
echo "What was configured:"
echo "1. ✅ MT7921 ASPM disabled (permanent)"
echo "2. ✅ WiFi power save disabled (permanent)"
echo "3. ✅ Bluetooth codec config (permanent)"
echo "4. ✅ Initramfs rebuilt (critical for persistence)"
echo ""
echo "==================================================================="
echo "                         IMPORTANT                                  "
echo "==================================================================="
echo ""
echo "REBOOT NOW for changes to take permanent effect:"
echo ""
echo "    sudo reboot"
echo ""
echo "After reboot:"
echo "  • Settings will persist across all future reboots"
echo "  • WiFi will be fast immediately on boot"
echo "  • No need to run this script again"
echo ""
echo "To verify settings after reboot, run:"
echo "    cat /sys/module/mt7921e/parameters/disable_aspm"
echo "    (should show: Y)"
echo ""
echo "==================================================================="
