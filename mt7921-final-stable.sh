#!/bin/bash

echo "=== MT7921 Final Stable Configuration ==="
echo "Optimized for dual-boot stability without breaking WiFi/Bluetooth"
echo ""

# 1. MT7921 driver - only proven working options
echo "Creating /etc/modprobe.d/mt7921.conf..."
sudo tee /etc/modprobe.d/mt7921.conf > /dev/null << 'EOF'
# Disable ASPM for stability (proven to work)
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
  -- Codec priority: LDAC > AAC > SBC
  bluez5.codecs = [ ldac aac sbc ]
  
  -- Enable better codec support
  bluez5.enable-msbc = true
  bluez5.enable-hw-volume = true
  
  -- Use standard quality LDAC for better stability
  bluez5.a2dp.ldac.quality = "sq"
}
EOF

# 4. Systemd service - auto-reset card on boot (fixes Windows->Linux issue)
echo "Creating auto-reset service for dual-boot..."
sudo tee /etc/systemd/system/mt7921-reset.service > /dev/null << 'EOF'
[Unit]
Description=Reset MT7921 card on boot (fixes dual-boot issues)
After=multi-user.target
Before=NetworkManager.service bluetooth.service

[Service]
Type=oneshot
ExecStart=/usr/bin/modprobe -r mt7921e
ExecStart=/usr/bin/sleep 2
ExecStart=/usr/bin/modprobe mt7921e
ExecStart=/usr/bin/sleep 2
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
sudo systemctl daemon-reload
sudo systemctl enable mt7921-reset.service

# 5. Apply changes immediately (for current session)
echo ""
echo "Applying changes to current session..."
echo "Reloading MT7921 driver..."
sudo modprobe -r mt7921e 2>/dev/null
sleep 2
sudo modprobe mt7921e
sleep 2

echo "Restarting NetworkManager..."
sudo systemctl restart NetworkManager
sleep 2

echo "Restarting WirePlumber..."
systemctl --user restart wireplumber 2>/dev/null

echo ""
echo "==================================================================="
echo "                    CONFIGURATION COMPLETE                          "
echo "==================================================================="
echo ""
echo "✅ What was configured:"
echo ""
echo "1. MT7921 ASPM disabled (improves stability)"
echo "2. WiFi power save disabled (prevents speed drops)"
echo "3. Bluetooth codecs optimized (LDAC/AAC/SBC with stability)"
echo "4. Auto card reset on boot (fixes Windows->Linux dual-boot issue)"
echo ""
echo "==================================================================="
echo "                         IMPORTANT                                  "
echo "==================================================================="
echo ""
echo "REBOOT NOW for all changes to take full effect:"
echo ""
echo "    sudo reboot"
echo ""
echo "==================================================================="
echo "                    WHAT TO EXPECT                                  "
echo "==================================================================="
echo ""
echo "After reboot:"
echo "  • WiFi will be fast and stable"
echo "  • Bluetooth audio will work with LDAC/AAC"
echo "  • No need to manually reseat card after booting from Windows"
echo "  • Card auto-resets on every boot (handles dual-boot issues)"
echo ""
echo "If you still get audio dropouts:"
echo "  1. Check antenna cables inside laptop (loose/damaged)"
echo "  2. Do 60-second power button reset (unplug, hold 60s)"
echo "  3. Consider upgrading to Intel AX210 card (~₹1,300)"
echo ""
echo "==================================================================="
