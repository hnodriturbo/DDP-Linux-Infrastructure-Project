# Configuration Guide

This document contains the configuration process and infrastructure setup steps for the DDP Linux Infrastructure Project.

---

# My Final Project Build Order

1. Configure static networking
2. Verify client ↔ server connectivity
3. Enable persistent logging
4. Configure centralized Syslog
5. Configure DHCP
6. Configure DNS/BIND9
7. Configure NTP
8. Create users/groups + automation scripts
9. Configure SSH hardening
10. Configure Postfix + Roundcube
11. Configure CUPS printers
12. Configure weekly backup automation
13. Configure firewall hardening
14. Run Nmap verification scans

> Note:
> Screenshots and evidence will be collected continuously throughout the project during each configuration and verification step.

---

# 1. Configure Static Networking

## Server1 - Ubuntu Server

Server1 uses two network adapters:

- `ens33` for NAT internet access
- `ens34` for the internal DDP private network

The private interface will use:

- IP address: `192.168.100.10/24`
- Domain: `ddp.is`
- Hostname: `server1.ddp.is`

### Files

- `/etc/netplan/00-installer-config.yaml`
- `/etc/hosts`
- `/etc/hostname`

---

## Client1 - Ubuntu/Debian Client

Client1 will be connected to the internal network and later receive its IP address from DHCP.

Initial planned address:

- IP address: `192.168.100.20`
- Domain: `ddp.is`
- Hostname: `client1.ddp.is`

### Files

- `/etc/netplan/00-installer-config.yaml`
- `/etc/hosts`
- `/etc/hostname`

---

## Client2 - CentOS/Red Hat Client

Client2 will be connected to the internal network and later receive its IP address from DHCP.

Initial planned address:

- IP address: `192.168.100.30`
- Domain: `ddp.is`
- Hostname: `client2.ddp.is`

### Files

- `/etc/NetworkManager/system-connections/ens160.nmconnection`
- `/etc/hosts`
- `/etc/hostname`

> Note:
> CentOS/Red Hat networking can also be configured using `nmtui`. If `nmtui` is used, the saved NetworkManager connection file should still be copied into the `Config_Files/CentOS_Client2/` folder.

---

# 2. Verify Client ↔ Server Connectivity

## Verification Tasks

- Verify connectivity between all systems
- Verify hostname resolution
- Verify internet access from server1

### Commands

```bash
ping
ip a
hostnamectl
```

---

# 3. Enable Persistent Logging

## Tasks

- Enable persistent journal logging
- Verify logs remain after reboot

### Files

- `/etc/systemd/journald.conf`

---

# 4. Configure Centralized Syslog

## Server1

- Configure rsyslog server
- Enable remote log collection

## Clients

- Configure clients to forward logs to server1

### Files

- `/etc/rsyslog.conf`

---

# 5. Configure DHCP

## Tasks

- Install ISC DHCP server
- Configure DHCP scope
- Configure gateway, DNS, and domain distribution
- Configure client systems to receive network settings from DHCP

### Files

Server1:

- `/etc/dhcp/dhcpd.conf`
- `/etc/default/isc-dhcp-server`

Client1:

- `/etc/netplan/00-installer-config.yaml`

Client2:

- `/etc/NetworkManager/system-connections/ens160.nmconnection`

---

# 6. Configure DNS/BIND9

## Tasks

- Install BIND9
- Configure forward lookup zone
- Configure reverse lookup zone
- Verify DNS resolution

### Files

- `/etc/bind/named.conf`
- `/etc/bind/named.conf.local`
- `/etc/bind/named.conf.options`
- `/etc/bind/named.ddp.is.zone`
- `/etc/bind/named.192.168.100.zone`

---

# 7. Configure NTP

## Tasks

- Configure Chrony/NTP on server1
- Synchronize clients with server1
- Verify time synchronization

### Files

Ubuntu Server1:

- `/etc/chrony/chrony.conf`

Ubuntu/Debian Client1:

- `/etc/chrony/chrony.conf`

CentOS/Red Hat Client2:

- `/etc/chrony.conf`

---

# 8. Create Users/Groups + Automation Scripts

## Tasks

- Create automated user creation script
- Import users from CSV
- Configure groups and permissions
- Verify created users and groups

### Scripts

- `create_users.sh`

---

# 9. Configure SSH Hardening

## Tasks

- Disable password authentication
- Enable RSA key authentication only
- Verify SSH login using keys

### Files

Server1:

- `/etc/ssh/sshd_config`

Client1:

- `/etc/ssh/sshd_config`

Client2:

- `/etc/ssh/sshd_config`

---

# 10. Configure Postfix + Roundcube

## Tasks

- Install Postfix mail server
- Configure internal email delivery
- Install and configure Roundcube
- Verify sending and receiving email

### Files

- `/etc/postfix/main.cf`
- Roundcube configuration files used during setup

---

# 11. Configure CUPS Printers

## Tasks

- Install CUPS
- Configure shared printers
- Configure department-based permissions
- Verify printer access

### Files

- `/etc/cups/cupsd.conf`
- Any printer configuration files created during setup

---

# 12. Configure Weekly Backup Automation

## Tasks

- Create backup script
- Schedule weekly backups every Friday at midnight
- Verify backup output

### Scripts

- `backup_home.sh`

### Files

- User crontab or system cron file used for scheduling

---

# 13. Configure Firewall Hardening

## Tasks

- Close unused ports
- Allow only required infrastructure services
- Verify firewall rules

### Tools

Ubuntu:

- `ufw`

CentOS/Red Hat:

- `firewalld`

---

# 14. Run Nmap Verification Scans

## Tasks

- Verify open ports
- Verify firewall hardening
- Verify SSH restrictions
- Save scan results inside the Evidence folder

### Commands

```bash
nmap
ss -tulnp
```

---

# Evidence Collection

The following evidence will be collected throughout the project:

- Service status screenshots
- DHCP lease verification
- DNS resolution tests
- SSH key login verification
- Syslog verification
- Backup verification
- Nmap scan results
- User creation verification
- Printer configuration verification
