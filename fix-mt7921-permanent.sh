#!/bin/bash

echo "=== MT7921 Permanent Fix Script ==="
echo ""

# 1. Remove the broken systemd service created by break script
echo "Removing broken mt7921-reset.service..."
sudo systemctl stop mt7921-reset.service 2>/dev/null
sudo systemctl disable mt7921-reset.service 2>/dev/null
sudo rm -f /etc/systemd/system/mt7921-reset.service
sudo systemctl daemon-reload

# 2. Remove the broken modprobe config
echo "Removing old modprobe config..."
sudo rm -f /etc/modprobe.d/mt7921.conf

# 3. Write the CORRECT safe modprobe config
echo "Writing safe modprobe config..."
sudo tee /etc/modprobe.d/mt7921.conf > /dev/null << 'EOF'
# Only disable ASPM - proven to work
options mt7921e disable_aspm=1
EOF

# 4. Remove broken udev rule
echo "Removing broken udev rule..."
sudo rm -f /etc/udev/rules.d/50-mt7921-no-autosuspend.rules
sudo udevadm control --reload-rules

# 5. Keep the good NetworkManager wifi powersave config
echo "Ensuring WiFi power save is disabled..."
sudo tee /etc/NetworkManager/conf.d/wifi-powersave.conf > /dev/null << 'EOF'
[connection]
wifi.powersave = 2
EOF

# 6. Keep the good WirePlumber Bluetooth config
echo "Writing WirePlumber Bluetooth config..."
mkdir -p ~/.config/wireplumber/wireplumber.conf.d/
tee ~/.config/wireplumber/wireplumber.conf.d/51-bluetooth-stable.conf > /dev/null << 'EOF'
monitor.bluez.properties = {
  bluez5.codecs = [ ldac aac sbc ]
  bluez5.enable-msbc = true
}
EOF

# 7. Create a proper systemd service that ONLY reloads the driver cleanly
echo "Creating proper MT7921 fix service..."
sudo tee /etc/systemd/system/mt7921-fix.service > /dev/null << 'EOF'
[Unit]
Description=MT7921 WiFi fix on boot
After=network-pre.target
Before=NetworkManager.service

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'modprobe -r mt7921e 2>/dev/null; sleep 1; modprobe mt7921e'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable mt7921-fix.service

# 8. Rebuild initramfs so modprobe config is baked in
echo "Rebuilding initramfs..."
sudo mkinitcpio -P

echo ""
echo "=== Done! ==="
echo ""
echo "What was fixed:"
echo "1. ✅ Removed broken mt7921-reset.service"
echo "2. ✅ Removed broken udev rules"
echo "3. ✅ Safe modprobe config written (ASPM disabled)"
echo "4. ✅ WiFi power save disabled permanently"
echo "5. ✅ Bluetooth codec config kept"
echo "6. ✅ New clean mt7921-fix.service created and enabled"
echo "7. ✅ Initramfs rebuilt"
echo ""
echo "Please reboot now:"
echo "sudo reboot"
