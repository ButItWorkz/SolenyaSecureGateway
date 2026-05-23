#!/bin/bash
# System: Internal Linux Node (Raspberry Pi)
# Function: OOB Cryptographic Messaging Relay
# Description: Receives boundary updates from the gateway and transmits them via E2E encryption.

TARGET_NUMBER="+12345678900"  # Your registered Signal destination number
NEW_IP=$1

if [ -z "$NEW_IP" ]; then
    echo "Error: No payload provided."
    exit 1
fi

# Execute the native signal-cli binary to dispatch the E2E encrypted transmission
# Note: Requires correct Java environment and libsignal_jni.so injection in /usr/lib/
signal-cli -u $TARGET_NUMBER send -m "Gateway Edge Reallocation: New Public IP is $NEW_IP" $TARGET_NUMBER