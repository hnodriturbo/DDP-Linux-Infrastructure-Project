# DDP Linux Infrastructure Project — Configuration Guide

> Course: KEST3NL05EU — Linux Netstjórnun  
> Project: DDP Linux Infrastructure Project  
> Domain: `ddp.is`  
> Main server: `server1.ddp.is`  
> Clients: `client1.ddp.is`, `client2.ddp.is`

---

## Table of Contents

1. [Project Environment](#1-project-environment)
2. [Network Architecture](#2-network-architecture)
3. [Hostnames and Domain Identity](#3-hostnames-and-domain-identity)
4. [Static Server Networking](#4-static-server-networking)
5. [Persistent Logging and Centralized Syslog](#5-persistent-logging-and-centralized-syslog)
6. [DHCP Configuration](#6-dhcp-configuration)
7. [DNS / BIND9 Configuration](#7-dns--bind9-configuration)
8. [Time Synchronization / Chrony](#8-time-synchronization--chrony)
9. [User and Group Automation](#9-user-and-group-automation)
10. [SSH Hardening](#10-ssh-hardening)
11. [Postfix, Dovecot, and Roundcube Mail](#11-postfix-dovecot-and-roundcube-mail)
12. [CUPS Printer Sharing](#12-cups-printer-sharing)
13. [Backup Automation](#13-backup-automation)
14. [Firewall Hardening](#14-firewall-hardening)
15. [Nmap and Final Service Verification](#15-nmap-and-final-service-verification)
16. [Repository Evidence Structure](#16-repository-evidence-structure)

---

## 1. Project Environment

### Purpose

The project environment defines the machines, operating systems, domain name, and infrastructure role of each system in the DDP Linux infrastructure.

The purpose of this environment is to simulate a small company network where one central Linux server provides essential services to Linux clients.

### Final Configuration

The infrastructure is built around one central Ubuntu server and two Linux clients:

| Hostname         | Role                      | Operating System Family | Purpose                                                                         |
| ---------------- | ------------------------- | ----------------------- | ------------------------------------------------------------------------------- |
| `server1.ddp.is` | Central Management Server | Ubuntu Server           | Hosts DHCP, DNS, NTP, Syslog, SSH, mail, printer, backup, and firewall services |
| `client1.ddp.is` | Client machine            | Debian-based / Ubuntu   | Receives network services from `server1`                                        |
| `client2.ddp.is` | Client machine            | Red Hat-based / CentOS  | Receives network services from `server1`                                        |

Project domain:

```text
ddp.is
```

Internal LAN subnet:

```text
192.168.100.0/24
```

Main server internal IP:

```text
192.168.100.10/24
```

### Related Files

**Server 1 Ubuntu**
- None specific for this chapter.

**Client 1 Ubuntu**
- None specific for this chapter.

**Client 2 CentOS**
- None specific for this chapter.

**Shared / Project Files**
- `README.md`
- `Documentation/Network_Infrastructure.png`
- `Documentation/Network_Structure_Basic_Text_Diagram.md`

### Evidence

**Server 1 Ubuntu**
- `Documentation/Screenshots/Server1_Ubuntu/static_network_validation.png`

**Client 1 Ubuntu**
- `Documentation/Screenshots/Client1_Ubuntu/static_network_validation.png`

**Client 2 CentOS**
- `Documentation/Screenshots/Client2_CentOS/static_network_validation.png`

**Shared / Project Files**
- `Documentation/Network_Infrastructure.png`

### Verification

The project environment is verified by checking the hostnames, IP addressing, and network connectivity of all three systems. The machines must match the expected DDP infrastructure design and must be able to communicate on the private LAN.

---

## 2. Network Architecture

### Purpose

The network architecture separates internet access from internal company services.

The server uses two network adapters:

- one adapter for internet access and package downloads
- one adapter for the private DDP LAN where infrastructure services run

This separation keeps internal services controlled inside the private network while still allowing the server to install updates and required packages.

### Final Configuration

The official project mentions a NAT adapter and a host-only/private adapter. In this lab, VMware `VMnet8` is used for NAT/WAN access and VMware `VMnet6` is used for the internal private LAN.

The subnet remains the required project subnet:

```text
192.168.100.0/24
```

Current interface mapping:

| Machine          | Interface | Network        | Purpose                              | Addressing                 |
| ---------------- | --------- | -------------- | ------------------------------------ | -------------------------- |
| `server1.ddp.is` | `ens37`   | VMnet8 NAT/WAN | Internet access for updates/packages | DHCP from VMware NAT       |
| `server1.ddp.is` | `ens33`   | VMnet6 LAN     | Internal DDP infrastructure services | Static `192.168.100.10/24` |
| `client1.ddp.is` | `ens33`   | VMnet6 LAN     | Internal client network              | DHCP from `server1`        |
| `client2.ddp.is` | `ens160`  | VMnet6 LAN     | Internal client network              | DHCP from `server1`        |

Current DHCP client leases:

| Client           | Current IP Address |
| ---------------- | ------------------ |
| `client1.ddp.is` | `192.168.100.100`  |
| `client2.ddp.is` | `192.168.100.101`  |

### Related Files

**Server 1 Ubuntu**
- `Config_Files/Server1_Ubuntu/etc/netplan/00-installer-config.yaml`

**Client 1 Ubuntu**
- `Config_Files/Client1_Ubuntu/etc/netplan/00-installer-config.yaml`

**Client 2 CentOS**
- `Config_Files/Client2_CentOS/etc/NetworkManager/system-connections/ens160.nmconnection`
- `Config_Files/Client2_CentOS/etc/sysconfig/network-scripts/ifcfg-ens160`

### Evidence

**Server 1 Ubuntu**
- `Documentation/Screenshots/Server1_Ubuntu/static_network_validation.png`

**Client 1 Ubuntu**
- `Documentation/Screenshots/Client1_Ubuntu/static_network_validation.png`

**Client 2 CentOS**
- `Documentation/Screenshots/Client2_CentOS/static_network_validation.png`

**Shared / Project Files**
- `Documentation/Network_Infrastructure.png`

### Verification

The network architecture is verified by checking interface names, IP addresses, routing tables, and ping tests between clients and the server. The server must have both NAT/WAN and internal LAN connectivity, while the clients should only use the internal DDP LAN.

---

## 3. Hostnames and Domain Identity

### Purpose

Hostnames and domain identity make each machine clearly identifiable inside the project network.

This is important because services such as DNS, SSH, Syslog, mail, and CUPS rely on predictable hostnames.

### Final Configuration

The systems are configured with fully qualified domain names under the `ddp.is` domain:

| Machine  | Hostname         |
| -------- | ---------------- |
| Server   | `server1.ddp.is` |
| Client 1 | `client1.ddp.is` |
| Client 2 | `client2.ddp.is` |

Before DNS was fully configured, `/etc/hosts` was used as temporary local name resolution. After BIND9 is configured, DNS becomes the main name resolution service for the DDP infrastructure.

### Related Files

**Server 1 Ubuntu**
- `Config_Files/Server1_Ubuntu/etc/hostname`
- `Config_Files/Server1_Ubuntu/etc/hosts`
- `Config_Files/Server1_Ubuntu/etc/static_hosts`

**Client 1 Ubuntu**
- `Config_Files/Client1_Ubuntu/etc/hostname`
- `Config_Files/Client1_Ubuntu/etc/hosts`
- `Config_Files/Client1_Ubuntu/etc/static_hosts`

**Client 2 CentOS**
- `Config_Files/Client2_CentOS/etc/hostname`
- `Config_Files/Client2_CentOS/etc/hosts`
- `Config_Files/Client2_CentOS/etc/static_hosts`

### Evidence

**Server 1 Ubuntu**
- `Documentation/Screenshots/Server1_Ubuntu/static_hosts.png`

**Client 1 Ubuntu**
- `Documentation/Screenshots/Client1_Ubuntu/static_hosts.png`

**Client 2 CentOS**
- `Documentation/Screenshots/Client2_CentOS/static_hosts.png`

### Verification

Hostname configuration is verified with hostname and name-resolution checks. Each system should report the correct hostname and should resolve the other DDP machines by name.

---

## 4. Static Server Networking

### Purpose

Static networking gives `server1.ddp.is` a permanent internal address so all clients can reliably use it as their infrastructure server.

This is required because DHCP, DNS, NTP, Syslog, SSH, mail, CUPS, and backups all depend on the server having a stable IP address.

### Final Configuration

`server1.ddp.is` uses two interfaces:

| Interface | Purpose          | Configuration              |
| --------- | ---------------- | -------------------------- |
| `ens37`   | NAT/WAN access   | DHCP from VMware NAT       |
| `ens33`   | Internal DDP LAN | Static `192.168.100.10/24` |

The internal interface `ens33` is the service-facing interface for the DDP LAN.

The NAT/WAN interface `ens37` is used only for internet access, package downloads, and updates.

### Related Files

**Server 1 Ubuntu**
- `Config_Files/Server1_Ubuntu/etc/netplan/00-installer-config.yaml`
- `Config_Files/Server1_Ubuntu/etc/sysctl.conf`

### Evidence

**Server 1 Ubuntu**
- `Documentation/Screenshots/Server1_Ubuntu/static_netplan_00-installer-config.png`
- `Documentation/Screenshots/Server1_Ubuntu/static_network_validation.png`

### Verification

Static networking is verified by checking that `ens33` has `192.168.100.10/24`, that `ens37` has a NAT/WAN address from VMware, and that `server1` can reach both the internal clients and the internet.

---

## 5. Persistent Logging and Centralized Syslog

### Purpose

Logging is configured in two layers:

1. persistent local journal logging
2. centralized Syslog forwarding to `server1`

Persistent logging keeps service and system logs after reboot. Centralized Syslog allows `server1` to collect logs from the clients for monitoring and troubleshooting.

### Final Configuration

Persistent journald logging is enabled on `server1` so logs survive reboot.

Centralized rsyslog is configured as follows:

| Machine          | Role          | Configuration                         |
| ---------------- | ------------- | ------------------------------------- |
| `server1.ddp.is` | Syslog server | Receives remote logs on port 514      |
| `client1.ddp.is` | Syslog client | Forwards logs to `192.168.100.10:514` |
| `client2.ddp.is` | Syslog client | Forwards logs to `192.168.100.10:514` |

Remote logs are stored on `server1` under:

```text
/var/log/remote/
```

### Related Files

**Server 1 Ubuntu**
- `Config_Files/Server1_Ubuntu/etc/systemd/journald.conf`
- `Config_Files/Server1_Ubuntu/etc/rsyslog.d/10-ddp-server.conf`

**Client 1 Ubuntu**
- `Config_Files/Client1_Ubuntu/etc/rsyslog.d/10-ddp-client.conf`

**Client 2 CentOS**
- `Config_Files/Client2_CentOS/etc/rsyslog.d/10-ddp-client.conf`

### Evidence

**Server 1 Ubuntu**
- `Evidence/logs/journal_persistence_check.txt`
- `Evidence/logs/syslog_test_results.txt`
- `Evidence/service_status/rsyslog_status.txt`
- `Documentation/Screenshots/Server1_Ubuntu/journald_persistent.png`
- `Documentation/Screenshots/Server1_Ubuntu/rsyslog_server_status.png`
- `Documentation/Screenshots/Server1_Ubuntu/syslog_received.png`

**Client 1 Ubuntu**
- `Documentation/Screenshots/Client1_Ubuntu/syslog_test.png`

**Client 2 CentOS**
- `Documentation/Screenshots/Client2_CentOS/syslog_test.png`

### Verification

Persistent logging is verified by checking journal history after reboot. Centralized Syslog is verified by sending test log messages from both clients and confirming that the messages appear under `/var/log/remote/` on `server1`.

---

## 6. DHCP Configuration

### Purpose

DHCP is configured on `server1.ddp.is` to automatically provide network settings to the internal Linux clients.

The DHCP service gives clients:

- an IP address
- default gateway
- DNS server
- domain name

### Final Configuration

The DHCP server runs on `server1.ddp.is` and listens only on the internal LAN interface.

In this project:

| Setting                          | Value                               |
| -------------------------------- | ----------------------------------- |
| DHCP server                      | `server1.ddp.is`                    |
| DHCP interface                   | `ens33`                             |
| LAN subnet                       | `192.168.100.0/24`                  |
| DHCP range                       | `192.168.100.100 – 192.168.100.200` |
| DNS server given to clients      | `192.168.100.10`                    |
| Domain given to clients          | `ddp.is`                            |
| Default gateway given to clients | `192.168.100.10`                    |

Current successful DHCP leases:

| Client           | DHCP Lease        |
| ---------------- | ----------------- |
| `client1.ddp.is` | `192.168.100.100` |
| `client2.ddp.is` | `192.168.100.101` |

The client addresses are dynamic leases from the DHCP range. Earlier `.20` and `.30` addresses were only planning addresses and are not the final DHCP evidence state.

### Related Files

**Server 1 Ubuntu**
- `Config_Files/Server1_Ubuntu/etc/dhcp/dhcpd.conf`
- `Config_Files/Server1_Ubuntu/etc/default/isc-dhcp-server`

**Client 1 Ubuntu**
- `Config_Files/Client1_Ubuntu/etc/netplan/00-installer-config.yaml`

**Client 2 CentOS**
- `Config_Files/Client2_CentOS/etc/NetworkManager/system-connections/ens160.nmconnection`

### Evidence

**Server 1 Ubuntu**
- `Evidence/dhcp/dhcp_status.txt`
- `Evidence/dhcp/dhcpd.leases`
- `Documentation/Screenshots/Server1_Ubuntu/dhcpd_config.png`
- `Documentation/Screenshots/Server1_Ubuntu/dhcp_server_status.png`
- `Documentation/Screenshots/Server1_Ubuntu/dhcp_leases.png`

**Client 1 Ubuntu**
- `Evidence/dhcp/client1_lease.txt`
- `Documentation/Screenshots/Client1_Ubuntu/dhcp.png`

**Client 2 CentOS**
- `Evidence/dhcp/client2_lease.txt`
- `Documentation/Screenshots/Client2_CentOS/dhcp.png`

### Verification

The DHCP service was verified by checking the service status on `server1`, confirming active leases in the DHCP lease file, and confirming that both clients received addresses from the configured DHCP range.

---

## 7. DNS / BIND9 Configuration

### Purpose

DNS is configured with BIND9 on `server1.ddp.is` to provide name resolution for the `ddp.is` domain.

DNS allows machines and services to be reached by hostname instead of only by IP address.

The DNS service provides:

- forward lookup: hostname to IP address
- reverse lookup: IP address to hostname
- service names such as `mail.ddp.is`, `ntp.ddp.is`, `print.ddp.is`, and `syslog.ddp.is`

### Final Configuration

BIND9 is configured on `server1.ddp.is` as the authoritative DNS server for the internal DDP domain.

Planned/final zone design:

| Zone Type    | Zone Name                  | Purpose                                     |
| ------------ | -------------------------- | ------------------------------------------- |
| Forward zone | `ddp.is`                   | Resolves DDP hostnames to IP addresses      |
| Reverse zone | `100.168.192.in-addr.arpa` | Resolves DDP IP addresses back to hostnames |

Important DNS records:

| Name             | Type | Target            |
| ---------------- | ---- | ----------------- |
| `server1.ddp.is` | A    | `192.168.100.10`  |
| `client1.ddp.is` | A    | `192.168.100.100` |
| `client2.ddp.is` | A    | `192.168.100.101` |
| `mail.ddp.is`    | A    | `192.168.100.10`  |
| `ntp.ddp.is`     | A    | `192.168.100.10`  |
| `print.ddp.is`   | A    | `192.168.100.10`  |
| `syslog.ddp.is`  | A    | `192.168.100.10`  |

### Related Files

**Server 1 Ubuntu**
- `Config_Files/Server1_Ubuntu/etc/bind/named.conf.local`
- `Config_Files/Server1_Ubuntu/etc/bind/named.conf.options`
- `Config_Files/Server1_Ubuntu/etc/bind/db.ddp.is`
- `Config_Files/Server1_Ubuntu/etc/bind/db.192.168.100`

### Evidence

**Server 1 Ubuntu**
- `Evidence/dns/dig_forward_lookup.txt`
- `Evidence/dns/dig_reverse_lookup.txt`
- `Evidence/dns/named_checkzone_output.txt`
- `Documentation/Screenshots/Server1_Ubuntu/bind9_status.png`
- `Documentation/Screenshots/Server1_Ubuntu/dig_forward_lookup.png`
- `Documentation/Screenshots/Server1_Ubuntu/dig_reverse_lookup.png`

**Client 1 Ubuntu**
- `Documentation/Screenshots/Client1_Ubuntu/dns_resolution.png`

**Client 2 CentOS**
- `Documentation/Screenshots/Client2_CentOS/dns_resolution.png`

### Verification

DNS is verified by checking the BIND9 service status, validating the zone files, and running forward and reverse lookup tests. Client verification should prove that both clients use `server1` as DNS and can resolve `server1.ddp.is` through BIND9.

---

## 8. Time Synchronization / Chrony

### Purpose

Time synchronization keeps all machines using consistent system time.

This is important because logs, backups, authentication, mail, and security evidence all depend on accurate timestamps.

### Final Configuration

Chrony is used to provide NTP-style time synchronization.

`server1.ddp.is` acts as the internal time source for the DDP clients. The clients synchronize their clocks from `server1` over the private LAN.

Expected setup:

| Machine          | Time Role            | Time Source                      |
| ---------------- | -------------------- | -------------------------------- |
| `server1.ddp.is` | Internal time server | Public NTP pool / local fallback |
| `client1.ddp.is` | Time client          | `192.168.100.10`                 |
| `client2.ddp.is` | Time client          | `192.168.100.10`                 |

### Related Files

**Server 1 Ubuntu**
- `Config_Files/Server1_Ubuntu/etc/chrony/chrony.conf`

**Client 1 Ubuntu**
- `Config_Files/Client1_Ubuntu/etc/chrony/chrony.conf`

**Client 2 CentOS**
- `Config_Files/Client2_CentOS/etc/chrony.conf`

### Evidence

**Server 1 Ubuntu**
- `Evidence/service_status/chrony_status.txt`
- `Documentation/Screenshots/Server1_Ubuntu/chrony_status.png`
- `Documentation/Screenshots/Server1_Ubuntu/chrony_clients.png`

**Client 1 Ubuntu**
- `Documentation/Screenshots/Client1_Ubuntu/chrony.png`

**Client 2 CentOS**
- `Documentation/Screenshots/Client2_CentOS/chrony.png`

### Verification

Time synchronization is verified by checking Chrony service status and Chrony source/tracking output. The clients should show `server1` or `192.168.100.10` as their configured time source.

---

## 9. User and Group Automation

### Purpose

User and group automation creates DDP employee accounts from the provided user CSV file.

This avoids manually creating each user and proves that account creation can be repeated consistently.

### Final Configuration

A Bash script is used to read the provided CSV file and create:

- Linux user accounts
- home directories
- department groups
- group memberships

Expected department groups:

| Department Group   | Users | Linux Group Name   | Default Shell | Group Type    | Sudo Access | Force Password Change |
| ------------------ | ----- | ------------------ | ------------- | ------------- | ----------- | --------------------- |
| `Tolvudeild`       | 3     | `Tolvudeild`       | `/bin/bash`   | Supplementary | No          | Yes                   |
| `Rekstrardeild`    | 5     | `Rekstrardeild`    | `/bin/bash`   | Supplementary | No          | Yes                   |
| `Framkvaemdadeild` | 8     | `Framkvaemdadeild` | `/bin/bash`   | Supplementary | No          | Yes                   |
| `Framleidsludeild` | 13    | `Framleidsludeild` | `/bin/bash`   | Supplementary | No          | Yes                   |

The users are created with home directories under:

```text
/home/
```

The uploaded CSV contains 29 user entries plus the header. The assignment text says 30 employees, so this mismatch should be documented in the final report unless an updated CSV is provided.

### Related Files

**Server 1 Ubuntu**
- `Scripts/create_users.sh`
- `Scripts/Linux_Users.CSV`
- `Scripts/User_Creation_Logs/create_users.log`

### Evidence

**Server 1 Ubuntu**
- `Evidence/users/department_groups.txt`
- `Evidence/users/home_directory_listing.txt`
- `Evidence/users/user_list_verification.txt`

### Verification

User creation is verified by checking system user entries, department group entries, and created home directories. The evidence should prove that users from the CSV were created and assigned to their department groups.

---

## 10. SSH Hardening

### Purpose

SSH hardening improves remote access security.

The project requires SSH password authentication to be disabled and RSA key-based authentication to be enforced.

### Final Configuration

OpenSSH is configured on the systems so remote login uses public key authentication.

Expected SSH security settings:

| Setting                           | Final Value | Purpose                                       |
| --------------------------------- | ----------- | --------------------------------------------- |
| `PermitRootLogin`                 | `no`        | Prevent direct root login over SSH            |
| `PubkeyAuthentication`            | `yes`       | Allow SSH key authentication                  |
| `PasswordAuthentication`          | `no`        | Disable password-based SSH login              |
| `KbdInteractiveAuthentication`    | `no`        | Disable keyboard-interactive password prompts |
| `ChallengeResponseAuthentication` | `no`        | Disable challenge-response authentication     |

SSH password login should only be disabled after key-based login has been tested successfully.

### Related Files

**Server 1 Ubuntu**
- `Config_Files/Server1_Ubuntu/etc/ssh/sshd_config`
- `Scripts/system_hardening.sh`

**Client 1 Ubuntu**
- `Config_Files/Client1_Ubuntu/etc/ssh/ssh_config`

**Client 2 CentOS**
- `Config_Files/Client2_CentOS/etc/ssh/sshd_config`

### Evidence

**Server 1 Ubuntu**
- `Evidence/service_status/ssh_status.txt`
- `Documentation/Screenshots/Server1_Ubuntu/ssh_status.png`

**Client 1 Ubuntu**
- `Documentation/Screenshots/Client1_Ubuntu/ssh_key_login.png`

**Client 2 CentOS**
- `Documentation/Screenshots/Client2_CentOS/ssh_key_login.png`

### Verification

SSH hardening is verified by successfully logging in with an SSH key and confirming that password authentication is disabled in the SSH server configuration.

---

## 11. Postfix, Dovecot, and Roundcube Mail

### Purpose

Mail services provide internal email functionality for the DDP infrastructure.

Postfix handles mail transfer, Dovecot provides mailbox access, and Roundcube provides browser-based webmail access.

### Final Configuration

Mail services are hosted on `server1.ddp.is`.

Expected service roles:

| Service   | Purpose                                      |
| --------- | -------------------------------------------- |
| Postfix   | Sends and receives local mail                |
| Dovecot   | Provides IMAP mailbox access                 |
| Roundcube | Provides webmail interface through a browser |
| Apache    | Serves the Roundcube web interface           |

Expected mail identity:

```text
mail.ddp.is
```

Mail should be configured for the internal domain:

```text
ddp.is
```

### Related Files

**Server 1 Ubuntu**
- `Config_Files/Server1_Ubuntu/etc/postfix/main.cf`
- `Config_Files/Server1_Ubuntu/etc/dovecot/conf.d/10-mail.conf`

### Evidence

**Server 1 Ubuntu**
- `Evidence/service_status/postfix_status.txt`
- `Evidence/service_status/dovecot_status.txt`
- `Documentation/Screenshots/Server1_Ubuntu/postfix_status.png`
- `Documentation/Screenshots/Server1_Ubuntu/dovecot_status.png`
- `Documentation/Screenshots/Server1_Ubuntu/roundcube_login.png`

### Verification

Mail services are verified by checking service status for Postfix, Dovecot, and Apache/Roundcube. Additional verification should show a successful local mail test and access to the Roundcube web interface.

---

## 12. CUPS Printer Sharing

### Purpose

CUPS printer sharing provides shared printing for DDP users.

The project requires printer access to be controlled by department groups. IT and Management should have broader print/manage rights.

### Final Configuration

CUPS is hosted on `server1.ddp.is` and provides printer sharing on the internal LAN.

Expected printer access model:

| Group                           | Intended Access                   |
| ------------------------------- | --------------------------------- |
| Department users                | Print to their department printer |
| IT / `Tolvudeild`               | Print and manage rights           |
| Management / `Framkvaemdadeild` | Print and manage rights           |

Because this is a virtual lab, virtual or PDF printers can be used as evidence if physical printers are not available.

### Related Files

**Server 1 Ubuntu**
- `Config_Files/Server1_Ubuntu/etc/cups/cupsd.conf`

### Evidence

**Server 1 Ubuntu**
- `Evidence/service_status/cups_status.txt`
- `Documentation/Screenshots/Server1_Ubuntu/cups_status.png`
- `Documentation/Screenshots/Server1_Ubuntu/cups_web_interface.png`

### Verification

CUPS is verified by checking the CUPS service status, confirming available printers, accessing the CUPS web interface, and performing a test print or queue check.

---

## 13. Backup Automation

### Purpose

Backup automation protects user home directories and satisfies the requirement for weekly backups.

The project requires home directory backups to run every Friday at midnight.

### Final Configuration

A Bash backup script is used to create compressed backups of `/home`.

Expected backup source:

```text
/home
```

Expected backup destination:

```text
/backup/ddp-home
```

Expected schedule:

```text
Every Friday at 00:00
```

Cron schedule:

```text
0 0 * * 5
```

### Related Files

**Server 1 Ubuntu**
- `Scripts/backup_home.sh`
- root crontab or relevant cron configuration

### Evidence

**Server 1 Ubuntu**
- `Evidence/logs/backup_log.txt`
- `Documentation/Screenshots/Server1_Ubuntu/backup_script_execution.png`
- `Documentation/Screenshots/Server1_Ubuntu/cron_schedule.png`

### Verification

Backup automation is verified by running the backup script manually, confirming that a compressed backup file is created, and showing the scheduled cron entry for Friday at midnight.

---

## 14. Firewall Hardening

### Purpose

Firewall hardening closes unused ports and allows only the services required for the DDP infrastructure.

This reduces unnecessary network exposure and supports the final Nmap verification requirement.

### Final Configuration

`server1.ddp.is` should allow only required internal infrastructure services.

Expected server services and ports:

| Service          | Port | Protocol |
| ---------------- | ---: | -------- |
| SSH              |   22 | TCP      |
| DNS              |   53 | TCP/UDP  |
| DHCP             |   67 | UDP      |
| HTTP / Roundcube |   80 | TCP      |
| SMTP / Postfix   |   25 | TCP      |
| IMAP / Dovecot   |  143 | TCP      |
| Syslog           |  514 | TCP/UDP  |
| CUPS             |  631 | TCP      |
| NTP / Chrony     |  123 | UDP      |

Ubuntu uses UFW for firewall rules. CentOS uses firewalld.

### Related Files

**Server 1 Ubuntu**
- `Config_Files/Server1_Ubuntu/etc/ufw/user.rules`
- `Scripts/system_hardening.sh`

**Client 2 CentOS**
- `Config_Files/Client2_CentOS/etc/firewalld/zones/public.xml`

### Evidence

**Server 1 Ubuntu**
- `Evidence/firewall/ufw_status.txt`
- `Evidence/firewall/listening_ports.txt`
- `Documentation/Screenshots/Server1_Ubuntu/ufw_status.png`

**Client 2 CentOS**
- `Evidence/firewall/firewalld_status.txt`

### Verification

Firewall hardening is verified by checking firewall status, checking listening ports, and running Nmap scans from a client machine.

---

## 15. Nmap and Final Service Verification

### Purpose

Nmap verification proves which ports are open after service configuration and firewall hardening.

This confirms that required services are reachable and unused ports are closed.

### Final Configuration

Nmap scans are run against:

| Target            | Purpose                           |
| ----------------- | --------------------------------- |
| `192.168.100.10`  | Verify open services on `server1` |
| `192.168.100.100` | Verify exposed ports on `client1` |
| `192.168.100.101` | Verify exposed ports on `client2` |

Expected scan files:

- basic scan for `server1`
- final scan for `server1`
- UDP top ports scan for `server1`
- basic scan for `client1`
- basic scan for `client2`

### Related Files

**Server 1 Ubuntu**
- `Evidence/nmap_scans/server1-basic-scan.txt`
- `Evidence/nmap_scans/server1-final-scan.txt`
- `Evidence/nmap_scans/server1-udp-top20-scan.txt`

**Client 1 Ubuntu**
- `Evidence/nmap_scans/client1-basic-scan.txt`

**Client 2 CentOS**
- `Evidence/nmap_scans/client2-basic-scan.txt`

### Evidence

**Server 1 Ubuntu**
- `Documentation/Screenshots/Server1_Ubuntu/final_validation.png`

**Client 1 Ubuntu**
- `Documentation/Screenshots/Client1_Ubuntu/final_validation.png`

**Client 2 CentOS**
- `Documentation/Screenshots/Client2_CentOS/final_validation.png`

**Shared / Project Files**
- `Evidence/nmap_scans/`
- `Evidence/firewall/listening_ports.txt`

### Verification

Final verification is complete when Nmap output matches the intended firewall and service design. Required services should be visible, and unnecessary services should not be exposed.

---

## 16. Repository Evidence Structure

### Purpose

The repository structure organizes all configuration files, scripts, screenshots, and command evidence in a clean format for final submission.

This makes the project easier to review and proves that every requirement has supporting evidence.

### Final Configuration

The repository is organized into these main folders:

| Folder           | Purpose                                                       |
| ---------------- | ------------------------------------------------------------- |
| `Config_Files/`  | Copies of service and system configuration files              |
| `Documentation/` | Main documentation, screenshots, diagrams, and reports        |
| `Evidence/`      | Command outputs, service status files, logs, and scans        |
| `Scripts/`       | Automation scripts for users, backups, hardening, and testing |

The configuration files are grouped by machine and then mirror the original Linux filesystem paths.

### Related Files

**Server 1 Ubuntu**
- None specific for this chapter.

**Client 1 Ubuntu**
- None specific for this chapter.

**Client 2 CentOS**
- None specific for this chapter.

**Shared / Project Files**
- `README.md`
- `Documentation/Configuration_Guide.md`
- `Documentation/Project_Report.pdf`
- `Documentation/Network_Infrastructure.png`

### Evidence

**Server 1 Ubuntu**
- None specific for this chapter.

**Client 1 Ubuntu**
- None specific for this chapter.

**Client 2 CentOS**
- None specific for this chapter.

**Shared / Project Files**
- `Config_Files/`
- `Documentation/Screenshots/`
- `Evidence/`
- `Scripts/`

### Verification

The repository structure is verified by checking that the final GitHub repository contains the required documentation, scripts, configuration files, screenshots, and evidence files.

---

# Final Notes

This configuration guide explains how each major infrastructure component is configured in the DDP Linux Infrastructure Project.

Configuration file contents are not duplicated in full inside this document because the actual files are stored separately in the `Config_Files/` folder. Scripts are also stored separately in the `Scripts/` folder. This keeps the guide readable while still pointing clearly to the technical implementation and evidence.
