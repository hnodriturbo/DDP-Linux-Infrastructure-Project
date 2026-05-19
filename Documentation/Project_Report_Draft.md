# DDP Linux Infrastructure Project — Project Report Draft

> Course: KEST3NL05EU — Linux Netstjórnun  
> Project: DDP Linux Infrastructure Project  
> Company: DDP ehf.  
> Domain: `ddp.is`

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Project Goal](#2-project-goal)
3. [Network Design](#3-network-design)
4. [Server and Client Setup](#4-server-and-client-setup)
5. [Static Networking and Internal LAN](#5-static-networking-and-internal-lan)
6. [DHCP Implementation](#6-dhcp-implementation)
7. [DNS / BIND9 Implementation](#7-dns--bind9-implementation)
8. [Time Synchronization](#8-time-synchronization)
9. [Centralized Logging](#9-centralized-logging)
10. [User and Group Management](#10-user-and-group-management)
11. [SSH Security](#11-ssh-security)
12. [Mail and Webmail Services](#12-mail-and-webmail-services)
13. [Printer Sharing](#13-printer-sharing)
14. [Backup Automation](#14-backup-automation)
15. [Firewall and Nmap Verification](#15-firewall-and-nmap-verification)
16. [Problems Encountered and Fixes](#16-problems-encountered-and-fixes)
17. [Final Result](#17-final-result)
18. [Conclusion](#18-conclusion)

---

## 1. Introduction

This project was created for the KEST3NL05EU Linux network administration course.

The goal was to build a small centralized Linux infrastructure for a company called DDP ehf. The infrastructure uses one central Ubuntu server and two Linux clients. The server provides the main network services required by the project, while the clients are used to test and verify that the services work correctly.

The project focuses on practical Linux administration tasks such as IP management, DNS, time synchronization, centralized logging, user automation, SSH security, mail services, printer sharing, backups, firewall hardening, and Nmap verification.

---

## 2. Project Goal

The main goal of the project was to create a reliable, secure, and centralized Linux-based infrastructure for DDP ehf.

The infrastructure was designed to provide the following services:

- DHCP for automatic IP address assignment
- DNS/BIND9 for internal name resolution
- Chrony/NTP for time synchronization
- centralized Syslog logging
- automated Linux user and group creation
- SSH hardening with RSA key authentication
- Postfix and Roundcube for mail and webmail
- CUPS printer sharing
- weekly backup automation
- firewall hardening
- Nmap verification scans

The final result should be a clean GitHub repository containing documentation, configuration files, scripts, screenshots, and evidence files.

---

## 3. Network Design

The network was designed with one central server and two client systems.

The central server is `server1.ddp.is`. It is responsible for hosting the infrastructure services. The two clients are `client1.ddp.is` and `client2.ddp.is`. Client1 is the Debian-based/Ubuntu client, and client2 is the Red Hat-based/CentOS client.

The official project requires the private network to use the `192.168.100.0/24` subnet and the server to use the static IP address `192.168.100.10/24`. This was followed in the final lab design.

One lab change was made: the official project mentions VMnet1 as the host-only network, but this lab uses VMware VMnet6 for the private LAN. The subnet and server IP address remain the same, so the technical requirement is still satisfied.

The server uses two network adapters:

| Interface | Purpose |
|---|---|
| `ens37` | NAT/WAN internet access through VMnet8 |
| `ens33` | Internal DDP LAN through VMnet6 |

The clients only use the internal DDP LAN.

---

## 4. Server and Client Setup

The project contains three machines:

| Machine | Role |
|---|---|
| `server1.ddp.is` | Central management server |
| `client1.ddp.is` | Debian-based client |
| `client2.ddp.is` | Red Hat-based client |

The hostnames were configured to match the `ddp.is` domain. This was important because later services such as DNS, SSH, Syslog, mail, and CUPS depend on consistent hostnames.

Before DNS was configured, local `/etc/hosts` entries were used to make hostname resolution work during the early setup stage. After DNS/BIND9 is completed, DNS becomes the main source of name resolution.

---

## 5. Static Networking and Internal LAN

Static networking was configured on `server1.ddp.is` so that the server always uses the internal IP address `192.168.100.10/24`.

This was necessary because all infrastructure services depend on the server having a stable address. Clients need to know where to find DHCP, DNS, NTP, Syslog, SSH, mail, CUPS, and other services.

The final server network design is:

| Interface | Configuration |
|---|---|
| `ens37` | DHCP from VMware NAT for internet access |
| `ens33` | Static `192.168.100.10/24` for the internal DDP LAN |

The clients were later configured to receive their network settings from the DHCP service running on `server1`.

---

## 6. DHCP Implementation

To satisfy the DHCP requirement, I configured `server1.ddp.is` as the DHCP server for the internal DDP LAN.

The DHCP service was bound to the internal interface instead of the NAT interface. This was important because the NAT interface is only used for internet access, while the private interface is responsible for internal company services.

The DHCP pool was configured to assign addresses from:

```text
192.168.100.100 – 192.168.100.200
```

The DHCP server also provides clients with:

- default gateway: `192.168.100.10`
- DNS server: `192.168.100.10`
- domain name: `ddp.is`

Both clients successfully received DHCP leases:

| Client | DHCP Lease |
|---|---|
| `client1.ddp.is` | `192.168.100.100` |
| `client2.ddp.is` | `192.168.100.101` |

This proves that the Linux DHCP server is controlling the internal network instead of VMware DHCP.

---

## 7. DNS / BIND9 Implementation

BIND9 is used to provide DNS resolution for the `ddp.is` domain.

The purpose of DNS is to allow machines and services to be reached by name instead of only by IP address. This is especially useful for services such as mail, SSH, printing, and logging.

The planned DNS configuration includes:

- a forward lookup zone for `ddp.is`
- a reverse lookup zone for `192.168.100.0/24`
- host records for `server1`, `client1`, and `client2`
- service records/names for mail, printing, NTP, and Syslog

This section should be updated with final evidence after BIND9 is fully configured and tested.

---

## 8. Time Synchronization

Chrony is used for time synchronization.

Time synchronization is important because all systems need consistent timestamps. This affects logs, backups, security evidence, mail records, and troubleshooting.

The intended design is that `server1.ddp.is` acts as the internal time server, while `client1.ddp.is` and `client2.ddp.is` synchronize their time from `server1`.

This section should be updated with final Chrony status and client synchronization evidence after the phase is complete.

---

## 9. Centralized Logging

Centralized logging was configured so that `server1.ddp.is` receives logs from both client systems.

This was done using rsyslog. The server was configured as a Syslog receiver, and both clients were configured to forward log messages to the server.

The purpose of this setup is to support proactive monitoring and troubleshooting. Instead of checking logs separately on every machine, the server can collect logs from the clients in one central location.

Remote logs are stored on the server under:

```text
/var/log/remote/
```

The setup was verified by sending test log messages from both clients and confirming that the messages arrived on `server1`.

---

## 10. User and Group Management

User and group management is handled with a Bash automation script.

The script reads the provided user CSV file and creates Linux users, home directories, department groups, and group memberships.

The expected department groups are:

- `Tolvudeild`
- `Rekstrardeild`
- `Framkvaemdadeild`
- `Framleidsludeild`

The project text says 30 employees, but the uploaded CSV file contains 29 user entries plus the header. I did not invent a missing user. This mismatch should be mentioned in the final report unless an updated CSV is provided.

This section should be updated after the user creation script is run and the final user evidence files are generated.

---

## 11. SSH Security

SSH is hardened to require RSA key-based authentication and disable password authentication.

This improves security because users cannot log in remotely using only a password. Instead, SSH login requires a valid private key that matches an authorized public key on the server.

The expected SSH hardening settings include:

- root SSH login disabled
- public key authentication enabled
- password authentication disabled
- keyboard-interactive authentication disabled
- challenge-response authentication disabled

The important safety rule is that key-based login must be tested before password login is disabled.

This section should be updated with final SSH login evidence after the hardening phase is complete.

---

## 12. Mail and Webmail Services

Mail service is planned using Postfix, Dovecot, and Roundcube.

Postfix handles mail sending and receiving. Dovecot provides mailbox access. Roundcube provides a browser-based webmail interface.

The mail service is hosted on `server1.ddp.is` and should use the internal domain:

```text
ddp.is
```

The expected mail hostname is:

```text
mail.ddp.is
```

This section should be updated with service status, local mail tests, and Roundcube login evidence after the mail phase is complete.

---

## 13. Printer Sharing

Printer sharing is planned with CUPS.

The project requires shared printers with group-based access control. Users should print through printers connected to their department group, while IT and Management should have broader print and manage rights.

Because this is a virtual lab, simulated or PDF printers may be used if physical printers are not available.

This section should be updated with CUPS service status, printer queue evidence, CUPS web interface evidence, and any group access policy evidence after the printer phase is complete.

---

## 14. Backup Automation

Backup automation is required to back up all home directories every Friday at midnight.

The backup script is designed to archive `/home` and store compressed backups under:

```text
/backup/ddp-home
```

The cron schedule for Friday at midnight is:

```text
0 0 * * 5
```

This section should be updated after the backup script is tested manually and the cron schedule is documented.

---

## 15. Firewall and Nmap Verification

Firewall hardening closes unused ports and allows only required infrastructure services.

On Ubuntu, UFW is used. On CentOS, firewalld is used.

After firewall rules are configured, Nmap scans are used to verify which ports are open. The goal is to confirm that required services are reachable and unnecessary services are not exposed.

Expected Nmap targets:

| Target | Purpose |
|---|---|
| `192.168.100.10` | Scan `server1` services |
| `192.168.100.100` | Scan `client1` |
| `192.168.100.101` | Scan `client2` |

This section should be updated after the firewall and final Nmap phase is complete.

---

## 16. Problems Encountered and Fixes

During the project, some VMware and Linux startup issues appeared.

One issue was that Ubuntu sometimes showed a black screen after boot or login. This was fixed by switching to a TTY and restarting the display manager.

Another issue was that network interfaces sometimes appeared down after reboot. This was usually a VMware or startup timing issue, not lost configuration. The fix was to bring the interfaces back up, apply Netplan again, and restart the DHCP service if needed.

The recommended boot order is:

1. Start `server1`
2. Wait for services to start
3. Start `client1`
4. Start `client2`

This helps ensure that DHCP, DNS, and Syslog are available before the clients request services.

---

## 17. Final Result

At the current stage, the project has completed:

- VMware network planning
- static networking on `server1`
- client connectivity
- persistent journald logging
- centralized rsyslog logging
- DHCP server configuration
- DHCP client configuration
- DHCP evidence and screenshots
- Chrony/NTP phase

The next major phases are:

- users and groups from CSV
- SSH key hardening
- Postfix and Roundcube
- CUPS printer sharing
- backup automation
- firewall hardening
- Nmap verification
- final project report cleanup

This section should be updated at the end with the final completed state.

---

## 18. Conclusion

This project demonstrates how a small Linux-based company infrastructure can be built using one central server and two clients.

The server provides the core services needed for a managed internal network, including IP management, name resolution, time synchronization, logging, user management, secure remote access, mail, printing, backups, and firewall protection.

The project is documented with configuration files, screenshots, scripts, and command evidence so that each requirement can be reviewed and verified.

