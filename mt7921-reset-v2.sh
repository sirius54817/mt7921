#!/bin/bash

echo "=== MT7921 Complete Reset ==="
echo ""

# Find MT7921 PCI address
MT7921_FULL=$(lspci -nn | grep -i "MT7921\|14c3:7961" | cut -d' ' -f1)

if [ -z "$MT7921_FULL" ]; then
    echo "Error: MT7921 not found!"
    exit 1
fi

echo "Found MT7921 at: $MT7921_FULL"

# Handle both cases: "2d:00.0" or "0000:2d:00.0"
if [[ $MT7921_FULL == 0000:* ]]; then
    # Already has domain prefix
    PCI_PATH="/sys/bus/pci/devices/${MT7921_FULL}"
else
    # Need to add domain prefix
    PCI_PATH="/sys/bus/pci/devices/0000:${MT7921_FULL}"
fi

echo "PCI path: $PCI_PATH"

# Verify path exists
if [ ! -d "$PCI_PATH" ]; then
    echo "Error: PCI device path not found at $PCI_PATH"
    echo ""
    echo "Trying to find correct path..."
    ls -la /sys/bus/pci/devices/ | grep -i "2d:00"
    exit 1
fi

echo "Path verified!"
echo ""

# Step 1: Stop services
echo "Stopping services..."
sudo systemctl stop NetworkManager
sudo systemctl stop bluetooth
sleep 2

# Step 2: Unload modules
echo "Unloading modules..."
sudo modprobe -r btusb 2>/dev/null
sudo modprobe -r mt7921e 2>/dev/null
sudo modprobe -r mt792x_lib 2>/dev/null
sudo modprobe -r mt7921_common 2>/dev/null
sudo modprobe -r mt76_connac_lib 2>/dev/null
sudo modprobe -r mt76 2>/dev/null
sleep 3

# Step 3: Power cycle
echo "Power cycling..."
echo auto | sudo tee ${PCI_PATH}/power/control > /dev/null
sleep 2
echo on | sudo tee ${PCI_PATH}/power/control > /dev/null
sleep 2

# Step 4: PCI reset
echo "PCI reset..."
if [ -f "${PCI_PATH}/reset" ]; then
    echo 1 | sudo tee ${PCI_PATH}/reset > /dev/null
    sleep 3
else
    echo "Warning: reset file not found, skipping..."
fi

# Step 5: Remove device
echo "Removing device..."
echo 1 | sudo tee ${PCI_PATH}/remove > /dev/null
sleep 2

# Step 6: Rescan
echo "Rescanning PCI bus..."
echo 1 | sudo tee /sys/bus/pci/rescan > /dev/null
sleep 5

# Step 7: Reload modules
echo "Reloading modules..."
sudo modprobe mt76
sleep 1
sudo modprobe mt76_connac_lib
sleep 1
sudo modprobe mt7921_common
sleep 1
sudo modprobe mt792x_lib
sleep 1
sudo modprobe mt7921e
sleep 2
sudo modprobe btusb
sleep 2

# Step 8: Restart services
echo "Restarting services..."
sudo systemctl start bluetooth
sleep 2
sudo systemctl start NetworkManager
sleep 3

echo ""
echo "=== Done! ==="
echo ""
echo "Wait 10 seconds, then test WiFi/Bluetooth"
echo ""
