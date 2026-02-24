#!/bin/bash

# MT7921 Windows→Linux State Reset Fix
# This fixes the card corruption that happens after booting from Windows

echo "=== MT7921 Windows→Linux Fix ==="
echo ""
echo "This script fixes MT7921 when it's broken after booting from Windows"
echo ""

# The problem: Windows leaves the MT7921 firmware in a bad state
# The solution: Force a complete hardware reset using PCI subsystem

# Step 1: Identify the MT7921 PCI device
echo "Finding MT7921 PCI device..."
MT7921_PCI=$(lspci -nn | grep -i "MT7921\|14c3:7961" | cut -d' ' -f1)

if [ -z "$MT7921_PCI" ]; then
    echo "Error: MT7921 card not found!"
    exit 1
fi

echo "Found MT7921 at PCI address: $MT7921_PCI"
echo ""

# Step 2: Unload all MT7921 modules
echo "Unloading MT7921 drivers..."
sudo modprobe -r mt7921e 2>/dev/null
sudo modprobe -r mt792x_lib 2>/dev/null
sudo modprobe -r mt7921_common 2>/dev/null
sudo modprobe -r mt76_connac_lib 2>/dev/null
sudo modprobe -r mt76 2>/dev/null

sleep 2

# Step 3: Force PCI device reset (this is the key!)
echo "Performing PCI device reset..."
echo 1 | sudo tee /sys/bus/pci/devices/0000:${MT7921_PCI}/reset > /dev/null

sleep 2

# Step 4: Remove and rescan PCI device (full hardware reset)
echo "Removing PCI device..."
echo 1 | sudo tee /sys/bus/pci/devices/0000:${MT7921_PCI}/remove > /dev/null

sleep 1

echo "Rescanning PCI bus..."
echo 1 | sudo tee /sys/bus/pci/rescan > /dev/null

sleep 3

# Step 5: Reload drivers
echo "Reloading MT7921 drivers..."
sudo modprobe mt7921e

sleep 2

# Step 6: Restart services
echo "Restarting NetworkManager and Bluetooth..."
sudo systemctl restart NetworkManager
sudo systemctl restart bluetooth

sleep 2

echo ""
echo "=== Reset Complete! ==="
echo ""
echo "Your MT7921 WiFi and Bluetooth should work now."
echo ""
echo "If WiFi doesn't connect automatically, reconnect manually."
echo ""
