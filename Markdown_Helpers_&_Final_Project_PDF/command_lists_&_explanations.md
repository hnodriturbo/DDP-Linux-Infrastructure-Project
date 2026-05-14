# Command Lists & Explanations — DDP Linux Infrastructure Project

> Purpose: reusable command reference for the final project.  
> Current state: static networking, persistent logging, centralized syslog, and DHCP are complete.  
> Next phase: BIND9 DNS.

---

# Table of Contents

- [1. Hostname and identity commands](#1-hostname-and-identity-commands)
- [2. Network inspection commands](#2-network-inspection-commands)
- [3. Ubuntu Netplan commands](#3-ubuntu-netplan-commands)
- [4. CentOS NetworkManager commands](#4-centos-networkmanager-commands)
- [5. Interface recovery commands](#5-interface-recovery-commands)
- [6. Connectivity test commands](#6-connectivity-test-commands)
- [7. Persistent journald commands](#7-persistent-journald-commands)
- [8. Rsyslog commands](#8-rsyslog-commands)
- [9. DHCP server commands](#9-dhcp-server-commands)
- [10. DHCP client evidence commands](#10-dhcp-client-evidence-commands)
- [11. DNS/BIND9 future commands](#11-dnsbind9-future-commands)
- [12. Routing/NAT commands](#12-routingnat-commands)
- [13. Service management commands](#13-service-management-commands)
- [14. File copy/evidence commands](#14-file-copyevidence-commands)
- [15. Package installation commands](#15-package-installation-commands)
- [16. Useful troubleshooting commands](#16-useful-troubleshooting-commands)

---

# 1. Hostname and Identity Commands

## Set hostname

```bash
sudo hostnamectl set-hostname server1.ddp.is
```

Used on server1 to set the fully qualified domain name.

Parts:
- `sudo` runs the command with administrator privileges.
- `hostnamectl` manages system hostname settings.
- `set-hostname` changes the persistent hostname.
- `server1.ddp.is` is the target hostname.

Client examples:

```bash
sudo hostnamectl set-hostname client1.ddp.is
sudo hostnamectl set-hostname client2.ddp.is
```

---

## Show hostname information

```bash
hostnamectl
```

Purpose:
- Verifies hostname.
- Shows OS/kernel information.
- Good screenshot evidence.

---

## Show full hostname

```bash
hostname -f
```

Purpose:
- Shows fully qualified domain name.
- Useful after editing `/etc/hosts`.

---

# 2. Network Inspection Commands

## Show compact IP address list

```bash
ip -br addr
```

Purpose:
- Best quick view of interfaces and IP addresses.
- Used for screenshots and evidence.

Parts:
- `ip` manages network configuration.
- `-br` means brief output.
- `addr` shows addresses.

---

## Show interface link state

```bash
ip -br link
```

Purpose:
- Shows whether interfaces are `UP` or `DOWN`.
- Useful after VMware boot problems.

---

## Show full interface information

```bash
ip link
```

Purpose:
- Shows MAC addresses.
- Useful for DHCP reservation troubleshooting.

---

## Show routing table

```bash
ip route
```

Purpose:
- Shows default gateway.
- Confirms clients route traffic through `192.168.100.10`.

Current expected client route:

```text
default via 192.168.100.10 dev ens33 proto dhcp
```

---

# 3. Ubuntu Netplan Commands

## Open Netplan file

```bash
sudo nano /etc/netplan/00-installer-config.yaml
```

Purpose:
- Edits Ubuntu network configuration.

Parts:
- `sudo` opens as administrator.
- `nano` is the text editor.
- `/etc/netplan/00-installer-config.yaml` is the Netplan file.

---

## Set secure Netplan permissions

```bash
sudo chmod 600 /etc/netplan/00-installer-config.yaml
```

Purpose:
- Removes unsafe read access.
- Prevents Netplan warning messages.

Parts:
- `chmod` changes permissions.
- `600` means owner read/write only.

---

## Generate Netplan config

```bash
sudo netplan generate
```

Purpose:
- Checks and generates backend network config.
- Useful before applying changes.

---

## Apply Netplan config

```bash
sudo netplan apply
```

Purpose:
- Applies Ubuntu network configuration.

Use after editing:
- static networking
- DHCP mode
- DNS settings
- route settings

---

# 4. CentOS NetworkManager Commands

## Open text network manager

```bash
sudo nmtui
```

Purpose:
- Opens text-based network configuration UI.
- Good for CentOS interface configuration.

---

## Show connections

```bash
nmcli connection show
```

Purpose:
- Lists NetworkManager connection names.
- Needed before using `nmcli connection modify`.

---

## Set DHCP mode

```bash
sudo nmcli connection modify ens160 ipv4.method auto
```

Purpose:
- Makes CentOS client receive IP settings from DHCP.

Parts:
- `nmcli` controls NetworkManager.
- `connection modify` edits a connection profile.
- `ens160` is the connection/interface name.
- `ipv4.method auto` means DHCP.

---

## Restart connection

```bash
sudo nmcli connection down ens160
sudo nmcli connection up ens160
```

Purpose:
- Forces new DHCP request.
- Updates IP, route, and DNS settings.

---

## Restart NetworkManager

```bash
sudo systemctl restart NetworkManager
```

Purpose:
- Reloads CentOS networking.
- Useful if connection changes are not applied.

---

# 5. Interface Recovery Commands

## Bring server interfaces UP

```bash
sudo ip link set ens37 up
sudo ip link set ens33 up
```

Purpose:
- Recovers server1 after VMware boot/interface issue.

Current server roles:
- `ens37` = NAT/WAN.
- `ens33` = internal LAN.

---

## Bring client1 interface UP

```bash
sudo ip link set ens33 up
```

Purpose:
- Recovers client1 Ubuntu internal LAN interface.

---

## Verify after recovery

```bash
ip -br addr
ip route
```

Purpose:
- Confirms IP address and default route returned.

---

# 6. Connectivity Test Commands

## Ping server IP

```bash
ping -c 4 192.168.100.10
```

Purpose:
- Tests client-to-server connectivity.

Parts:
- `ping` sends ICMP echo requests.
- `-c 4` sends exactly 4 packets.
- `192.168.100.10` is server1.

---

## Ping external IP

```bash
ping -c 4 8.8.8.8
```

Purpose:
- Tests routing/internet connectivity without DNS.

---

## Ping external domain

```bash
ping -c 4 google.com
```

Purpose:
- Tests both internet and DNS resolution.

---

## Resolve local hosts through hosts/DNS

```bash
getent hosts server1.ddp.is
getent hosts client1.ddp.is
getent hosts client2.ddp.is
```

Purpose:
- Shows name resolution from system databases.
- Works with `/etc/hosts` before BIND9 is ready.

---

# 7. Persistent Journald Commands

## Create persistent journal directory

```bash
sudo mkdir -p /var/log/journal
```

Purpose:
- Allows systemd journal logs to survive reboot.

Parts:
- `mkdir` creates a directory.
- `-p` avoids error if it already exists.

---

## Apply journald tempfiles

```bash
sudo systemd-tmpfiles --create --prefix /var/log/journal
```

Purpose:
- Applies systemd directory permissions/settings for journal storage.

---

## Restart journald

```bash
sudo systemctl restart systemd-journald
```

Purpose:
- Reloads persistent journal configuration.

---

## Show journal boots

```bash
journalctl --list-boots
```

Purpose:
- Verifies logs exist across boots.

---

## Show disk usage

```bash
journalctl --disk-usage
```

Purpose:
- Shows how much space journal logs use.

---

# 8. Rsyslog Commands

## Install rsyslog

```bash
sudo apt install rsyslog -y
```

Ubuntu package installation.

```bash
sudo dnf install rsyslog -y
```

CentOS package installation.

---

## Enable and start rsyslog

```bash
sudo systemctl enable --now rsyslog
```

Purpose:
- Starts rsyslog immediately.
- Enables rsyslog at boot.

---

## Restart rsyslog

```bash
sudo systemctl restart rsyslog
```

Purpose:
- Applies rsyslog configuration changes.

---

## Check rsyslog status

```bash
systemctl status rsyslog --no-pager
```

Purpose:
- Shows whether rsyslog is active.
- `--no-pager` keeps output directly in terminal.

---

## Verify syslog listening port

```bash
sudo ss -tulnp | grep ':514'
```

Purpose:
- Confirms rsyslog is listening on TCP/UDP 514.

Parts:
- `ss` shows sockets.
- `-t` shows TCP.
- `-u` shows UDP.
- `-l` shows listening sockets.
- `-n` avoids DNS/service-name lookup.
- `-p` shows process names.
- `grep ':514'` filters syslog port.

---

## Send test log

```bash
logger -p user.info "DDP syslog test from client1"
```

Purpose:
- Creates test log message.
- Confirms centralized logging works.

---

## Find remote logs

```bash
sudo find /var/log/remote -type f | sort
```

Purpose:
- Lists files created by remote syslog clients.

---

## Search remote logs

```bash
sudo grep -R "DDP syslog test" /var/log/remote
```

Purpose:
- Confirms test messages arrived on server1.

---

# 9. DHCP Server Commands

## Install ISC DHCP server

```bash
sudo apt install isc-dhcp-server -y
```

Purpose:
- Installs DHCP service on server1.

---

## Open DHCP default interface file

```bash
sudo nano /etc/default/isc-dhcp-server
```

Purpose:
- Defines which interface DHCP listens on.

Current correct setting:

```conf
INTERFACESv4="ens33"
INTERFACESv6=""
```

---

## Open DHCP main config

```bash
sudo nano /etc/dhcp/dhcpd.conf
```

Purpose:
- Defines DHCP pool and options.

Current DHCP pool:

```text
192.168.100.100 - 192.168.100.200
```

---

## Restart DHCP service

```bash
sudo systemctl restart isc-dhcp-server
```

Purpose:
- Applies DHCP config changes.

---

## Check DHCP service status

```bash
systemctl status isc-dhcp-server --no-pager
```

Purpose:
- Confirms service is active/running.
- Shows interface DHCP is listening on.
- Shows recent DHCPREQUEST/DHCPACK messages.

---

## Watch DHCP logs live

```bash
sudo journalctl -fu isc-dhcp-server
```

Purpose:
- Live DHCP troubleshooting.

Parts:
- `journalctl` reads system logs.
- `-f` follows new entries.
- `-u isc-dhcp-server` filters to DHCP unit.

---

## Show DHCP lease file

```bash
sudo cat /var/lib/dhcp/dhcpd.leases
```

Purpose:
- Shows active DHCP leases.
- Good final evidence file.

Current expected leases:
- client1 → `192.168.100.100`
- client2 → `192.168.100.101`

---

# 10. DHCP Client Evidence Commands

## client1 Ubuntu evidence

```bash
ip -br addr
ip route
resolvectl status
```

Shows:
- DHCP IP lease.
- Default gateway.
- DNS server.
- DNS domain.

---

## client2 CentOS evidence

```bash
ip -br addr
ip route
cat /etc/resolv.conf
```

Shows:
- DHCP IP lease.
- Default gateway.
- DNS server.
- Search domain.

---

# 11. DNS/BIND9 Future Commands

## Install BIND9

```bash
sudo apt install bind9 bind9utils dnsutils -y
```

Purpose:
- Installs DNS server and DNS test tools.

---

## Validate named config

```bash
sudo named-checkconf
```

Purpose:
- Checks BIND9 config syntax.

---

## Validate forward zone

```bash
sudo named-checkzone ddp.is /etc/bind/db.ddp.is
```

Purpose:
- Checks the `ddp.is` forward zone.

---

## Validate reverse zone

```bash
sudo named-checkzone 100.168.192.in-addr.arpa /etc/bind/db.192.168.100
```

Purpose:
- Checks reverse DNS zone.

---

## Test forward lookup

```bash
dig @192.168.100.10 server1.ddp.is
```

Purpose:
- Confirms DNS name-to-IP lookup.

---

## Test reverse lookup

```bash
dig @192.168.100.10 -x 192.168.100.10
```

Purpose:
- Confirms IP-to-name lookup.

---

# 12. Routing/NAT Commands

## Enable IPv4 forwarding now

```bash
sudo sysctl -p
```

Purpose:
- Applies `/etc/sysctl.conf` changes.

---

## Verify IPv4 forwarding

```bash
cat /proc/sys/net/ipv4/ip_forward
```

Expected:

```text
1
```

---

## Add NAT masquerading

```bash
sudo iptables -t nat -A POSTROUTING -o ens37 -j MASQUERADE
```

Purpose:
- Allows internal clients to share server1 NAT internet route.

Parts:
- `-t nat` selects NAT table.
- `-A POSTROUTING` appends rule after routing decision.
- `-o ens37` means traffic leaving WAN/NAT interface.
- `-j MASQUERADE` rewrites source address.

---

## Save iptables rules

```bash
sudo netfilter-persistent save
```

Purpose:
- Saves iptables rules persistently.

---

# 13. Service Management Commands

## Enable service at boot

```bash
sudo systemctl enable SERVICE_NAME
```

Purpose:
- Makes service start automatically after reboot.

---

## Start service

```bash
sudo systemctl start SERVICE_NAME
```

Purpose:
- Starts service immediately.

---

## Restart service

```bash
sudo systemctl restart SERVICE_NAME
```

Purpose:
- Reloads service after config changes.

---

## Show failed services

```bash
systemctl --failed
```

Purpose:
- Quickly finds broken services.

---

# 14. File Copy/Evidence Commands

## Save command output to file

```bash
command > file.txt
```

Purpose:
- Creates or overwrites evidence file.

---

## Append command output to file

```bash
command >> file.txt
```

Purpose:
- Adds evidence to an existing file.

---

## Show and save output

```bash
command | tee file.txt
```

Purpose:
- Shows output in terminal and saves it to file.

---

## Append with tee

```bash
command | tee -a file.txt
```

Purpose:
- Shows output and appends to evidence file.

---

# 15. Package Installation Commands

## Ubuntu install

```bash
sudo apt update
sudo apt install PACKAGE_NAME -y
```

Purpose:
- Updates package index.
- Installs package automatically.

---

## CentOS install

```bash
sudo dnf install PACKAGE_NAME -y
```

Purpose:
- Installs packages on Red Hat/CentOS systems.

---

# 16. Useful Troubleshooting Commands

## Show recent logs for a service

```bash
journalctl -u SERVICE_NAME --no-pager | tail -n 50
```

Purpose:
- Shows latest logs without opening pager.

---

## Follow all logs live

```bash
journalctl -f
```

Purpose:
- Useful while restarting services.

---

## Show listening services

```bash
sudo ss -tulnp
```

Purpose:
- Verifies which services are accepting connections.

---

## Check DNS resolver on Ubuntu

```bash
resolvectl status
```

Purpose:
- Shows DNS server and search domain.

---

## Check DNS resolver on CentOS

```bash
cat /etc/resolv.conf
```

Purpose:
- Shows DNS server and search domain.
