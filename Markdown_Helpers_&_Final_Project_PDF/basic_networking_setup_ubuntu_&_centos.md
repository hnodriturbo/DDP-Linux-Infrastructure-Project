# Basic Networking Setup — Ubuntu & CentOS

> This file is a cleaned current-state networking guide for the final project.  
> The older `ubuntu_network_setup_guide.md` and `centos_network_setup_guide.md` used the earlier VMnet5 / 192.168.56.0/24 practice network.  
> The final project now uses **VMnet6** and **192.168.100.0/24**.

---

# Table of Contents

- [1. Final Network Design](#1-final-network-design)
- [2. Server1 Ubuntu Interface Mapping](#2-server1-ubuntu-interface-mapping)
- [3. Client1 Ubuntu Interface Mapping](#3-client1-ubuntu-interface-mapping)
- [4. Client2 CentOS Interface Mapping](#4-client2-centos-interface-mapping)
- [5. Ubuntu Server Netplan](#5-ubuntu-server-netplan)
- [6. Client1 Ubuntu DHCP Netplan](#6-client1-ubuntu-dhcp-netplan)
- [7. Client2 CentOS DHCP Setup](#7-client2-centos-dhcp-setup)
- [8. Verification Commands](#8-verification-commands)
- [9. Screenshot Evidence](#9-screenshot-evidence)
- [10. Troubleshooting](#10-troubleshooting)

---

# 1. Final Network Design

```text
                         INTERNET
                            │
                      VMware VMnet8 NAT
                            │
                      ens37 on server1
                            │
                    server1.ddp.is
                    192.168.100.10
                            │
                      ens33 on server1
                            │
                   VMware VMnet6 LAN
                   192.168.100.0/24
                            │
        ┌───────────────────┴───────────────────┐
        │                                       │
 client1.ddp.is                           client2.ddp.is
 Ubuntu client                             CentOS client
 DHCP lease: 192.168.100.100              DHCP lease: 192.168.100.101
```

---

# 2. Server1 Ubuntu Interface Mapping

| Interface | Network | Purpose | IP mode |
|---|---|---|---|
| ens37 | VMnet8 NAT | Internet/package access | DHCP from VMware NAT |
| ens33 | VMnet6 LAN | Internal DDP services | Static `192.168.100.10/24` |

Important:
- `ens33` is the internal LAN interface in the current lab.
- DHCP, DNS, NTP, Syslog, SSH, CUPS, and mail services should listen on or be reachable through `192.168.100.10`.

---

# 3. Client1 Ubuntu Interface Mapping

| Interface | Network | Purpose | IP mode |
|---|---|---|---|
| ens33 | VMnet6 LAN | Internal client network | DHCP from server1 |

Current DHCP result:

```text
192.168.100.100/24
```

---

# 4. Client2 CentOS Interface Mapping

| Interface | Network | Purpose | IP mode |
|---|---|---|---|
| ens160 | VMnet6 LAN | Internal client network | DHCP from server1 |

Current DHCP result:

```text
192.168.100.101/24
```

---

# 5. Ubuntu Server Netplan

## File: `/etc/netplan/00-installer-config.yaml`

```yaml
# ================================
# Netplan Configuration - DDP server1
# ================================
# Path: /etc/netplan/00-installer-config.yaml
# Purpose:
# - Configure server1 NAT/WAN access through VMware VMnet8
# - Configure server1 internal LAN access through VMware VMnet6
# - Provide a stable internal IP for DHCP, DNS, NTP, Syslog, SSH, CUPS, and mail
# ================================

network:
  version: 2
  renderer: networkd

  ethernets:

    # Internal DDP LAN interface using static addressing.
    ens33:
      dhcp4: false
      addresses:
        - 192.168.100.10/24

    # VMware NAT/WAN interface using DHCP from VMnet8.
    ens37:
      dhcp4: true
```

# ORIGINAL FILE:

Paste the original captured server Netplan file below this section when copying into `Config_Files/Server1_Ubuntu/etc/netplan/00-installer-config.yaml`.

---

## Apply server Netplan

```bash
sudo chmod 600 /etc/netplan/00-installer-config.yaml
sudo netplan generate
sudo netplan apply
```

---

# 6. Client1 Ubuntu DHCP Netplan

## File: `/etc/netplan/00-installer-config.yaml`

```yaml
# ================================
# Netplan Configuration - DDP client1 DHCP
# ================================
# Path: /etc/netplan/00-installer-config.yaml
# Purpose:
# - Configure client1 to receive network settings from server1 DHCP
# - Receive IP address, gateway, DNS server, and domain automatically
# - Support DHCP evidence for the final project
# ================================

network:
  version: 2
  renderer: NetworkManager

  ethernets:

    # Internal DDP LAN interface using DHCP from server1.
    ens33:
      dhcp4: true
```

# ORIGINAL FILE:

Paste the original captured client1 Netplan file below this section when copying into `Config_Files/Client1_Ubuntu/etc/netplan/00-installer-config.yaml`.

---

## Apply client1 Netplan

```bash
sudo netplan apply
```

---

# 7. Client2 CentOS DHCP Setup

## GUI method

```bash
sudo nmtui
```

Steps:
1. Edit a connection.
2. Select `ens160`.
3. Set IPv4 method to Automatic/DHCP.
4. Save.
5. Activate the connection again.

---

## CLI method

```bash
nmcli connection show
```

Use the connection name shown. If it is `ens160`, run:

```bash
sudo nmcli connection modify ens160 ipv4.method auto
sudo nmcli connection down ens160
sudo nmcli connection up ens160
```

---

## NetworkManager connection file style

The final saved connection file can be copied from:

```text
/etc/NetworkManager/system-connections/
```

Expected evidence file path:

```text
Config_Files/Client2_CentOS/etc/NetworkManager/system-connections/ens160.nmconnection
```

---

# 8. Verification Commands

## server1

```bash
hostnamectl
ip -br addr
ip route
ping -c 4 8.8.8.8
ping -c 4 google.com
```

Expected:
- `ens33` has `192.168.100.10/24`.
- `ens37` has NAT/WAN DHCP address.
- server1 can reach the internet.

---

## client1

```bash
hostnamectl
ip -br addr
ip route
resolvectl status
ping -c 4 192.168.100.10
```

Expected:
- client1 has `192.168.100.100/24`.
- default route points to `192.168.100.10`.
- DNS server is `192.168.100.10`.
- DNS domain is `ddp.is`.

---

## client2

```bash
hostnamectl
ip -br addr
ip route
cat /etc/resolv.conf
ping -c 4 192.168.100.10
```

Expected:
- client2 has `192.168.100.101/24`.
- default route points to `192.168.100.10`.
- DNS server is `192.168.100.10`.
- search domain is `ddp.is`.

---

# 9. Screenshot Evidence

Required screenshots already completed or planned:

```text
Documentation/Screenshots/Server1_Ubuntu/static_network_validation.png
Documentation/Screenshots/Client1_Ubuntu/static_network_validation.png
Documentation/Screenshots/Client2_CentOS/static_network_validation.png
Documentation/Screenshots/Client1_Ubuntu/dhcp.png
Documentation/Screenshots/Client2_CentOS/dhcp.png
Documentation/Screenshots/Server1_Ubuntu/dhcp_server_status.png
Documentation/Screenshots/Server1_Ubuntu/dhcp_leases.png
```

---

# 10. Troubleshooting

## Bring interfaces up on server1

```bash
sudo ip link set ens37 up
sudo ip link set ens33 up
sudo netplan apply
ip -br addr
```

---

## Bring client1 interface up

```bash
sudo ip link set ens33 up
sudo netplan apply
ip -br addr
```

---

## Restart CentOS networking

```bash
sudo systemctl restart NetworkManager
ip -br addr
```

---

## Check DHCP logs from server1

```bash
sudo journalctl -fu isc-dhcp-server
```
