#!/bin/bash

echo "=== Trying Multiple Reset Strategies ==="
echo "This tries different things that might trigger the 'random fix'"
echo ""

# Try different reset methods in sequence

for i in {1..5}; do
    echo "Attempt $i/5..."
    
    # Method 1: Quick reset
    sudo modprobe -r mt7921e
    sleep 2
    sudo modprobe mt7921e
    sleep 3
    
    # Check if Bluetooth works now
    if rfkill list bluetooth | grep -q "Soft blocked: no"; then
        echo "Checking if Bluetooth is responding..."
        sudo systemctl restart bluetooth
        sleep 2
        
        # Try to see if we can scan
        timeout 3 bluetoothctl scan on 2>/dev/null && echo "✅ Bluetooth working!" && break
    fi
    
    echo "Not fixed yet, trying next method..."
    
    # Method 2: With NetworkManager restart
    sudo systemctl restart NetworkManager
    sleep 3
    
    # Method 3: Toggle WiFi
    nmcli radio wifi off
    sleep 2
    nmcli radio wifi on
    sleep 3
    
    # Method 4: Bluetooth power cycle
    sudo rfkill block bluetooth
    sleep 1
    sudo rfkill unblock bluetooth
    sleep 2
    
    echo "Waiting before next attempt..."
    sleep 5
done

echo ""
echo "=== Attempted 5 different reset strategies ==="
echo "Test your Bluetooth now"
echo ""
