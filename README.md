# Solenya Enterprise OOB VPN Architecture

## Abstract & Philosophy
The Solenya Enterprise OOB (Out-of-Band) VPN Architecture is a zero-trust, high-assurance framework for establishing an IPsec IKEv2 full-tunnel virtual private network.

**Project Status: Stable Release**

This project demonstrates advanced network micro-segmentation and infrastructure automation by coupling the native Windows Remote Access daemon with a decoupled, air-gapped signaling framework designed to provide boundary IP telemetry securely over End-to-End Encrypted (E2E) channels.

This is an academic and defensive engineering framework intended to demonstrate advanced operating system networking mechanics, kernel-level firewall manipulation, and secure telemetry routing, while empowering users with self-hosted, high-security tunneling capabilities.

## Ethical Use & Liability Disclaimer
This framework is provided "as is" strictly for defensive engineering, security research, and authorized systems administration. It is not intended to be utilized as malicious command-and-control (C2) infrastructure, nor should the cryptographic tunneling techniques be used to bypass legitimate, authorized network access controls or organizational egress filtering.

As the end-user, it is your absolute and sole responsibility to ensure that your usage of this tool—including the deployment of the OOB relay and the manipulation of endpoint firewall rules—is strictly ethical, legally compliant, and explicitly authorized by the owners of the target infrastructure. The authors and contributors assume no liability and are not responsible for any misuse, damage, data leaks, or legal consequences resulting from the deployment or modification of this software.

## Architecture
The framework operates on a decentralized, three-tier architecture:

1. **The Edge Security Gateway (pfSense):** Handles the IPSec IKEv2 cryptography, Outbound NAT mapping, and asymmetric packet filtering.
2. **The Cryptographic OOB Relay (Linux Node):** An internal node (e.g., a Raspberry Pi) utilizing `signal-cli` to decouple public IP telemetry detection from notification transmission, insulating the perimeter firewall from public web APIs.
3. **The Native Endpoint Client (`Secure_Gateway_Client.ps1`):** A dynamically generated Windows Presentation Foundation (WPF) GUI executed entirely in memory via PowerShell. It provides real-time state synchronization, automated certificate lifecycle management, and strict kernel-level network enforcement using purely native OS binaries.

---

## Engineering Trade-Offs & Academic Transparency
While the core philosophy of the Windows Client relies strictly on "Living off the Land" (LotL) and zero-dependency execution, specific architectural exceptions were made in the broader infrastructure to demonstrate practical utility and self-reliance.

### 1. The OOB Relay & The `signal-cli` Exception
The integration of a Raspberry Pi running the third-party `signal-cli` technically violates a pure zero-dependency constraint. A true OOB relay would emulate an Advanced Persistent Threat (APT) and likely utilize steganography, botnet routing, or obfuscated public forums for C2 style communication, evasion, and telemetry.

* **The Rationale:** The primary goal of this project was to empower independent users with highly secure infrastructure, rather than executing a flawless adversary emulation. Utilizing Signal provides robust End-to-End (E2E) encryption and the high-utility convenience of receiving real-time SMS-style alerts when an ISP IP shift occurs.
* **Alternative Implementations:** This modular architecture allows the `signal-cli` node to be easily swapped for other native transmission methods, such as an automated script pushing to an encrypted ProtonMail inbox or a secure internal forum bot.
* **Enterprise Context:** In a true enterprise environment, this entire OOB dropper architecture would be rendered unnecessary, as corporate ISPs natively provision static public IPs.

### 2. PKI Infrastructure & The CA Server
In this demonstration, the pfSense Edge Gateway doubles as the Certificate Authority (CA) responsible for minting the machine certificates. Furthermore, third-party domain hosting (DNS validation) was intentionally omitted.

* **The Rationale:** The objective was to demonstrate absolute self-reliance. By internally generating the PKI chain and tying the client to the raw firewall infrastructure, the project proves that high-security IPsec tunneling is viable without tethering to a third-party domain registrar or commercial CA.
* **Enterprise Context:** In a production, high-security environment, the Certificate Authority must be strictly air-gapped or separated onto a dedicated internal PKI server. Edge routers should never act as the primary CA for an enterprise domain.

---

## Deployment Guide

### Step 1: Gateway Configuration (pfSense)
Configure your pfSense IPsec instance to accept native Windows 11 IKEv2 connections:

* **Phase 1 (IKEv2):** Configure Mutual Certificate (RSA) authentication. Ensure the Server Certificate's Subject Alternative Name (SAN) exactly matches the FQDN or IP your clients will dial. Set cryptography to AES-GCM (256-bit), SHA256, and DH Group 14 (2048-bit).
* **Phase 2 (ESP):** Set Mode to `Tunnel IPv4` targeting `0.0.0.0/0`.
* **Outbound NAT:** Switch to **Hybrid Outbound NAT** and create an explicit mapping for your virtual IPsec subnet pool (e.g., `10.20.20.0/24`) to translate to the WAN Interface Address.
* **Firewall Rules:** Allow incoming UDP 500 (ISAKMP) and UDP 4500 (NAT-T) on the WAN interface.

### Step 2: Initialize the Topology Monitor
**Where to execute:** On the pfSense Gateway via the `cron` scheduler.

1. Deploy the `boundary_monitor.sh` script to your pfSense appliance.
2. Schedule the script to run natively via `cron` (e.g., `* * * * *`).
3. This script polls the active WAN IP. If an ISP shift is detected, it utilizes a localized SSH Trust Bridge (RSA keys) to silently push the new IP payload across the LAN to the OOB Relay node.

### Step 3: Stand up the OOB Relay
**Where to execute:** On an internal Linux Node (e.g., Raspberry Pi).

1. Install and configure `signal-cli`. Register the daemon to an administrative phone number.
2. Deploy the `oob_relay.sh` script.
3. When triggered by the Gateway's SSH command, this script ingests the payload and dispatches an End-to-End Encrypted (E2E) text message containing the new Gateway IP to the designated administrator, ensuring zero public API exposure on the firewall itself.

### Step 4: Arm the Endpoints
**Where to execute:** On the target Windows 11 clients.

1. Transfer your generated Machine Certificate (`.pfx`) and the `Secure_Gateway_Client.ps1` script to the endpoint.
2. Run the client script as an Administrator.
3. Click **"IMPORT & CLEAN"**. The script will securely ingest the `.pfx` into the `Cert:\LocalMachine\My` kernel store and immediately shred the source file payload from the disk to preserve operational security.
4. Input your Gateway IP, select your target cryptography, optionally arm the "Strict Network Enforcement" (Kill Switch), and initialize the tunnel.

---

## Technical Mechanics & Core Capabilities

### Zero-Touch State Synchronization
The native client polls the Windows Operating System dynamically. It interrogates the `Get-VpnConnection` status, virtual adapter IP tables, and `Get-NetFirewallProfile` state to ensure the UI perfectly mirrors the kernel's reality, surviving terminal crashes and unexpected adapter resets.

### The WFP Race-Condition Nudge
Standard macro and VPN software frequently crash the Windows Filtering Platform (WFP) when enforcing pre-connection firewall drops due to Network Location Awareness (NLA) failures. The Solenya client bypasses this race condition by dynamically injecting a `RemoteAccess` InterfaceType exception the millisecond the virtual adapter spins up, allowing encrypted traffic to flow while physical interfaces remain dead-dropped.

### Asymmetric Cryptographic Hot-Swapping
The UI allows users to hot-swap their Phase 2 IPsec proposals (e.g., shifting from AES-128 to GCM-AES-256). The script rewrites the Windows internal registry IPsec policy via `Set-VpnConnectionIPsecConfiguration` immediately prior to dialing the `rasman` service, bypassing legacy OS limitations.

---

## Implementation Notes: 

### pfBlockerNG Routing Conflicts:
If you are running pfBlockerNG on your pfSense Edge Gateway, be highly aware of state-table and routing conflicts between the IPsec virtual interface and the pfBlocker DNS sinkhole.

The Issue: 
* pfBlockerNG utilizes a Virtual IP (VIP), typically 10.10.10.1, to sinkhole malicious DNS requests. If your IPsec Phase 2 virtual subnet overlaps with this VIP, or if pfBlocker's strict Geo-IP/DNSBL auto-generated firewall rules blanket the IPsec interface, the Windows client will successfully complete the IKEv2 cryptographic handshake, but all encapsulated data packets will be silently dropped by the pfSense kernel.

The Solution: 
* You must ensure your IPsec Virtual Subnet (e.g., 10.20.20.0/24) is strictly segregated from the pfBlocker VIP. Additionally, you may have to manually explicitly whitelist the IPsec gateway traffic within pfBlocker's advanced settings, or ensure your IPsec interface rules are ordered above the auto-generated pfBlocker block rules to prevent asymmetric routing drops inside the tunnel.


### ARM64 Dependency Friction:
If you choose to deploy the OOB Relay on a Raspberry Pi (or similar aarch64 SBC), be aware of significant architectural friction regarding signal-cli.

* The Issue: The native signal-cli binaries rely heavily on the Java Native Interface (JNI) and specific glibc libraries compiled for standard x86_64 architecture. Executing this on an ARM64 system frequently results in fatal libsignal_jni.so missing library errors or JVM crashes.

* The Solution: You must manually compile the libsignal_jni.so library from source for your specific ARM architecture and inject it into the Java library path, or utilize an environment manager like SDKMAN to force a compatible Java runtime environment. Do not expect a simple apt-get install to yield a functional cryptographic relay on micro-architecture.

---

## Development Transparency
This project was developed through a collaborative effort between a human Security Architect and an A.I. LLM (Large Language Model).

* **Human Contribution:** The human architect defined the strategic requirements, designed the "Living off the Land" constraints, architected the pfSense Outbound NAT routing rules, and identified deep OS-level logical flaws (such as the pfBlocker VIP state-table conflict and the Windows NLA firewall race conditions).
* **AI Contribution:** The AI generated the underlying PowerShell and Bash code, engineered the in-memory WPF XAML UI rendering, structured the asynchronous OS state polling logic, and assisted with translating complex WFP firewall concepts into functional PowerShell cmdlets.

---

## License

**MIT License**

Copyright (c) 2026 ButItWorkz

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
