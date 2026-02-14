#!/bin/bash

echo "=== MT7921 Stable Configuration (No Auto-Reset) ==="
echo "This keeps WiFi working on every boot"
echo ""

# First, remove the broken auto-reset service if it exists
echo "Removing auto-reset service (it breaks WiFi)..."
sudo systemctl disable mt7921-reset.service 2>/dev/null
sudo systemctl stop mt7921-reset.service 2>/dev/null
sudo rm -f /etc/systemd/system/mt7921-reset.service
sudo systemctl daemon-reload

# 1. MT7921 driver - only ASPM disable
echo "Creating /etc/modprobe.d/mt7921.conf..."
sudo tee /etc/modprobe.d/mt7921.conf > /dev/null << 'EOF'
# Disable ASPM for stability
options mt7921e disable_aspm=1
EOF

# 2. NetworkManager - disable WiFi power save
echo "Configuring NetworkManager..."
sudo tee /etc/NetworkManager/conf.d/wifi-powersave.conf > /dev/null << 'EOF'
[connection]
wifi.powersave = 2
EOF

# 3. WirePlumber - Bluetooth codec optimization
echo "Creating WirePlumber Bluetooth config..."
mkdir -p ~/.config/wireplumber/wireplumber.conf.d/
tee ~/.config/wireplumber/wireplumber.conf.d/51-bluetooth-stable.conf > /dev/null << 'EOF'
monitor.bluez.properties = {
  bluez5.codecs = [ ldac aac sbc ]
  bluez5.enable-msbc = true
  bluez5.enable-hw-volume = true
  bluez5.a2dp.ldac.quality = "sq"
}
EOF

# 4. Create MANUAL reset script for Windows->Linux boots
echo "Creating manual reset script..."
tee ~/reset-bt-wifi.sh > /dev/null << 'EOF'
#!/bin/bash
echo "Resetting MT7921 card..."
sudo modprobe -r mt7921e
sleep 2
sudo modprobe mt7921e
sleep 2
sudo systemctl restart NetworkManager
echo "Done! WiFi and Bluetooth reset."
EOF

chmod +x ~/reset-bt-wifi.sh

echo ""
echo "==================================================================="
echo "                    CONFIGURATION COMPLETE                          "
echo "==================================================================="
echo ""
echo "✅ What was configured:"
echo ""
echo "1. MT7921 ASPM disabled"
echo "2. WiFi power save disabled"
echo "3. Bluetooth codecs optimized (LDAC/AAC/SBC)"
echo "4. Manual reset script created: ~/reset-bt-wifi.sh"
echo ""
echo "==================================================================="
echo "                         IMPORTANT                                  "
echo "==================================================================="
echo ""
echo "You need to rebuild initramfs for the ASPM setting:"
echo ""
echo "    sudo mkinitcpio -P"
echo ""
echo "Then reboot:"
echo ""
echo "    sudo reboot"
echo ""
echo "==================================================================="
echo "                    DUAL-BOOT INSTRUCTIONS                          "
echo "==================================================================="
echo ""
echo "WiFi will work normally when booting Linux->Linux"
echo ""
echo "When you boot Windows->Linux and WiFi/BT don't work:"
echo "  Run this command ONCE:"
echo ""
echo "    ~/reset-bt-wifi.sh"
echo ""
echo "This manually resets the card only when needed."
echo ""
echo "==================================================================="
