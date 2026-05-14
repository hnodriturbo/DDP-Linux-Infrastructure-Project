# Ultimate Final Project Guide — DDP Linux Infrastructure Project

> Course: KEST3NL05EU — Linux Netstjórnun  
> Project network: **192.168.100.0/24**  
> VMware private network used in this guide: **VMnet6** instead of the PDF's VMnet1  
> NAT network: **VMnet8**  
> Server: **server1.ddp.is**  
> Clients: **client1.ddp.is** Ubuntu/Debian-based, **client2.ddp.is** CentOS/Red-Hat-based  

---

> **Current lab status:** Static networking, persistent journald logging, centralized rsyslog, and DHCP are completed.  
> **Current DHCP result:** `client1.ddp.is` leases `192.168.100.100`; `client2.ddp.is` leases `192.168.100.101`.  
> **Next phase:** BIND9 DNS.

## Clickable Table of Contents

- [0. Exact Project Target](#0-exact-project-target)
- [1. Final Topology](#1-final-topology)
- [2. Evidence and Repository Structure](#2-evidence-and-repository-structure)
- [3. Phase 0 — Clone Ubuntu VM into client1](#3-phase-0--clone-ubuntu-vm-into-client1)
- [4. Phase 1 — VMware Virtual Network Editor: VMnet6](#4-phase-1--vmware-virtual-network-editor-vmnet6)
- [5. Phase 2 — VM Adapter Assignment](#5-phase-2--vm-adapter-assignment)
- [6. Phase 3 — Hostnames and Local Identity](#6-phase-3--hostnames-and-local-identity)
- [7. Phase 4 — Server Networking with Netplan](#7-phase-4--server-networking-with-netplan)
- [8. Phase 5 — Client Networking](#8-phase-5--client-networking)
- [9. Phase 6 — Connectivity Verification](#9-phase-6--connectivity-verification)
- [10. Phase 7 — Persistent Logging](#10-phase-7--persistent-logging)
- [11. Phase 8 — Centralized Syslog](#11-phase-8--centralized-syslog)
- [12. Phase 9 — Internet Sharing / Routing for Clients](#12-phase-9--internet-sharing--routing-for-clients)
- [13. Phase 10 — DHCP on server1](#13-phase-10--dhcp-on-server1)
- [14. Phase 11 — DNS / BIND9](#14-phase-11--dns--bind9)
- [15. Phase 12 — NTP / Time Synchronization](#15-phase-12--ntp--time-synchronization)
- [16. Phase 13 — Users, Groups, and CSV Automation](#16-phase-13--users-groups-and-csv-automation)
- [17. Phase 14 — SSH Key Hardening](#17-phase-14--ssh-key-hardening)
- [18. Phase 15 — Postfix and Roundcube Mail](#18-phase-15--postfix-and-roundcube-mail)
- [19. Phase 16 — CUPS Printing with Group Access](#19-phase-16--cups-printing-with-group-access)
- [20. Phase 17 — Weekly Home Directory Backups](#20-phase-17--weekly-home-directory-backups)
- [21. Phase 18 — Firewall and Nmap Evidence](#21-phase-18--firewall-and-nmap-evidence)
- [22. Final Scripts](#22-final-scripts)
- [23. Final Config Files](#23-final-config-files)
- [24. Screenshot and Command Evidence Plan](#24-screenshot-and-command-evidence-plan)
- [25. Final Validation Walkthrough](#25-final-validation-walkthrough)
- [26. Final GitHub Submission Checklist](#26-final-github-submission-checklist)

---

# 0. Exact Project Target

The final project requires a centralized Linux infrastructure for DDP ehf. supporting:

- IP management with DHCP
- DNS forward and reverse lookup with BIND9
- user and group creation from the provided CSV
- secure SSH access using RSA keys only
- centralized logging
- mail service with Postfix and Roundcube
- CUPS shared printers with group-based access control
- NTP time synchronization
- automated weekly backups
- closed unused ports verified with Nmap

The official project says:

```text
server1.ddp.is = Central Management Server
client1.ddp.is = Debian-based client
client2.ddp.is = Red Hat-based client
domain = ddp.is
server private IP = 192.168.100.10/24
DNS server = 192.168.100.10
```

This guide follows that exactly, except for one deliberate lab change:

```text
Official PDF: Host-only VMnet1
This lab:     Host-only VMnet6
```

Why this is acceptable:

- the subnet remains **192.168.100.0/24**
- the server IP remains **192.168.100.10/24**
- all clients remain only on the private company network
- VMnet6 is only the VMware transport network replacing VMnet1

---

# 1. Final Topology

```text
                         INTERNET
                            │
                      VMware VMnet8 NAT
                            │
                    server1.ddp.is
                    Ubuntu Server VM

                 ens37 = NAT / DHCP from VMware
                 ens33 = VMnet6 / 192.168.100.10/24
                            │
                   VMware VMnet6 Host-only
                   192.168.100.0/24 LAN
                            │
        ┌───────────────────┴───────────────────┐
        │                                       │
 client1.ddp.is                           client2.ddp.is
 Ubuntu clone / Debian-based              CentOS / Red-Hat-based
 VMnet6 only                              VMnet6 only
 DHCP or static reservation               DHCP or static reservation
 target: 192.168.100.20                   target: 192.168.100.30
```

## Final addressing plan

| Machine | Role | OS family | Interface | IP plan |
|---|---|---|---|---|
| server1.ddp.is | Central server | Ubuntu | ens37 NAT | DHCP from VMnet8 |
| server1.ddp.is | Central server | Ubuntu | ens33 private | 192.168.100.10/24 |
| client1.ddp.is | Client | Ubuntu/Debian | private only | DHCP lease, currently 192.168.100.100 |
| client2.ddp.is | Client | CentOS/Red Hat | private only | DHCP lease, currently 192.168.100.101 |

Important:

- `server1` has **two adapters**.
- `client1` and `client2` have **only VMnet6**.
- The clients should not have VMnet8 NAT directly.
- Client internet access, if needed, should go through `server1` as router/gateway.

---

# 2. Evidence and Repository Structure

Create this repository structure early, not at the end.

```bash
mkdir -p ~/DDP-Linux-Infrastructure-Project/{{Documentation/Screenshots,Scripts,Config_Files,Evidence/nmap_scans,Evidence/service_status_screenshots}}
cd ~/DDP-Linux-Infrastructure-Project
```

Why:

- screenshots and command outputs stay organized from the start
- config copies are easier to collect
- the final GitHub submission will already match the required layout

Expected structure:

```text
/DDP-Linux-Infrastructure-Project/
├── README.md
├── Documentation/
│   ├── Project_Report.pdf
│   ├── Screenshots/
│   ├── Network_Diagram.png
│   └── Configuration_Guide.md
├── Scripts/
│   ├── create_users.sh
│   ├── backup_home.sh
│   └── system_hardening.sh
├── Config_Files/
│   ├── dhcpd.conf
│   ├── named.conf
│   ├── named.ddp.is.zone
│   ├── sshd_config
│   ├── rsylog.conf
│   ├── postfix_main.cf
│   └── ntp.conf
├── Evidence/
│   ├── nmap_scans/
│   ├── user_list_verification.png
│   └── service_status_screenshots/
└── LICENSE
```

Screenshots and evidence will be collected continuously throughout the project during each configuration and verification step.

Good evidence commands:

```bash
hostnamectl
ip -br addr
ip route
systemctl status SERVICE_NAME --no-pager
ss -tulnp
```

---

# 3. Phase 0 — Clone Ubuntu VM into client1

## Goal

You currently have one Ubuntu VM that was used as the server in practice. The project needs:

```text
server1.ddp.is = original Ubuntu server VM
client1.ddp.is = cloned Ubuntu client VM
client2.ddp.is = existing CentOS VM
```

## VMware GUI method

1. Shut down the Ubuntu VM completely.
2. In VMware, right-click the Ubuntu VM.
3. Choose **Manage → Clone**.
4. Choose **The current state in the virtual machine**.
5. Choose **Create a full clone**.
6. Name the clone:

```text
client1-ddp-ubuntu
```

7. Finish the clone.

## After cloning

On the cloned VM only:

- remove the NAT adapter
- leave only VMnet6 private adapter
- later set hostname to `client1.ddp.is`

On the original Ubuntu VM:

- keep NAT adapter on VMnet8
- add/keep private adapter on VMnet6
- later set hostname to `server1.ddp.is`

Why full clone is best:

- it gives client1 its own disk
- it avoids dependency on snapshots
- it is easier to prove that there are two separate machines

Evidence to capture:

- VMware VM list showing `server1` and `client1`
- adapter settings for both machines

---

# 4. Phase 1 — VMware Virtual Network Editor: VMnet6

## Goal

Create a clean private company LAN:

```text
VMnet6
Host-only
Subnet: 192.168.100.0
Mask:   255.255.255.0
DHCP:   disabled
```

## GUI method — Virtual Network Editor

Open:

```text
VMware Workstation → Edit → Virtual Network Editor
```

Click:

```text
Change Settings
```

Then either create or edit VMnet6.

## VMnet6 required settings

| Field | Required value |
|---|---|
| Name | VMnet6 |
| Type | Host-only |
| External connection | none |
| Host connection | optional, connected is fine |
| DHCP | disabled |
| Subnet IP | 192.168.100.0 |
| Subnet mask | 255.255.255.0 |

## Checkboxes for VMnet6

Use this:

```text
[ ] Connect a host virtual adapter to this network     Optional
[ ] Use local DHCP service to distribute IP address    OFF
```

Recommended for this project:

```text
Connect host virtual adapter = OFF or ON is acceptable
VMware DHCP = OFF
```

Strong recommendation:

- keep VMware DHCP **off** for VMnet6
- let your Linux `server1` DHCP service control the project network

Why:

- the project explicitly asks DHCP to be installed on `server1`
- VMware DHCP would hide whether your Linux DHCP server works
- only one DHCP server should serve a subnet

## Difference between VMnet6 and VMnet8

VMnet6:

```text
Host-only private LAN
Used by server1, client1, client2
No VMware DHCP
No direct internet
```

VMnet8:

```text
NAT network
Used only by server1
Provides internet access through VMware NAT
Uses VMware DHCP
```

## VMnet8 should stay like this

```text
Type: NAT
DHCP: Enabled
Used by server1 ens33 only
```

Do not attach client1 or client2 to VMnet8.

Evidence:

- screenshot Virtual Network Editor showing VMnet6 = 192.168.100.0/24
- screenshot VMnet8 NAT still enabled

---

# 5. Phase 2 — VM Adapter Assignment

## server1 VM adapters

In VMware settings for original Ubuntu server:

Adapter 1:

```text
Network Adapter
Custom: VMnet8 NAT
Connected: checked
Connect at power on: checked
```

Adapter 2:

```text
Network Adapter 2
Custom: VMnet6 Host-only
Connected: checked
Connect at power on: checked
```

## client1 VM adapters

In VMware settings for Ubuntu clone:

```text
Network Adapter
Custom: VMnet6 Host-only
Connected: checked
Connect at power on: checked
```

Remove or disconnect NAT adapter.

## client2 VM adapters

In VMware settings for CentOS:

```text
Network Adapter
Custom: VMnet6 Host-only
Connected: checked
Connect at power on: checked
```

Remove or disconnect NAT adapter.

## Verify Linux interface names

On each VM:

```bash
ip -br link
ip -br addr
```

Expected idea:

```text
server1: ens37 NAT/WAN + ens33 internal LAN
client1: one main interface
client2: one main interface, often ens160
```

Important:

- your interface names may differ
- do not blindly assume `ens33` and `ens34`
- use `ip -br addr` to confirm

In the current lab state, the private server interface is `ens33` and the NAT/WAN interface is `ens37`.

Evidence:

```bash
ip -br addr
```

Take screenshot on all three machines.

---

# 6. Phase 3 — Hostnames and Local Identity

## server1 hostname

Run on original Ubuntu server:

```bash
sudo hostnamectl set-hostname server1.ddp.is
hostnamectl
```

Expected:

```text
Static hostname: server1.ddp.is
```

## client1 hostname

Run on Ubuntu clone:

```bash
sudo hostnamectl set-hostname client1.ddp.is
hostnamectl
```

## client2 hostname

Run on CentOS:

```bash
sudo hostnamectl set-hostname client2.ddp.is
hostnamectl
```

## Temporary `/etc/hosts` before DNS exists

This is useful before BIND9 is working.

### server1 `/etc/hosts`

Open:

```bash
sudo nano /etc/hosts
```

Use:

```text
# ================================
# Local Host Resolution Configuration
# ================================
# Purpose:
# - Define DDP hostnames before BIND9 is fully active
# - Keep server and client names usable during setup
# - Preserve standard localhost entries
# ================================

127.0.0.1 localhost
127.0.1.1 server1.ddp.is server1

# Local DDP infrastructure hosts
192.168.100.10 server1.ddp.is server1
192.168.100.20 client1.ddp.is client1
192.168.100.30 client2.ddp.is client2

# IPv6 localhost entries
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
```

### client1 `/etc/hosts`

```text
# ================================
# Local Host Resolution Configuration
# ================================
# Purpose:
# - Define DDP hostnames before DNS testing is complete
# - Allow client1 to reach server1 by name during setup
# ================================

127.0.0.1 localhost
127.0.1.1 client1.ddp.is client1

# Local DDP infrastructure hosts
192.168.100.10 server1.ddp.is server1
192.168.100.20 client1.ddp.is client1
192.168.100.30 client2.ddp.is client2

# IPv6 localhost entries
::1     ip6-localhost ip6-loopback
```

### client2 `/etc/hosts`

```text
# ================================
# Local Host Resolution Configuration
# ================================
# Purpose:
# - Define DDP hostnames before DNS testing is complete
# - Allow client2 to reach server1 by name during setup
# ================================

127.0.0.1 localhost localhost.localdomain localhost4 localhost4.localdomain4
127.0.1.1 client2.ddp.is client2

# Local DDP infrastructure hosts
192.168.100.10 server1.ddp.is server1
192.168.100.20 client1.ddp.is client1
192.168.100.30 client2.ddp.is client2

# IPv6 localhost entries
::1 localhost localhost.localdomain localhost6 localhost6.localdomain6
```

Verify:

```bash
hostnamectl
hostname -f
getent hosts server1.ddp.is
getent hosts client1.ddp.is
getent hosts client2.ddp.is
```

Why:

- `/etc/hosts` gives temporary name resolution
- BIND9 later becomes the real DNS source
- hostnames must match project scope exactly

Evidence:

- screenshot `hostnamectl` on all machines
- screenshot `/etc/hosts` on all machines

---

# 7. Phase 4 — Server Networking with Netplan

## Goal

`server1` must have:

```text
NAT interface: `ens37` using DHCP from VMnet8
Private interface: `ens33` using 192.168.100.10/24 on VMnet6
```

## Find interface names

Run:

```bash
ip -br addr
```

Example:

```text
ens37  UP  VMware NAT DHCP address
ens33  UP  192.168.100.10/24
```

This guide now uses the current lab interface mapping: `ens37` for NAT/WAN and `ens33` for the internal LAN.

## Open Netplan

```bash
sudo nano /etc/netplan/00-installer-config.yaml
```

## Recommended server Netplan

```yaml
# ================================
# Netplan Configuration - DDP server1
# ================================
# Purpose:
# - ens37 uses VMware NAT for internet access and package updates
# - ens33 uses VMnet6 as the private DDP company network
# - server1 provides DHCP, DNS, NTP, Syslog, CUPS, SSH, and mail services
# ================================

network:
  version: 2
  renderer: networkd

  ethernets:
    ens37:
      dhcp4: true

    ens33:
      dhcp4: false
      addresses:
        - 192.168.100.10/24
```

Apply:

```bash
sudo chmod 600 /etc/netplan/00-installer-config.yaml
sudo netplan generate
sudo netplan apply
```

Verify:

```bash
ip -br addr
ip route
ping -c 4 8.8.8.8
ping -c 4 google.com
```

Expected:

- NAT interface has a VMware NAT address
- private interface has `192.168.100.10/24`
- internet works from server1

Why no default gateway on ens34:

- ens33 already gets the default route from NAT DHCP
- ens34 is internal only
- two default gateways can create routing confusion

Evidence:

```bash
ip -br addr
ip route
ping -c 4 google.com
```

---

# 8. Phase 5 — Client Networking

You have two possible approaches:

## Best project approach

1. Temporarily give clients static IPs for early testing.
2. Build DHCP on server1.
3. Switch clients to DHCP.
4. Use DHCP reservations if you want stable `.20` and `.30`.

This proves both:

- basic connectivity works before DHCP
- DHCP works after server configuration

---

## client1 Ubuntu temporary static Netplan

Open:

```bash
sudo nano /etc/netplan/00-installer-config.yaml
```

Use this if client1's private interface is `ens33`:

```yaml
# ================================
# Netplan Configuration - DDP client1
# ================================
# Purpose:
# - Configure client1 as the Debian-based DDP client
# - Use VMnet6 private company LAN only
# - Use server1 as gateway and DNS during final project setup
# ================================

network:
  version: 2
  renderer: networkd

  ethernets:
    ens33:
      dhcp4: false
      addresses:
        - 192.168.100.20/24
      routes:
        - to: default
          via: 192.168.100.10
      nameservers:
        addresses:
          - 192.168.100.10
        search:
          - ddp.is
```

Apply:

```bash
sudo chmod 600 /etc/netplan/00-installer-config.yaml
sudo netplan generate
sudo netplan apply
```

Verify:

```bash
ip -br addr
ip route
ping -c 4 192.168.100.10
ping -c 4 server1.ddp.is
```

---

## client2 CentOS temporary static GUI method

Run:

```bash
sudo nmtui
```

Go to:

```text
Edit a connection
```

Set IPv4:

```text
Method: Manual
Address: 192.168.100.30/24
Gateway: 192.168.100.10
DNS servers: 192.168.100.10
Search domains: ddp.is
```

Then:

```text
Activate a connection → deactivate/activate connection
```

Verify:

```bash
ip -br addr
ip route
ping -c 4 192.168.100.10
ping -c 4 server1.ddp.is
```

---

## client2 CentOS CLI method with nmcli

Find connection name:

```bash
nmcli connection show
```

Example connection name:

```text
Wired connection 1
```

Set static IP:

```bash
sudo nmcli connection modify "Wired connection 1" ipv4.method manual ipv4.addresses 192.168.100.30/24 ipv4.gateway 192.168.100.10 ipv4.dns 192.168.100.10 ipv4.dns-search ddp.is
sudo nmcli connection down "Wired connection 1"
sudo nmcli connection up "Wired connection 1"
```

Verify:

```bash
ip -br addr
ip route
cat /etc/resolv.conf
```

Why:

- `nmtui` is easier and safer
- `nmcli` is faster and scriptable
- CentOS uses NetworkManager by default

Evidence:

- screenshot `ip -br addr` on client1 and client2
- screenshot `ip route` on client1 and client2

---


# 9. Phase 6 — Connectivity Verification

## Goal

Before infrastructure services are installed, verify:

- client ↔ server communication
- hostname resolution from `/etc/hosts`
- routing functionality
- internet access from server1
- optional internet access from clients through server1

## Core Verification Commands

Run on all systems:

```bash
hostnamectl
ip -br addr
ip route
ping -c 4 192.168.100.10
```

Additional checks:

```bash
ping -c 4 server1.ddp.is
ping -c 4 client1.ddp.is
ping -c 4 client2.ddp.is
```

Server internet verification:

```bash
ping -c 4 8.8.8.8
ping -c 4 google.com
```

DNS verification before BIND9:

```bash
getent hosts server1.ddp.is
getent hosts client1.ddp.is
getent hosts client2.ddp.is
```

## Expected Results

- all systems reply to ICMP pings
- hostnames resolve correctly
- server1 has internet connectivity
- clients can reach server1
- routes point toward correct interfaces

## Evidence

Take screenshots of:

```bash
hostnamectl
ip -br addr
ip route
ping -c 4 server1.ddp.is
```


# 12. Phase 9 — Internet Sharing / Routing for Clients

The PDF says private gateway may be `192.168.100.1` or none if no external routing is required. In this lab, since clients are only on VMnet6, the clean practical gateway is:

```text
192.168.100.10 = server1
```

That lets clients install packages through server1.

## Enable IPv4 forwarding on server1

Open:

```bash
sudo nano /etc/sysctl.conf
```

Add or uncomment:

```conf
# ================================
# IPv4 Forwarding - DDP server1 Router Function
# ================================
# Purpose:
# - Allow client1 and client2 to reach the internet through server1
# - Forward traffic from VMnet6 private LAN to VMnet8 NAT
# ================================

net.ipv4.ip_forward=1
```

Apply:

```bash
sudo sysctl -p
cat /proc/sys/net/ipv4/ip_forward
```

Expected:

```text
1
```

## Add NAT masquerading on server1

Find NAT interface:

```bash
ip route | grep default
```

In the current lab, the NAT/WAN interface is `ens37`.

Install persistent firewall tools:

```bash
sudo apt update
sudo apt install iptables-persistent -y
```

Add masquerade:

```bash
sudo iptables -t nat -A POSTROUTING -o ens37 -j MASQUERADE
sudo iptables -A FORWARD -i ens33 -o ens37 -j ACCEPT
sudo iptables -A FORWARD -i ens37 -o ens33 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo netfilter-persistent save
```

Verify:

```bash
sudo iptables -t nat -L -n -v
sudo iptables -L FORWARD -n -v
```

## Test from clients

From client1 and client2:

```bash
ping -c 4 192.168.100.10
ping -c 4 8.8.8.8
ping -c 4 google.com
```

Expected:

- ping server works
- ping `8.8.8.8` works if routing works
- ping `google.com` works if DNS works

Troubleshooting order:

1. Can client ping `192.168.100.10`?
2. Does server have internet?
3. Is `net.ipv4.ip_forward=1` active?
4. Is NAT masquerade using correct outbound interface?
5. Does client default route point to `192.168.100.10`?
6. Does client DNS point to `192.168.100.10` or temporary public DNS?

Evidence:

```bash
sudo sysctl -p
sudo iptables -t nat -L -n -v
ping -c 4 8.8.8.8
```

---

# 13. Phase 10 — DHCP on server1

## Goal

server1 automatically assigns:

- IP address
- gateway
- DNS server
- domain name

to client1 and client2 through the private VMnet6 interface.

## Install DHCP server

```bash
sudo apt update
sudo apt install isc-dhcp-server -y
```

## Configure DHCP interface

Open:

```bash
sudo nano /etc/default/isc-dhcp-server
```

Use:

```conf
# ================================
# ISC DHCP Server Interface Selection
# ================================
# Purpose:
# - Bind DHCP service only to the DDP private LAN interface
# - Prevent DHCP service from answering on the NAT interface
# - Keep DHCP controlled by server1, not VMware
# ================================

INTERFACESv4="ens33"
INTERFACESv6=""
```

## Configure DHCP scope

Open:

```bash
sudo nano /etc/dhcp/dhcpd.conf
```

Use:

```conf
# ================================
# DHCP Server Configuration - DDP LAN
# ================================
# Path: /etc/dhcp/dhcpd.conf
# Purpose:
# - Assign IP addresses to DDP clients
# - Provide gateway, DNS, and domain settings
# - Support VMnet6 internal infrastructure
# ================================

# Define the internal DNS domain and the DNS server address given to clients.
option domain-name "ddp.is";
option domain-name-servers 192.168.100.10;

# Define how long DHCP leases remain valid before renewal is required.
default-lease-time 600;
max-lease-time 7200;

# Mark this DHCP server as authoritative for the 192.168.100.0/24 LAN.
authoritative;

# Define the DDP internal LAN subnet and DHCP options.
subnet 192.168.100.0 netmask 255.255.255.0 {

    # Dynamic DHCP pool used by client1 and client2.
    range 192.168.100.100 192.168.100.200;

    # Default gateway handed out to DHCP clients.
    option routers 192.168.100.10;

    # Subnet mask handed out to DHCP clients.
    option subnet-mask 255.255.255.0;

    # Broadcast address for the DDP LAN.
    option broadcast-address 192.168.100.255;
}

# ORIGINAL FILE:

```

Important:

- replace fake MAC addresses with real MAC addresses
- get each client MAC with:

```bash
ip link
```

## Start DHCP

```bash
sudo systemctl enable isc-dhcp-server
sudo systemctl restart isc-dhcp-server
systemctl status isc-dhcp-server --no-pager
```

## Switch clients from static to DHCP

### client1 Ubuntu Netplan DHCP

```yaml
# ================================
# Netplan Configuration - DDP client1 DHCP
# ================================
# Purpose:
# - Receive IP configuration from server1 DHCP
# - Prove DHCP requirement for the final project
# ================================

network:
  version: 2
  renderer: networkd

  ethernets:
    ens33:
      dhcp4: true
```

Apply:

```bash
sudo netplan apply
```

### client2 CentOS DHCP with nmcli

```bash
sudo nmcli connection modify "Wired connection 1" ipv4.method auto ipv4.gateway "" ipv4.addresses "" ipv4.dns "" ipv4.dns-search ""
sudo nmcli connection down "Wired connection 1"
sudo nmcli connection up "Wired connection 1"
```

## Verify DHCP leases

On clients:

```bash
ip -br addr
ip route
cat /etc/resolv.conf
```

On server:

```bash
sudo cat /var/lib/dhcp/dhcpd.leases
journalctl -u isc-dhcp-server --no-pager | tail -n 50
```

Evidence:

- `systemctl status isc-dhcp-server`
- client `ip -br addr` showing DHCP address
- `/var/lib/dhcp/dhcpd.leases`

---

# 14. Phase 11 — DNS / BIND9

## Goal

server1 must provide:

- forward lookup: name → IP
- reverse lookup: IP → name

Examples:

```text
server1.ddp.is → 192.168.100.10
192.168.100.10 → server1.ddp.is
```

## Install BIND9

```bash
sudo apt update
sudo apt install bind9 bind9utils dnsutils -y
```

## Configure local zones

Open:

```bash
sudo nano /etc/bind/named.conf.local
```

Use:

```conf
# ================================
# BIND9 Local Zone Configuration - DDP
# ================================
# Purpose:
# - Define authoritative DNS zones for ddp.is
# - Provide forward and reverse DNS resolution on the private LAN
# ================================

zone "ddp.is" {
    type master;
    file "/etc/bind/db.ddp.is";
};

zone "100.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/db.192.168.100";
};
```

## Configure forward zone

Create:

```bash
sudo nano /etc/bind/db.ddp.is
```

Use:

```dns
; ================================
; BIND9 Forward Zone - ddp.is
; ================================
; Purpose:
; - Resolve DDP hostnames to IPv4 addresses
; - Support DHCP, SSH, mail, CUPS, NTP, and Syslog by hostname
; ================================

$TTL 604800
@   IN  SOA server1.ddp.is. admin.ddp.is. (
        2026050801 ; Serial
        604800     ; Refresh
        86400      ; Retry
        2419200    ; Expire
        604800 )   ; Negative Cache TTL

@       IN  NS      server1.ddp.is.
@       IN  MX 10   mail.ddp.is.

server1 IN  A       192.168.100.10
client1 IN  A       192.168.100.100
client2 IN  A       192.168.100.101
mail    IN  A       192.168.100.10
print   IN  A       192.168.100.10
ntp     IN  A       192.168.100.10
syslog  IN  A       192.168.100.10
```

## Configure reverse zone

Create:

```bash
sudo nano /etc/bind/db.192.168.100
```

Use:

```dns
; ================================
; BIND9 Reverse Zone - 192.168.100.0/24
; ================================
; Purpose:
; - Resolve DDP IPv4 addresses back to hostnames
; - Provide reverse DNS evidence for the final project
; ================================

$TTL 604800
@   IN  SOA server1.ddp.is. admin.ddp.is. (
        2026050801 ; Serial
        604800     ; Refresh
        86400      ; Retry
        2419200    ; Expire
        604800 )   ; Negative Cache TTL

@   IN  NS  server1.ddp.is.

10  IN  PTR server1.ddp.is.
100 IN  PTR client1.ddp.is.
101 IN  PTR client2.ddp.is.
```

## Configure BIND options

Open:

```bash
sudo nano /etc/bind/named.conf.options
```

Use or adapt:

```conf
# ================================
# BIND9 Options - DDP DNS Server
# ================================
# Purpose:
# - Listen on localhost and the private DDP LAN IP
# - Allow DNS queries from the DDP subnet
# - Forward internet DNS queries to public resolvers
# ================================

options {
    directory "/var/cache/bind";

    listen-on { 127.0.0.1; 192.168.100.10; };
    listen-on-v6 { none; };

    allow-query { localhost; 192.168.100.0/24; };
    recursion yes;

    forwarders {
        1.1.1.1;
        8.8.8.8;
    };

    dnssec-validation auto;
};
```

## Validate DNS config

```bash
sudo named-checkconf
sudo named-checkzone ddp.is /etc/bind/db.ddp.is
sudo named-checkzone 100.168.192.in-addr.arpa /etc/bind/db.192.168.100
```

Restart:

```bash
sudo systemctl enable bind9
sudo systemctl restart bind9
systemctl status bind9 --no-pager
```

Test:

```bash
dig @192.168.100.10 server1.ddp.is
dig @192.168.100.10 client1.ddp.is
dig @192.168.100.10 client2.ddp.is
dig @192.168.100.10 -x 192.168.100.10
dig @192.168.100.10 google.com
```

From clients:

```bash
getent hosts server1.ddp.is
ping -c 4 server1.ddp.is
dig server1.ddp.is
```

Evidence:

- `systemctl status bind9`
- `named-checkzone` output
- forward `dig`
- reverse `dig`

---

# 16. Phase 13 — Users, Groups, and CSV Automation

## CSV status

The uploaded CSV contains **29 user rows plus header**. The project text says **30 employees**.

Do not invent a missing user. Document this mismatch in the report unless the teacher gives an updated CSV.

## CSV columns found

```text
Name, FirstName, LastName, Username, Email, Depatment, EmployeeID
```

Note the column is spelled:

```text
Depatment
```

The script must use that exact spelling.

## Departments found

```text
Tolvudeild
Rekstrardeild
Framkvaemdadeild
Framleidsludeild
```

## Users from uploaded CSV

| EmployeeID | Username | Name | Email | Department |
|---|---|---|---|---|
| 1010 | AndFri | Andri Mar Fridriksson | amf@ddp.is | Tolvudeild |
| 1011 | SteGis | Stefan Gislason | stg@ddp.is | Tolvudeild |
| 1012  | SinGud | Sindri Gudmundsson | sig@ddp.is | Tolvudeild |
| 1013 | JonJon | Jon Bjarni Jonsson | jbj@ddp.is | Rekstrardeild |
| 1014 | EliGud | Elin Gudmundsdottir | elg@ddp.is | Rekstrardeild |
| 1015  | GudMag | GudrUn Lilja MagnUsdottir | glm@ddp.is | Rekstrardeild |
| 1016 | JohTor | Johann Hjalti Þorsteinsson | jht@ddp.is | Rekstrardeild |
| 1017 | ValSte | Valdis Steinarrsdottir | vas@ddp.is | Rekstrardeild |
| 1018 | JonHar | Jon Einar Haraldsson | jeh@ddp.is | Framkvaemdadeild |
| 1019 | EirEin | Eirikur Bergmann Einarsson | ebe@ddp.is | Framkvaemdadeild |
| 1020 | KolBjo | KolbrUn Anna Bjornsdottir | kab@ddp.is | Framkvaemdadeild |
| 1021 | GerHaf | Gerda Bjorg Hafsteinsdottir | gbh@ddp.is | Framkvaemdadeild |
| 1022  | AriTei | Ari Teitsson | art@ddp.is | Framkvaemdadeild |
| 1023 | BenSig | Benedikt Þorri Sigurjonsson | bts@ddp.is | Framkvaemdadeild |
| 1024 | OlaHan | olafur Hannibalsson | olh@ddp.is | Framkvaemdadeild |
| 1025 | HelHel | Helgi Helgason | heh@ddp.is | Framkvaemdadeild |
| 1026 | PetGun | Pétur Gunnlaugsson | peg@ddp.is | Framleidsludeild |
| 1027  | FreHar | Freyja Haraldsdottir | frh@ddp.is | Framleidsludeild |
| 1028  | JonVal | Jon Steindor Valdimarsson | jsv@ddp.is | Framleidsludeild |
| 1029 | VilTor | Vilhjalmur Þorsteinsson | vit@ddp.is | Framleidsludeild |
| 1030 | AxeKol | Axel Þor Kolbeinsson | atk@ddp.is | Framleidsludeild |
| 1031  | OrnSig | Orn Sigurdsson | ors@ddp.is | Framleidsludeild |
| 1032  | TorArn | Þorsteinn Arnalds | toa@ddp.is | Framleidsludeild |
| 1033 | RagOma | Ragnar omarsson | rao@ddp.is | Framleidsludeild |
| 1034  | GudPal | Gudmundur Palsson | gup@ddp.is | Framleidsludeild |
| 1035  | OskSig | Oskar Isfeld Sigurdsson | ois@ddp.is | Framleidsludeild |
| 1036 | TorGud | Þorunn Gudmundsdottir | tog@ddp.is | Framleidsludeild |
| 1037 | ArnGud | arni BjOrn Gudjonsson | abg@ddp.is | Framleidsludeild |
| 1038 | JonRag | Jon Palmar Ragnarsson | jpr@ddp.is | Framleidsludeild |

## Prepare project script folder

```bash
sudo mkdir -p /opt/ddp/scripts
sudo cp ~/DDP-Linux-Infrastructure-Project/Scripts/create_users.sh /opt/ddp/scripts/create_users.sh
sudo cp ~/DDP-Linux-Infrastructure-Project/Scripts/backup_home.sh /opt/ddp/scripts/backup_home.sh
sudo chmod +x /opt/ddp/scripts/*.sh
```

Copy CSV next to script:

```bash
sudo cp ~/DDP-Linux-Infrastructure-Project/Scripts/Linux_Users.CSV /opt/ddp/scripts/Linux_Users.CSV
```

If the CSV is in Downloads:

```bash
sudo cp ~/Downloads/Linux_Users.CSV /opt/ddp/scripts/Linux_Users.CSV
```

## Run user creation

```bash
sudo /opt/ddp/scripts/create_users.sh
```

## Verify users

```bash
getent passwd | grep -E 'AndFri|SigSig|JonRag'
getent group Tolvudeild
getent group Rekstrardeild
getent group Framkvaemdadeild
getent group Framleidsludeild
ls -ld /home/AndFri
```

Save evidence:

```bash
getent passwd | grep -E '/home/' | tee ~/DDP-Linux-Infrastructure-Project/Evidence/user_list_verification.txt
getent group Tolvudeild Rekstrardeild Framkvaemdadeild Framleidsludeild | tee -a ~/DDP-Linux-Infrastructure-Project/Evidence/user_list_verification.txt
```

Evidence screenshot:

- terminal showing created users
- terminal showing department groups
- maybe `/home` directory listing

Why this matters:

- NetAcad Chapter 6 user/group concepts are directly used here
- `useradd -m` creates home directories
- `usermod -aG` adds supplementary groups safely
- `getent` verifies from system databases

---

# 20. Phase 17 — Weekly Home Directory Backups

## Goal

Back up all home directories every Friday at midnight.

## Create backup script

Use the script in [Final Scripts](#20-final-scripts), then install it:

```bash
sudo mkdir -p /opt/ddp/scripts
sudo cp ~/DDP-Linux-Infrastructure-Project/Scripts/backup_home.sh /opt/ddp/scripts/backup_home.sh
sudo chmod +x /opt/ddp/scripts/backup_home.sh
```

## Test manually first

```bash
sudo /opt/ddp/scripts/backup_home.sh
ls -lh /backup/ddp-home
```

## Schedule with root cron

Open:

```bash
sudo crontab -e
```

Add:

```cron
# Run DDP home directory backup every Friday at midnight
0 0 * * 5 /opt/ddp/scripts/backup_home.sh >> /var/log/ddp_backup.log 2>&1
```

## Verify cron entry

```bash
sudo crontab -l
```

## Cron field explanation

```text
0 0 * * 5
│ │ │ │ └── Friday
│ │ │ └──── every month
│ │ └────── every day of month
│ └──────── hour 00
└────────── minute 00
```

Evidence:

```bash
sudo /opt/ddp/scripts/backup_home.sh
ls -lh /backup/ddp-home
sudo crontab -l
cat /var/log/ddp_backup.log
```

Take screenshots of:

- manual backup execution
- created `.tar.gz` file
- cron schedule

---

# 15. Phase 12 — NTP / Time Synchronization

The project says NTP. Modern Ubuntu often uses Chrony. To match the project wording and file name `ntp.conf`, this guide uses classic `ntp` where available. If Ubuntu package availability is difficult, use Chrony but save config as `ntp.conf` copy for documentation.

## Option A — Use chrony, recommended practical path

### server1 install

```bash
sudo apt update
sudo apt install chrony -y
```

Open:

```bash
sudo nano /etc/chrony/chrony.conf
```

Add:

```conf
# ================================
# Chrony Time Server - DDP server1
# ================================
# Purpose:
# - Synchronize server1 with public NTP sources
# - Allow DDP clients to synchronize time from server1
# ================================

pool pool.ntp.org iburst
allow 192.168.100.0/24
local stratum 10
```

Restart:

```bash
sudo systemctl enable chrony
sudo systemctl restart chrony
systemctl status chrony --no-pager
chronyc tracking
chronyc sources
```

### client1 Ubuntu chrony config

```bash
sudo apt install chrony -y
sudo nano /etc/chrony/chrony.conf
```

Add near top:

```conf
# Use DDP server1 as the local time source
server 192.168.100.10 iburst
```

Restart:

```bash
sudo systemctl restart chrony
chronyc sources
```

### client2 CentOS chrony config

```bash
sudo dnf install chrony -y
sudo nano /etc/chrony.conf
```

Add:

```conf
# Use DDP server1 as the local time source
server 192.168.100.10 iburst
```

Restart:

```bash
sudo systemctl enable chronyd
sudo systemctl restart chronyd
systemctl status chronyd --no-pager
chronyc sources
```

## Save required documentation copy

```bash
sudo cp /etc/chrony/chrony.conf ~/DDP-Linux-Infrastructure-Project/Config_Files/ntp.conf
```

On CentOS if needed:

```bash
sudo cp /etc/chrony.conf ~/chrony-client2.conf
```

Evidence:

```bash
systemctl status chrony --no-pager
chronyc tracking
chronyc sources
```

Why time matters:

- log timestamps need to match
- backups prove correct schedule
- SSH and security auditing depend on reliable time

---


# 10. Phase 7 — Persistent Logging

## Goal

Enable persistent journal logging before major infrastructure services are installed.

This is important because:

- troubleshooting evidence begins early
- service failures are preserved after reboot
- screenshots and logs remain available during the full project lifecycle
- centralized Syslog later becomes easier to validate

## Verify current journal storage

```bash
journalctl --disk-usage
ls -ld /var/log/journal
```

## Create persistent journal directory

```bash
sudo mkdir -p /var/log/journal
sudo systemd-tmpfiles --create --prefix /var/log/journal
```

## Configure journald persistence

Open:

```bash
sudo nano /etc/systemd/journald.conf
```

Set:

```conf
# ================================
# systemd-journald Persistent Logging
# ================================
# Purpose:
# - Keep logs after reboot
# - Preserve troubleshooting evidence
# - Support centralized logging validation later in the project
# ================================

Storage=persistent
Compress=yes
SystemMaxUse=500M
```

Restart journald:

```bash
sudo systemctl restart systemd-journald
```

## Verify persistence

```bash
journalctl -b
journalctl --list-boots
journalctl -xe
```

Reboot server1 and confirm logs still exist:

```bash
sudo reboot
journalctl -b -1
```

## Evidence

Capture screenshots of:

```bash
journalctl --disk-usage
journalctl --list-boots
systemctl status systemd-journald --no-pager
```


# 11. Phase 8 — Centralized Syslog

## Goal

server1 receives logs from client1 and client2.

Syslog uses port:

```text
UDP 514 and/or TCP 514
```

## server1 rsyslog receiver

Install:

```bash
sudo apt update
sudo apt install rsyslog -y
```

Open:

```bash
sudo nano /etc/rsyslog.d/10-ddp-server.conf
```

Use:

```conf
# ================================
# Rsyslog Server Configuration - DDP server1
# ================================
# Purpose:
# - Receive centralized logs from DDP Linux clients
# - Store client logs separately by hostname
# - Support proactive monitoring evidence for final project
# ================================

module(load="imudp")
input(type="imudp" port="514")

module(load="imtcp")
input(type="imtcp" port="514")

$template RemoteLogs,"/var/log/remote/%HOSTNAME%/%PROGRAMNAME%.log"
*.* ?RemoteLogs
& stop
```

Create folder:

```bash
sudo mkdir -p /var/log/remote
sudo chown syslog:adm /var/log/remote
```

Restart:

```bash
sudo systemctl enable rsyslog
sudo systemctl restart rsyslog
systemctl status rsyslog --no-pager
sudo ss -tulnp | grep ':514'
```

## client1 rsyslog forwarder

Open:

```bash
sudo nano /etc/rsyslog.d/10-ddp-client.conf
```

Use:

```conf
# ================================
# Rsyslog Client Forwarding - DDP client1
# ================================
# Purpose:
# - Forward client1 logs to server1.ddp.is
# - Support centralized monitoring requirement
# ================================

*.* @@192.168.100.10:514
```

Restart:

```bash
sudo systemctl restart rsyslog
logger -p user.info "DDP syslog test from client1"
```

## client2 rsyslog forwarder

CentOS:

```bash
sudo nano /etc/rsyslog.d/10-ddp-client.conf
```

Use:

```conf
# ================================
# Rsyslog Client Forwarding - DDP client2
# ================================
# Purpose:
# - Forward client2 logs to server1.ddp.is
# - Support centralized monitoring requirement
# ================================

*.* @@192.168.100.10:514
```

Restart:

```bash
sudo systemctl restart rsyslog
logger -p user.info "DDP syslog test from client2"
```

## Verify on server1

```bash
sudo find /var/log/remote -type f | sort
sudo grep -R "DDP syslog test" /var/log/remote
```

Evidence:

- `systemctl status rsyslog`
- `ss -tulnp | grep ':514'`
- `grep -R "DDP syslog test" /var/log/remote`

---

# 18. Phase 15 — Postfix and Roundcube Mail

## Goal

Install and configure Postfix on server1 integrated with Roundcube webmail for sending and receiving emails.

This can be heavy. Do this after networking, DNS, users, and time are stable.

## Install packages

```bash
sudo apt update
sudo apt install postfix dovecot-imapd dovecot-pop3d mailutils roundcube roundcube-core roundcube-mysql apache2 php php-mysql -y
```

During Postfix setup choose:

```text
Internet Site
System mail name: ddp.is
```

## Postfix main config

Open:

```bash
sudo nano /etc/postfix/main.cf
```

Key settings:

```conf
# ================================
# Postfix Main Configuration - DDP Mail Server
# ================================
# Purpose:
# - Provide local mail service for ddp.is
# - Listen on server1 private LAN
# - Support Roundcube webmail access for project evidence
# ================================

myhostname = mail.ddp.is
mydomain = ddp.is
myorigin = /etc/mailname
inet_interfaces = all
inet_protocols = ipv4
mydestination = $myhostname, server1.ddp.is, localhost.ddp.is, localhost, ddp.is
mynetworks = 127.0.0.0/8 192.168.100.0/24
home_mailbox = Maildir/
smtpd_banner = $myhostname ESMTP DDP Mail Server
```

Set mailname:

```bash
echo "ddp.is" | sudo tee /etc/mailname
```

Restart:

```bash
sudo systemctl restart postfix
sudo systemctl status postfix --no-pager
```

## Dovecot Maildir support

Open:

```bash
sudo nano /etc/dovecot/conf.d/10-mail.conf
```

Set:

```conf
# Store user mail in Maildir format under each home directory
mail_location = maildir:~/Maildir
```

Restart:

```bash
sudo systemctl restart dovecot
sudo systemctl status dovecot --no-pager
```

## Test mail locally

```bash
echo "DDP local mail test" | mail -s "DDP Test" AndFri
sudo ls -la /home/AndFri/Maildir/new
```

Check queue:

```bash
mailq
```

Check listening ports:

```bash
sudo ss -tulnp | grep -E ':25|:143|:80'
```

## Roundcube quick verification

Check Apache:

```bash
sudo systemctl status apache2 --no-pager
```

Try from client browser:

```text
http://server1.ddp.is/roundcube
```

If path differs, try:

```text
http://192.168.100.10/roundcube
```

Evidence:

- `systemctl status postfix`
- `systemctl status dovecot`
- `systemctl status apache2`
- `mailq`
- Roundcube login page screenshot
- successful local mail evidence

---

# 19. Phase 16 — CUPS Printing with Group Access

## Goal

Install and configure shared printers using CUPS with group access:

- users in each department print to their department printer
- IT and Management groups have print/manage rights

Because this is a VM lab, virtual PDF/file printers are acceptable if real printers are unavailable.

## Install CUPS

```bash
sudo apt update
sudo apt install cups cups-pdf -y
```

Enable:

```bash
sudo systemctl enable cups
sudo systemctl restart cups
systemctl status cups --no-pager
```

Allow web admin on LAN:

```bash
sudo cupsctl --remote-admin --remote-any --share-printers
```

## Add management-style groups

Based on CSV departments, `Tolvudeild` is likely IT. For management, `Framkvaemdadeild` likely represents management/executive department.

Create helper groups:

```bash
sudo groupadd -f DDP-Print-Admins
sudo groupadd -f DDP-Print-Managers
sudo usermod -aG DDP-Print-Admins AndFri
```

If teacher expects exact department groups only, document:

```text
Tolvudeild = IT group
Framkvaemdadeild = Management group
```

## Create class/queue placeholders

List printers:

```bash
lpstat -p
lpstat -v
```

If CUPS-PDF provides a printer, use it for evidence.

Example commands:

```bash
sudo lpadmin -p Tolvudeild_Printer -E -v cups-pdf:/ -m everywhere || true
sudo lpadmin -p Rekstrardeild_Printer -E -v cups-pdf:/ -m everywhere || true
sudo lpadmin -p Framkvaemdadeild_Printer -E -v cups-pdf:/ -m everywhere || true
sudo lpadmin -p Framleidsludeild_Printer -E -v cups-pdf:/ -m everywhere || true
```

If `-m everywhere` fails for local PDF queues, use the CUPS web GUI instead:

```text
http://server1.ddp.is:631
```

## CUPS GUI method

From server or client browser:

```text
http://localhost:631
http://server1.ddp.is:631
```

Go to:

```text
Administration → Add Printer
```

Then create one printer per department.

## Restrict printer access

CUPS access control is distro/version dependent. Check supported options:

```bash
lpoptions -p Tolvudeild_Printer -l
```

Common admin checks:

```bash
lpstat -p
lpstat -a
lpstat -v
```

Print test:

```bash
echo "DDP printer test" | lp -d Tolvudeild_Printer
lpq -P Tolvudeild_Printer
```

Evidence:

- `systemctl status cups`
- `lpstat -p`
- CUPS web page screenshot
- test print command
- group membership evidence

Important documentation note:

If exact group ACLs are difficult in the lab, document the intended group policy clearly and show as much technical implementation as possible. Ask teacher if simulated printers are acceptable.

---

# 17. Phase 14 — SSH Key Hardening

## Goal

Harden SSH on all systems:

```text
Disable password authentication
Enforce RSA key-based authentication only
```

Do not disable password authentication until key login works.

## On client1, create RSA key

```bash
ssh-keygen -t rsa -b 4096 -C "client1-ddp-admin"
```

Press Enter for default path.

Copy key to server1:

```bash
ssh-copy-id USERNAME@server1.ddp.is
```

Test:

```bash
ssh USERNAME@server1.ddp.is
```

## On client2, create RSA key

```bash
ssh-keygen -t rsa -b 4096 -C "client2-ddp-admin"
ssh-copy-id USERNAME@server1.ddp.is
ssh USERNAME@server1.ddp.is
```

## Harden server1 sshd_config

Open:

```bash
sudo nano /etc/ssh/sshd_config
```

Use or ensure:

```conf
# ================================
# SSH Server Hardening Configuration - DDP
# ================================
# Purpose:
# - Disable root SSH login
# - Disable password-based SSH login
# - Enforce public key authentication for secure remote access
# ================================

PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
UsePAM yes
```

Validate before restart:

```bash
sudo sshd -t
```

Restart:

```bash
sudo systemctl restart ssh
systemctl status ssh --no-pager
```

## Harden CentOS SSH service name

On CentOS the service is usually:

```bash
sudo systemctl restart sshd
systemctl status sshd --no-pager
```

## Evidence

From client:

```bash
ssh -i ~/.ssh/id_rsa USERNAME@server1.ddp.is
```

On server:

```bash
sudo grep -E '^(PermitRootLogin|PubkeyAuthentication|PasswordAuthentication|KbdInteractiveAuthentication|ChallengeResponseAuthentication)' /etc/ssh/sshd_config
systemctl status ssh --no-pager
```

Nmap should show SSH open only if firewall allows it:

```bash
nmap -sV -p 22 192.168.100.10
```

---

# 21. Phase 18 — Firewall and Nmap Evidence

## Goal

Close unused ports and verify with Nmap.

## Expected server ports

Server1 may need these:

| Service | Port | Protocol |
|---|---:|---|
| SSH | 22 | TCP |
| DNS | 53 | TCP/UDP |
| DHCP | 67 | UDP |
| HTTP/Roundcube | 80 | TCP |
| SMTP/Postfix | 25 | TCP |
| IMAP/Dovecot | 143 | TCP |
| Syslog | 514 | TCP/UDP |
| CUPS | 631 | TCP |
| NTP/Chrony | 123 | UDP |

Clients should have very few open ports. Usually SSH only, or none if not needed.

## Server firewall with UFW

Install:

```bash
sudo apt install ufw -y
```

Configure:

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from 192.168.100.0/24 to any port 22 proto tcp
sudo ufw allow from 192.168.100.0/24 to any port 53
sudo ufw allow from 192.168.100.0/24 to any port 67 proto udp
sudo ufw allow from 192.168.100.0/24 to any port 80 proto tcp
sudo ufw allow from 192.168.100.0/24 to any port 25 proto tcp
sudo ufw allow from 192.168.100.0/24 to any port 143 proto tcp
sudo ufw allow from 192.168.100.0/24 to any port 514
sudo ufw allow from 192.168.100.0/24 to any port 631 proto tcp
sudo ufw allow from 192.168.100.0/24 to any port 123 proto udp
sudo ufw --force enable
sudo ufw status verbose
```

Important:

- do not enable firewall until SSH key login works
- do not block DHCP/DNS before clients are tested

## CentOS firewall with firewalld

Check:

```bash
sudo firewall-cmd --state
sudo firewall-cmd --list-all
```

Allow SSH only if needed:

```bash
sudo firewall-cmd --add-service=ssh --permanent
sudo firewall-cmd --reload
sudo firewall-cmd --list-all
```

## Nmap from client1

Install:

```bash
sudo apt install nmap -y
```

Run:

```bash
mkdir -p ~/DDP-Linux-Infrastructure-Project/Evidence/nmap_scans
nmap -sV 192.168.100.10 | tee ~/DDP-Linux-Infrastructure-Project/Evidence/nmap_scans/server1-basic-scan.txt
nmap -sU --top-ports 20 192.168.100.10 | tee ~/DDP-Linux-Infrastructure-Project/Evidence/nmap_scans/server1-udp-top20-scan.txt
nmap -sV 192.168.100.100 | tee ~/DDP-Linux-Infrastructure-Project/Evidence/nmap_scans/client1-basic-scan.txt
nmap -sV 192.168.100.101 | tee ~/DDP-Linux-Infrastructure-Project/Evidence/nmap_scans/client2-basic-scan.txt
```

Run a later final scan after all firewall rules are complete:

```bash
nmap -sV -O 192.168.100.10 | tee ~/DDP-Linux-Infrastructure-Project/Evidence/nmap_scans/server1-final-scan.txt
```

Evidence:

- `ufw status verbose`
- `firewall-cmd --list-all`
- all Nmap scan text files
- screenshots of scans if required

---

# 22. Final Scripts

## `Scripts/create_users.sh`

```bash
#!/bin/bash

# ================================
# create_users.sh - DDP User Creation Script
# ================================
# Purpose:
# - Create DDP Linux users from Linux_Users.CSV
# - Create department groups from the CSV automatically
# - Add users to their department groups safely
# - Create home directories and store full names in the comment field
# - Generate evidence logs for final project documentation
#
# Parameters / Inputs:
# - Run as root or with sudo
# - Linux_Users.CSV must be in the same directory as this script
# - Expected CSV columns: Name, FirstName, LastName, Username, Email, Depatment, EmployeeID
# ================================

set -euo pipefail

script_directory="$(cd "$(dirname "${{BASH_SOURCE[0]}}")" && pwd)"
csv_file="$script_directory/Linux_Users.CSV"
log_file="$script_directory/create_users.log"
default_password="ChangeMe123!"

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Run this script as root or with sudo."
    exit 1
fi

if [[ ! -f "$csv_file" ]]; then
    echo "ERROR: Missing CSV file: $csv_file"
    exit 1
fi

: > "$log_file"

echo "DDP user creation started: $(date)" | tee -a "$log_file"

# Convert UTF-16 CSV to UTF-8 safely if needed.
temporary_csv="$(mktemp)"
if file "$csv_file" | grep -qi "utf-16"; then
    iconv -f UTF-16 -t UTF-8 "$csv_file" > "$temporary_csv"
else
    cp "$csv_file" "$temporary_csv"
fi

# Read CSV and skip header.
tail -n +2 "$temporary_csv" | while IFS=',' read -r full_name first_name last_name username email department employee_id
 do
    username="$(echo "${{username:-}}" | xargs)"
    full_name="$(echo "${{full_name:-}}" | xargs)"
    email="$(echo "${{email:-}}" | xargs)"
    department="$(echo "${{department:-}}" | xargs)"
    employee_id="$(echo "${{employee_id:-}}" | xargs)"

    if [[ -z "$username" || -z "$department" ]]; then
        echo "Skipping invalid CSV row: $full_name,$username,$department" | tee -a "$log_file"
        continue
    fi

    if ! getent group "$department" > /dev/null; then
        groupadd "$department"
        echo "Created group: $department" | tee -a "$log_file"
    fi

    if ! id "$username" > /dev/null 2>&1; then
        useradd -m -c "$full_name, $email, EmployeeID $employee_id" -s /bin/bash "$username"
        echo "$username:$default_password" | chpasswd
        passwd -e "$username" > /dev/null 2>&1 || true
        echo "Created user: $username ($full_name)" | tee -a "$log_file"
    else
        echo "User already exists: $username" | tee -a "$log_file"
    fi

    usermod -aG "$department" "$username"
    echo "Added $username to group $department" | tee -a "$log_file"
 done

rm -f "$temporary_csv"

echo "" | tee -a "$log_file"
echo "Department group verification:" | tee -a "$log_file"
getent group Tolvudeild Rekstrardeild Framkvaemdadeild Framleidsludeild | tee -a "$log_file"

echo "" | tee -a "$log_file"
echo "Home directory verification:" | tee -a "$log_file"
ls -ld /home/* 2>/dev/null | tee -a "$log_file"

echo "DDP user creation completed: $(date)" | tee -a "$log_file"
```

## `Scripts/backup_home.sh`

```bash
#!/bin/bash

# ================================
# backup_home.sh - DDP Home Directory Backup Script
# ================================
# Purpose:
# - Back up all user home directories from /home
# - Create timestamped compressed archive files
# - Support the Friday midnight automated backup requirement
# - Produce clear terminal/log evidence for final documentation
#
# Parameters / Inputs:
# - Run as root or through root cron
# - Backup source: /home
# - Backup destination: /backup/ddp-home
# ================================

set -euo pipefail

backup_root="/backup/ddp-home"
timestamp="$(date +%Y-%m-%d_%H-%M-%S)"
backup_file="$backup_root/home-backup-$timestamp.tar.gz"

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Run this script as root or with sudo."
    exit 1
fi

mkdir -p "$backup_root"
chown root:root "$backup_root"
chmod 700 "$backup_root"

tar -czf "$backup_file" /home

ls -lh "$backup_file"
echo "Backup completed: $backup_file"
```

## `Scripts/system_hardening.sh`

```bash
#!/bin/bash

# ================================
# system_hardening.sh - DDP Baseline Hardening Script
# ================================
# Purpose:
# - Apply SSH hardening settings
# - Disable root SSH login
# - Disable SSH password authentication
# - Keep public key authentication enabled
# - Show firewall and service status evidence
#
# Parameters / Inputs:
# - Run as root or with sudo
# - Confirm SSH key login works before using this script remotely
# ================================

set -euo pipefail

sshd_config="/etc/ssh/sshd_config"
backup_file="$sshd_config.backup.$(date +%Y%m%d-%H%M%S)"

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Run this script as root or with sudo."
    exit 1
fi

cp "$sshd_config" "$backup_file"

declare -A ssh_settings=(
    [PermitRootLogin]="no"
    [PubkeyAuthentication]="yes"
    [PasswordAuthentication]="no"
    [KbdInteractiveAuthentication]="no"
    [ChallengeResponseAuthentication]="no"
)

for setting_name in "${{!ssh_settings[@]}}"; do
    setting_value="${{ssh_settings[$setting_name]}}"

    if grep -qE "^#?$setting_name" "$sshd_config"; then
        sed -i "s/^#\?$setting_name.*/$setting_name $setting_value/" "$sshd_config"
    else
        echo "$setting_name $setting_value" >> "$sshd_config"
    fi
 done

sshd -t

if systemctl list-unit-files | grep -q '^ssh.service'; then
    systemctl restart ssh
    systemctl status ssh --no-pager
elif systemctl list-unit-files | grep -q '^sshd.service'; then
    systemctl restart sshd
    systemctl status sshd --no-pager
fi

if command -v ufw > /dev/null 2>&1; then
    ufw status verbose || true
fi

if command -v firewall-cmd > /dev/null 2>&1; then
    firewall-cmd --list-all || true
fi

echo "SSH hardening completed. Backup created at: $backup_file"
```

---

# 23. Final Config Files

Copy final active config files into `Config_Files` after each service works.

## Copy commands

```bash
sudo cp /etc/dhcp/dhcpd.conf ~/DDP-Linux-Infrastructure-Project/Config_Files/dhcpd.conf
sudo cp /etc/bind/named.conf.local ~/DDP-Linux-Infrastructure-Project/Config_Files/named.conf
sudo cp /etc/bind/db.ddp.is ~/DDP-Linux-Infrastructure-Project/Config_Files/named.ddp.is.zone
sudo cp /etc/ssh/sshd_config ~/DDP-Linux-Infrastructure-Project/Config_Files/sshd_config
sudo cp /etc/rsyslog.conf ~/DDP-Linux-Infrastructure-Project/Config_Files/rsylog.conf
sudo cp /etc/postfix/main.cf ~/DDP-Linux-Infrastructure-Project/Config_Files/postfix_main.cf
sudo cp /etc/chrony/chrony.conf ~/DDP-Linux-Infrastructure-Project/Config_Files/ntp.conf
```

Note:

- the project folder says `rsylog.conf`, likely typo
- keep that filename because the required structure shows it
- inside the report you can write that it is the copied rsyslog configuration

---

# 24. Screenshot and Command Evidence Plan

## Network evidence

```bash
hostnamectl
ip -br addr
ip route
ping -c 4 192.168.100.10
ping -c 4 server1.ddp.is
```

Take on:

- server1
- client1
- client2

## DHCP evidence

```bash
systemctl status isc-dhcp-server --no-pager
sudo cat /var/lib/dhcp/dhcpd.leases
ip -br addr
cat /etc/resolv.conf
```

## DNS evidence

```bash
systemctl status bind9 --no-pager
sudo named-checkconf
sudo named-checkzone ddp.is /etc/bind/db.ddp.is
sudo named-checkzone 100.168.192.in-addr.arpa /etc/bind/db.192.168.100
dig @192.168.100.10 server1.ddp.is
dig @192.168.100.10 -x 192.168.100.10
```

## User evidence

```bash
sudo /opt/ddp/scripts/create_users.sh
getent group Tolvudeild Rekstrardeild Framkvaemdadeild Framleidsludeild
getent passwd | grep -E 'AndFri|JonRag'
ls -ld /home/AndFri
```

## Backup evidence

```bash
sudo /opt/ddp/scripts/backup_home.sh
ls -lh /backup/ddp-home
sudo crontab -l
```

## NTP evidence

```bash
systemctl status chrony --no-pager
chronyc tracking
chronyc sources
```

## Syslog evidence

```bash
systemctl status rsyslog --no-pager
sudo ss -tulnp | grep ':514'
logger -p user.info "DDP local syslog evidence"
sudo grep -R "DDP" /var/log/remote
```

## Mail evidence

```bash
systemctl status postfix --no-pager
systemctl status dovecot --no-pager
systemctl status apache2 --no-pager
mailq
sudo ss -tulnp | grep -E ':25|:143|:80'
```

## CUPS evidence

```bash
systemctl status cups --no-pager
lpstat -p
lpstat -a
sudo ss -tulnp | grep ':631'
```

## SSH evidence

```bash
ssh-keygen -t rsa -b 4096 -C "ddp-evidence-key"
ssh USERNAME@server1.ddp.is
sudo grep -E '^(PermitRootLogin|PubkeyAuthentication|PasswordAuthentication)' /etc/ssh/sshd_config
```

## Firewall/Nmap evidence

```bash
sudo ufw status verbose
nmap -sV 192.168.100.10
nmap -sV 192.168.100.100
nmap -sV 192.168.100.101
```

---

# 25. Final Validation Walkthrough

Run this when you believe the project is finished.

## server1

```bash
hostnamectl
ip -br addr
ip route
systemctl status isc-dhcp-server --no-pager
systemctl status bind9 --no-pager
systemctl status chrony --no-pager
systemctl status rsyslog --no-pager
systemctl status postfix --no-pager
systemctl status dovecot --no-pager
systemctl status cups --no-pager
systemctl status ssh --no-pager
sudo ufw status verbose
```

## client1

```bash
hostnamectl
ip -br addr
ip route
cat /etc/resolv.conf
ping -c 4 server1.ddp.is
dig server1.ddp.is
chronyc sources
logger -p user.info "Final syslog test from client1"
ssh USERNAME@server1.ddp.is
```

## client2

```bash
hostnamectl
ip -br addr
ip route
cat /etc/resolv.conf
ping -c 4 server1.ddp.is
dig server1.ddp.is
chronyc sources
logger -p user.info "Final syslog test from client2"
ssh USERNAME@server1.ddp.is
```

## server1 final syslog check

```bash
sudo grep -R "Final syslog test" /var/log/remote
```

## final Nmap scans

From client1:

```bash
nmap -sV 192.168.100.10 | tee ~/DDP-Linux-Infrastructure-Project/Evidence/nmap_scans/server1-final-basic.txt
nmap -sV 192.168.100.100 | tee ~/DDP-Linux-Infrastructure-Project/Evidence/nmap_scans/client1-final-basic.txt
nmap -sV 192.168.100.101 | tee ~/DDP-Linux-Infrastructure-Project/Evidence/nmap_scans/client2-final-basic.txt
```

---

# 26. Final GitHub Submission Checklist

Before upload:

```bash
cd ~/DDP-Linux-Infrastructure-Project
find . -maxdepth 3 -type f | sort
```

Check that you have:

- README.md
- Documentation/Project_Report.pdf
- Documentation/Network_Diagram.png
- Documentation/Configuration_Guide.md
- Scripts/create_users.sh
- Scripts/backup_home.sh
- Scripts/system_hardening.sh
- Config_Files/dhcpd.conf
- Config_Files/named.conf
- Config_Files/named.ddp.is.zone
- Config_Files/sshd_config
- Config_Files/rsylog.conf
- Config_Files/postfix_main.cf
- Config_Files/ntp.conf
- Evidence/nmap_scans files
- Evidence/user_list_verification evidence
- Evidence/service_status_screenshots screenshots
- LICENSE

## Recommended Git commands

```bash
git init
git branch -M master
git add .
git commit -m "Initial DDP Linux infrastructure final project submission"
git status
```

Why `master`:

- this matches your preferred default branch name
- it is fine unless the teacher requires another branch name

## Final report notes to include

Mention clearly:

```text
VMnet6 was used as the private host-only VMware network instead of VMnet1.
The IP subnet remained the required 192.168.100.0/24.
server1 used 192.168.100.10/24 as required.
client1 and client2 received dynamic DHCP leases from server1: 192.168.100.100 and 192.168.100.101.
client1 was Debian-based Ubuntu.
client2 was Red-Hat-based CentOS.
The uploaded Users CSV contained 29 user entries, although the assignment text says 30 employees.
```

---

# End State

When finished, you should be able to demonstrate:

```text
client1/client2 receive network config from server1 DHCP
client1/client2 resolve ddp.is hostnames using server1 DNS
users and department groups exist from CSV automation
home directories are backed up by script and cron schedule
clients synchronize time from server1
client logs arrive on server1
mail services are installed and testable
CUPS is installed and department printer policy is documented
SSH uses RSA key login and password login is disabled
firewall is active and Nmap proves exposed ports
repository structure matches the required final submission
```
