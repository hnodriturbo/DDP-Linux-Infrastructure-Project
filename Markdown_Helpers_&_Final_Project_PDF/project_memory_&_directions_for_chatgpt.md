# Project Memory & Directions for ChatGPT — DDP Linux Infrastructure Project

> Use this file as the project-source memory file for a new ChatGPT project dedicated only to the final project.

---

# 1. Project Identity

Project name:

```text
DDP-Linux-Infrastructure-Project
```

Course:

```text
KEST3NL05EU — Linux Netstjórnun
```

Company/domain:

```text
DDP ehf.
ddp.is
```

Main goal:
- Build a centralized Linux infrastructure using one Ubuntu server and two Linux clients.

---

# 2. Official Requirement Summary

Official services required:
- DHCP server
- DNS/BIND9 server
- NTP time synchronization
- Centralized Syslog
- Postfix mail server
- Roundcube webmail
- CUPS printer sharing
- SSH hardening with RSA key authentication only
- Weekly backup automation
- Firewall hardening
- Nmap verification scans
- User/group automation from provided CSV

Official machines:

| Host | Role | OS family |
|---|---|---|
| server1.ddp.is | Central Management Server | Ubuntu Server |
| client1.ddp.is | Client | Debian-based / Ubuntu |
| client2.ddp.is | Client | Red Hat-based / CentOS |

Official network:

```text
192.168.100.0/24
```

Official static server IP:

```text
server1.ddp.is = 192.168.100.10/24
```

Official DNS server:

```text
192.168.100.10
```

---

# 3. Current Final Lab Design

VMware networks:

| VMware network | Purpose |
|---|---|
| VMnet8 | NAT/WAN internet access |
| VMnet6 | Internal private DDP LAN |

Important lab deviation:
- The PDF mentions VMnet1 for Host-Only.
- This lab uses VMnet6 instead.
- The IP subnet remains exactly `192.168.100.0/24`.

---

# 4. Current Interface Mapping

## server1

| Interface | Role | Addressing |
|---|---|---|
| ens37 | NAT/WAN | DHCP from VMware NAT |
| ens33 | Internal LAN | Static `192.168.100.10/24` |

## client1

| Interface | Role | Addressing |
|---|---|---|
| ens33 | Internal LAN | DHCP from server1 |

Current lease:

```text
192.168.100.100/24
```

## client2

| Interface | Role | Addressing |
|---|---|---|
| ens160 | Internal LAN | DHCP from server1 |

Current lease:

```text
192.168.100.101/24
```

---

# 5. Important DHCP Clarification

Earlier planning used:

```text
client1 = 192.168.100.20
client2 = 192.168.100.30
```

This was only a planning assumption.

The official PDF does NOT require fixed client addresses. It only requires DHCP to automatically assign IP address, gateway, DNS, and domain name to client1 and client2.

Final DHCP design:

```text
range 192.168.100.100 192.168.100.200
```

Current successful leases:

```text
client1.ddp.is = 192.168.100.100
client2.ddp.is = 192.168.100.101
```

This is correct and should be treated as the final DHCP evidence state.

---

# 6. Completed Work

Completed phases:

1. VMware network planning with VMnet6 and VMnet8.
2. Static networking on server1.
3. Initial client connectivity.
4. Persistent journald logging.
5. Centralized rsyslog server on server1.
6. Rsyslog forwarding from client1 and client2.
7. DHCP server installation and configuration.
8. DHCP client configuration on client1 and client2.
9. DHCP evidence files and screenshots.

---

# 7. Current Completed Evidence

From README status, completed DHCP evidence includes:

```text
Evidence/dhcp/client1_lease.txt
Evidence/dhcp/client2_lease.txt
Evidence/dhcp/dhcp_status.txt
Evidence/dhcp/dhcpd.leases
```

Completed screenshots include:

```text
Documentation/Screenshots/Client1_Ubuntu/dhcp.png
Documentation/Screenshots/Client2_CentOS/dhcp.png
Documentation/Screenshots/Server1_Ubuntu/dhcpd_config.png
Documentation/Screenshots/Server1_Ubuntu/dhcp_leases.png
Documentation/Screenshots/Server1_Ubuntu/dhcp_server_status.png
```

---

# 8. Current Next Step

Next logical step:

```text
DNS / BIND9
```

Required DNS evidence files to create later:

```text
Evidence/dns/dig_forward_lookup.txt
Evidence/dns/dig_reverse_lookup.txt
Evidence/dns/named_checkzone_output.txt
```

Do not create these as empty placeholders. Create them after BIND9 works.

---

# 9. Required Commenting Style

All copied config files in `Config_Files/` should use this top-comment style:

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
```

Rules:
- Use this style for all service config files.
- Include exact file path.
- Explain purpose clearly.
- Add short comments above important config groups.
- Do not comment every trivial line.
- Put `# ORIGINAL FILE:` after the documented/project version when copying original configs for evidence.

Example section-comment style:

```conf
# Define the internal DNS domain and DNS server address given to clients.
option domain-name "ddp.is";
option domain-name-servers 192.168.100.10;

# Define how long DHCP leases remain valid before renewal is required.
default-lease-time 600;
max-lease-time 7200;
```

---

# 10. Current DHCP Config

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
```

---

# 11. Current Project Build Order

Continue in this order:

1. DNS/BIND9
2. NTP/Chrony
3. Users/groups from CSV
4. SSH key hardening
5. Postfix + Roundcube
6. CUPS
7. Backup automation
8. Firewall hardening
9. Nmap scans
10. Final report PDF
11. Final README/GitHub cleanup

---

# 12. Recovery Rules

If Ubuntu black screen happens:

```bash
sudo systemctl restart gdm3
```

If interfaces are down after boot:

```bash
sudo ip link set ens37 up
sudo ip link set ens33 up
sudo netplan apply
ip -br addr
```

Client1:

```bash
sudo ip link set ens33 up
sudo netplan apply
ip -br addr
```

CentOS client2:

```bash
sudo systemctl restart NetworkManager
ip -br addr
```

---

# 13. Important Future Instruction for ChatGPT

When helping with this project:

- Do not reintroduce `.20` and `.30` as client final addresses unless explicitly asked.
- Use `.100` and `.101` as the current DHCP evidence state.
- Treat server1 internal LAN as `ens33`.
- Treat server1 NAT/WAN as `ens37`.
- Treat client1 interface as `ens33`.
- Treat client2 interface as `ens160`.
- Follow the current README structure.
- Do not create evidence files before the related service is configured.
- Prefer exact command blocks and short explanations.
- Keep comments in config files professional and consistent.
