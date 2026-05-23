#!/bin/sh
# System: pfSense Gateway
# Function: Edge Boundary Topology Monitor
# Description: Detects WAN IP shifts and triggers an Out-of-Band (OOB) notification relay via local SSH bridge.

# --- Configuration ---
STATE_FILE="/var/db/last_wan_ip.txt"
RELAY_USER="service_account"       # Local user on the internal Relay Node (e.g., Raspberry Pi)
RELAY_IP="192.168.1.10"            # Local IP of the Relay Node
# ---------------------

# 1. Retrieve the current public IP via external reflector
CURRENT_IP=$(curl -s --max-time 10 https://ifconfig.me)

# Verify valid payload receipt before proceeding
if [ -z "$CURRENT_IP" ]; then
    exit 0
fi

# 2. Read the historical state baseline
if [ -f "$STATE_FILE" ]; then
    LAST_IP=$(cat "$STATE_FILE")
else
    LAST_IP="none"
fi

# 3. Evaluate state and execute conditional relay
if [ "$CURRENT_IP" != "$LAST_IP" ]; then
    # Commit new state to prevent redundant execution
    echo "$CURRENT_IP" > "$STATE_FILE"
    
    # Execute the internal SSH payload trigger on the OOB Relay Node
    ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=no ${RELAY_USER}@${RELAY_IP} "/home/${RELAY_USER}/oob_relay.sh $CURRENT_IP"
fi