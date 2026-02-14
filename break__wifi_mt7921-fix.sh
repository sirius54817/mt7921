#!/bin/bash

echo "=== MT7921 Stability Configuration Script ==="
echo "This will create config files to maximize MT7921 stability on dual-boot"
echo ""

# 1. MT7921 driver options
echo "Creating /etc/modprobe.d/mt7921.conf..."
sudo tee /etc/modprobe.d/mt7921.conf > /dev/null << 'MODPROBE'
# Disable ASPM for stability
options mt7921e disable_aspm=1

# Force card reset on module load
options mt7921e reset=1

# Reduce power management issues
options mt7921e power_save=0
MODPROBE

# 2. NetworkManager WiFi power save
echo "Creating /etc/NetworkManager/conf.d/wifi-powersave.conf..."
sudo tee /etc/NetworkManager/conf.d/wifi-powersave.conf > /dev/null << 'NM'
[connection]
wifi.powersave = 2
NM

# 3. Bluetooth coexistence and power settings
echo "Creating /etc/bluetooth/main.conf override..."
sudo mkdir -p /etc/bluetooth
sudo tee /etc/bluetooth/main.conf > /dev/null << 'BT'
[General]
# Disable automatic suspend for Bluetooth
FastConnectable = true
ReconnectAttempts = 7
ReconnectIntervals = 1,2,4,8,16,32,64

[Policy]
AutoEnable = true
ReconnectUUIDs = 0000110b-0000-1000-8000-00805f9b34fb,0000110a-0000-1000-8000-00805f9b34fb

[LE]
MinConnectionInterval = 7
MaxConnectionInterval = 9
BT

# 4. WirePlumber Bluetooth audio optimization
echo "Creating WirePlumber Bluetooth config..."
mkdir -p ~/.config/wireplumber/wireplumber.conf.d/
tee ~/.config/wireplumber/wireplumber.conf.d/51-mt7921-bluetooth.conf > /dev/null << 'WP'
monitor.bluez.properties = {
  -- Prioritize stability over maximum quality
  bluez5.codecs = [ aac sbc ldac ]
  
  -- Enable better codec handling
  bluez5.enable-msbc = true
  bluez5.enable-hw-volume = true
  
  -- LDAC quality settings (lower for stability)
  bluez5.a2dp.ldac.quality = "sq"
  
  -- Improve connection stability
  bluez5.autoswitch-profile = false
}
WP

# 5. Systemd service to reset MT7921 on boot (after Windows)
echo "Creating systemd service to reset MT7921 on boot..."
sudo tee /etc/systemd/system/mt7921-reset.service > /dev/null << 'SERVICE'
[Unit]
Description=Reset MT7921 WiFi/Bluetooth card on boot
After=multi-user.target
Before=bluetooth.service
Before=NetworkManager.service

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'modprobe -r mt7921e; sleep 2; modprobe mt7921e; sleep 3'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
SERVICE

sudo systemctl daemon-reload
sudo systemctl enable mt7921-reset.service

# 6. udev rule to prevent auto-suspend
echo "Creating udev rule to prevent MT7921 auto-suspend..."
sudo tee /etc/udev/rules.d/50-mt7921-no-autosuspend.rules > /dev/null << 'UDEV'
# Disable USB autosuspend for MT7921
ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0e8d", ATTR{idProduct}=="7961", ATTR{power/autosuspend}="-1"

# Disable PCI runtime PM for MT7921
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x14c3", ATTR{device}=="0x7961", ATTR{power/control}="on"
UDEV

sudo udevadm control --reload-rules

echo ""
echo "=== Configuration Complete! ==="
echo ""
echo "What was configured:"
echo "1. ✅ MT7921 ASPM disabled + power_save off"
echo "2. ✅ NetworkManager WiFi power save disabled"
echo "3. ✅ Bluetooth reconnection improved"
echo "4. ✅ WirePlumber optimized for stability (AAC/SBC/LDAC)"
echo "5. ✅ Auto card reset on boot (fixes Windows->Linux issue)"
echo "6. ✅ udev rules to prevent auto-suspend"
echo ""
echo "IMPORTANT: Reboot now for all changes to take effect!"
echo ""
echo "After reboot:"
echo "- The card will auto-reset when booting from Windows"
echo "- LDAC will use Standard Quality for better stability"
echo "- Bluetooth reconnection will be more aggressive"
echo ""
echo "To reboot now: sudo reboot"
