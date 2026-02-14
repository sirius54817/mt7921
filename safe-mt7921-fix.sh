#!/bin/bash

echo "=== Safe MT7921 Performance Fix ==="
echo "This only applies settings we KNOW work"
echo ""

# 1. Re-enable ASPM disable (we know this works)
echo "Creating /etc/modprobe.d/mt7921.conf..."
sudo tee /etc/modprobe.d/mt7921.conf > /dev/null << 'EOF'
# Only disable ASPM - this is proven to work
options mt7921e disable_aspm=1
EOF

# 2. Disable WiFi power save in NetworkManager
echo "Disabling WiFi power save..."
sudo tee /etc/NetworkManager/conf.d/wifi-powersave.conf > /dev/null << 'EOF'
[connection]
wifi.powersave = 2
EOF

# 3. Simple WirePlumber config (only for LDAC stability)
echo "Creating simple WirePlumber Bluetooth config..."
mkdir -p ~/.config/wireplumber/wireplumber.conf.d/
tee ~/.config/wireplumber/wireplumber.conf.d/51-bluetooth-stable.conf > /dev/null << 'EOF'
monitor.bluez.properties = {
  bluez5.codecs = [ ldac aac sbc ]
  bluez5.enable-msbc = true
}
EOF

# 4. Reload driver to apply ASPM setting
echo "Reloading MT7921 driver..."
sudo modprobe -r mt7921e
sleep 2
sudo modprobe mt7921e
sleep 2

# 5. Restart NetworkManager
echo "Restarting NetworkManager..."
sudo systemctl restart NetworkManager
sleep 2

# 6. Restart WirePlumber
echo "Restarting WirePlumber..."
systemctl --user restart wireplumber

echo ""
echo "=== Done! ==="
echo ""
echo "What was applied:"
echo "1. ✅ MT7921 ASPM disabled (proven fix)"
echo "2. ✅ WiFi power save disabled"
echo "3. ✅ Simple Bluetooth codec config"
echo ""
echo "WiFi should be fast now. Test your connection speed."
echo ""
echo "If speed is still slow after a few seconds, try reconnecting to WiFi."
echo ""
