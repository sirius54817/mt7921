#!/bin/bash

echo "=== MT7921 AGGRESSIVE Reset (Stronger Fix) ==="
echo ""

# Find MT7921 PCI address
MT7921_PCI=$(lspci -nn | grep -i "MT7921\|14c3:7961" | cut -d' ' -f1)

if [ -z "$MT7921_PCI" ]; then
    echo "Error: MT7921 not found!"
    exit 1
fi

echo "Found MT7921 at: $MT7921_PCI"
echo ""

# Step 1: Stop all services using the card
echo "Stopping services..."
sudo systemctl stop NetworkManager
sudo systemctl stop bluetooth
sudo systemctl stop wpa_supplicant
sleep 2

# Step 2: Unload ALL related modules in correct order
echo "Unloading all MT7921 modules..."
sudo modprobe -r btusb
sudo modprobe -r btintel
sudo modprobe -r btbcm
sudo modprobe -r btrtl
sudo modprobe -r btmtk
sudo modprobe -r mt7921e
sudo modprobe -r mt792x_lib  
sudo modprobe -r mt7921_common
sudo modprobe -r mt76_connac_lib
sudo modprobe -r mt76
sudo modprobe -r mac80211
sudo modprobe -r cfg80211
sleep 3

# Step 3: Delete firmware cache to force reload
echo "Clearing firmware cache..."
sudo rm -rf /lib/firmware/mediatek/*.bin.xz 2>/dev/null
sudo rm -rf /var/lib/firmware/mediatek/* 2>/dev/null
sleep 1

# Step 4: Power cycle via ACPI
echo "ACPI power cycle..."
echo 1 | sudo tee /sys/bus/pci/devices/0000:${MT7921_PCI}/reset > /dev/null
sleep 2

# Step 5: Force D3 power state (deepest sleep)
echo "Forcing deep power state..."
echo auto | sudo tee /sys/bus/pci/devices/0000:${MT7921_PCI}/power/control > /dev/null
sleep 2
echo on | sudo tee /sys/bus/pci/devices/0000:${MT7921_PCI}/power/control > /dev/null
sleep 2

# Step 6: Complete removal and rescan
echo "Removing PCI device..."
echo 1 | sudo tee /sys/bus/pci/devices/0000:${MT7921_PCI}/remove > /dev/null
sleep 3

echo "Rescanning PCI bus..."
echo 1 | sudo tee /sys/bus/pci/rescan > /dev/null
sleep 5

# Step 7: Restore firmware files
echo "Restoring firmware..."
sudo pacman -S --noconfirm linux-firmware 2>/dev/null
sleep 2

# Step 8: Reload modules in correct order
echo "Reloading modules..."
sudo modprobe cfg80211
sleep 1
sudo modprobe mac80211
sleep 1
sudo modprobe mt76
sleep 1
sudo modprobe mt76_connac_lib
sleep 1
sudo modprobe mt7921_common
sleep 1
sudo modprobe mt792x_lib
sleep 1
sudo modprobe mt7921e
sleep 3
sudo modprobe btmtk
sudo modprobe btusb
sleep 2

# Step 9: Restart services
echo "Restarting services..."
sudo systemctl start bluetooth
sleep 2
sudo systemctl start NetworkManager
sleep 3

echo ""
echo "=== Aggressive Reset Complete! ==="
echo ""
echo "Wait 10 seconds, then try connecting to WiFi/Bluetooth"
echo ""
