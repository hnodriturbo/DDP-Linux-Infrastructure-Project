# DDP Linux Infrastructure Project

![Network Infrastructure](Documentation/Network_Infrastructure.png)

---

This project was created for the course **KEST3NL05EU – Linux Netstjórnun**.

The goal of the project is to build a small Linux infrastructure for a company called **DDP ehf.** using one central server and two Linux clients.

The infrastructure includes:
- DHCP server
- DNS server
- NTP time synchronization
- Centralized Syslog logging
- SSH hardening
- Postfix mail server
- Roundcube webmail
- CUPS printer sharing
- Automated backups
- Firewall hardening
- User automation scripts

---

## Important Notes

- `.txt` files are used for evidence/log outputs to improve GitHub readability and quick access to file contents.

---

# Network Overview

### Basic text overview of network structure:

```text
                           INTERNET
                               │
                        ens33 (NAT/WAN)
                               │
                            server1
                               │
                     ens34 (LAN/Internal)
                               │
              ┌────────────────┼────────────────┐
              │                                 │
       client1.ddp.is                   client2.ddp.is
       192.168.100.100                  192.168.100.101
```

### Table overview of the network structure:
| Device         | Role           | IP Address      |
| -------------- | -------------- | --------------- |
| server1.ddp.is | Main Server    | 192.168.100.10  |
| client1.ddp.is | Debian Client  | 192.168.100.100 |
| client2.ddp.is | Red Hat Client | 192.168.100.101 |

---

# Full Project Structure

```text
/DDP-Linux-Infrastructure-Project/
├── README.md
│
├── Config_Files/
│   ├── Client1_Ubuntu/
│   │   └── etc/
│   │       ├── chrony/
│   │       │   └── chrony.conf ✅
│   │       ├── netplan/
│   │       │   └── 00-installer-config.yaml  ✅
│   │       ├── rsyslog.d/
│   │       │   └── 10-ddp-client.conf  ✅
│   │       ├── ssh/
│   │       │   └── ssh_config
│   │       ├── hostname  ✅
│   │       ├── hosts ✅
│   │       └── static_hosts  ✅
│   │
│   ├── Client2_CentOS/
│   │   └── etc/
│   │       ├── firewalld/
│   │       │   └── zones/
│   │       │       └── public.xml
│   │       ├── NetworkManager/
│   │       │   └── system-connections/
│   │       │       └── ens160.nmconnection ✅
│   │       ├── rsyslog.d/
│   │       │   └── 10-ddp-client.conf  ✅
│   │       ├── ssh/
│   │       │   └── sshd_config
│   │       ├── sysconfig/
│   │       │   └── network-scripts/
│   │       │       └── ifcfg-ens160 ✅
│   │       ├── chrony.conf ✅
│   │       ├── hostname  ✅
│   │       ├── hosts ✅
│   │       └── static_hosts  ✅
│   │
│   └── Server1_Ubuntu/
│       └── etc/
│           ├── bind/
│           │   ├── db.192.168.100
│           │   ├── db.ddp.is
│           │   ├── named.conf.local
│           │   └── named.conf.options
│           ├── chrony/
│           │   └── chrony.conf ✅
│           ├── cups/
│           │   └── cupsd.conf
│           ├── default/
│           │   └── isc-dhcp-server ✅
│           ├── dhcp/
│           │   └── dhcpd.conf  ✅
│           ├── dovecot/
│           │   └── conf.d/
│           │       └── 10-mail.conf
│           ├── netplan/
│           │   └── 00-installer-config.yaml  ✅
│           ├── postfix/
│           │   └── main.cf
│           ├── rsyslog.d/
│           │   └── 10-ddp-server.conf  ✅
│           ├── ssh/
│           │   └── sshd_config
│           ├── systemd/
│           │   └── journald.conf ✅
│           ├── ufw/
│           │   └── user.rules
│           ├── hostname  ✅
│           ├── hosts ✅
│           ├── static_hosts  ✅
│           └── sysctl.conf ✅
│
├── Documentation/
│   ├── Screenshots/
│   │   ├── Client1_Ubuntu/
│   │   │   ├── chrony.png  ✅
│   │   │   ├── dhcp.png  ✅
│   │   │   ├── dns_resolution.png  ✅
│   │   │   ├── final_validation.png
│   │   │   ├── static_hosts.png  ✅
│   │   │   ├── static_netplan_00-installer-config.png  ✅
│   │   │   ├── ssh_key_login.png
│   │   │   ├── static_network_validation.png ✅
│   │   │   └── syslog_test.png ✅
│   │   │
│   │   ├── Client2_CentOS/
│   │   │   ├── chrony.png  ✅
│   │   │   ├── dhcp.png  ✅
│   │   │   ├── dns_resolution.png  ✅
│   │   │   ├── final_validation.png
│   │   │   ├── static_hosts.png  ✅
│   │   │   ├── nmtui_static.png  ✅
│   │   │   ├── ssh_key_login.png
│   │   │   ├── static_network_validation.png ✅
│   │   │   └── syslog_test.png ✅
│   │   │
│   │   └── Server1_Ubuntu/
│   │       ├── bind9_status.png  ✅
│   │       ├── chrony_status.png ✅
│   │       ├── chrony_clients.png ✅
│   │       ├── cron_schedule.png ✅
│   │       ├── cups_status.png
│   │       ├── cups_web_interface.png
│   │       ├── dhcpd_config.png  ✅
│   │       ├── dhcp_leases.png ✅
│   │       ├── dhcp_server_status.png  ✅
│   │       ├── dig_forward_lookup.png  ✅
│   │       ├── dig_reverse_lookup.png  ✅
│   │       ├── dovecot_status_&_postfix_status.png ✅
│   │       ├── final_validation.png
│   │       ├── static_hosts.png  ✅
│   │       ├── journald_persistent.png ✅
│   │       ├── static_netplan_00-installer-config.png  ✅
│   │       ├── roundcube_login.png
│   │       ├── rsyslog_server_status.png ✅
│   │       ├── ssh_status.png
│   │       ├── static_network_validation.png ✅
│   │       ├── syslog_received.png           ✅
│   │       ├── ufw_status.png
│   │       └── user_list_verification.png  ✅
│   │
│   ├── Configuration_Guide.md  ✅
│   ├── Network_Infrastructure.png  ✅
│   ├── Network_Structure_Basic_Text_Diagram.md ✅
│   └── Project_Report.pdf  ✅ (half way through)
│
├── Evidence/
│   ├── dhcp/
│   │   ├── client1_lease.txt ✅
│   │   ├── client2_lease.txt ✅
│   │   ├── dhcp_status.txt ✅
│   │   └── dhcpd.leases  ✅
│   │
│   ├── dns/
│   │   ├── dig_forward_lookup.txt  ✅
│   │   ├── dig_reverse_lookup.txt  ✅
│   │   └── named_checkzone_output.txt  ✅
│   │
│   ├── firewall/
│   │   ├── firewalld_status.txt
│   │   ├── listening_ports.txt
│   │   └── ufw_status.txt
│   │
│   ├── logs/
│   │   ├── backup_log.txt  ✅
│   │   ├── journal_persistence_check.txt
│   │   └── syslog_test_results.txt
│   │
│   ├── nmap_scans/
│   │   ├── client1-basic-scan.txt
│   │   ├── client2-basic-scan.txt
│   │   ├── server1-basic-scan.txt
│   │   ├── server1-final-scan.txt
│   │   └── server1-udp-top20-scan.txt
│   │
│   ├── service_status/
│   │   ├── bind9_status.txt  ✅
│   │   ├── chrony_status.txt ✅
│   │   ├── cups_status.txt
│   │   ├── dhcp_status.txt ✅
│   │   ├── dovecot_status_&_postfix_status.txt ✅
│   │   ├── rsyslog_status.txt  ✅
│   │   └── ssh_status.txt
│   │
│   └── users/
│       ├── department_groups.txt ✅
│       ├── home_directory_listing.txt  ✅
│       └── user_list_verification.txt  ✅
│
└── Scripts/
    ├── Testing/
    │   ├── test_backup.sh
    │   ├── test_mail.sh
    │   └── test_syslog.sh
    │
    ├── User_Creation_Logs/
    │   └── create_users.log  ✅
    │
    ├── backup_home.sh
    ├── create_users.sh ✅
    ├── Linux_Users.CSV ✅
    └── system_hardening.sh
```

---

# Project Files — Order of Completion

Files grouped in the order each phase was configured during the project.

```text
Phase 1 — Project Environment & Network Architecture
├── Documentation/Network_Infrastructure.png
├── Documentation/Network_Structure_Basic_Text_Diagram.md
└── README.md

Phase 2 — Hostnames and Domain Identity
├── Config_Files/Server1_Ubuntu/etc/hostname
├── Config_Files/Server1_Ubuntu/etc/hosts
├── Config_Files/Server1_Ubuntu/etc/static_hosts
├── Config_Files/Client1_Ubuntu/etc/hostname
├── Config_Files/Client1_Ubuntu/etc/hosts
├── Config_Files/Client1_Ubuntu/etc/static_hosts
├── Config_Files/Client2_CentOS/etc/hostname
├── Config_Files/Client2_CentOS/etc/hosts
└── Config_Files/Client2_CentOS/etc/static_hosts

Phase 3 — Static Server Networking
├── Config_Files/Server1_Ubuntu/etc/netplan/00-installer-config.yaml
├── Config_Files/Server1_Ubuntu/etc/sysctl.conf
└── Documentation/Screenshots/Server1_Ubuntu/static_network_validation.png

Phase 4 — Persistent Logging and Centralized Syslog
├── Config_Files/Server1_Ubuntu/etc/systemd/journald.conf
├── Config_Files/Server1_Ubuntu/etc/rsyslog.d/10-ddp-server.conf
├── Config_Files/Client1_Ubuntu/etc/rsyslog.d/10-ddp-client.conf
├── Config_Files/Client2_CentOS/etc/rsyslog.d/10-ddp-client.conf
├── Evidence/logs/journal_persistence_check.txt
├── Evidence/logs/syslog_test_results.txt
└── Evidence/service_status/rsyslog_status.txt

Phase 5 — DHCP Configuration
├── Config_Files/Server1_Ubuntu/etc/dhcp/dhcpd.conf
├── Config_Files/Server1_Ubuntu/etc/default/isc-dhcp-server
├── Config_Files/Client1_Ubuntu/etc/netplan/00-installer-config.yaml
├── Config_Files/Client2_CentOS/etc/NetworkManager/system-connections/ens160.nmconnection
├── Config_Files/Client2_CentOS/etc/sysconfig/network-scripts/ifcfg-ens160
├── Evidence/dhcp/dhcp_status.txt
├── Evidence/dhcp/dhcpd.leases
├── Evidence/dhcp/client1_lease.txt
└── Evidence/dhcp/client2_lease.txt

Phase 6 — DNS / BIND9 Configuration
├── Config_Files/Server1_Ubuntu/etc/bind/named.conf.local
├── Config_Files/Server1_Ubuntu/etc/bind/named.conf.options
├── Config_Files/Server1_Ubuntu/etc/bind/db.ddp.is
├── Config_Files/Server1_Ubuntu/etc/bind/db.192.168.100
├── Evidence/dns/dig_forward_lookup.txt
├── Evidence/dns/dig_reverse_lookup.txt
└── Evidence/dns/named_checkzone_output.txt

Phase 7 — Time Synchronization / Chrony
├── Config_Files/Server1_Ubuntu/etc/chrony/chrony.conf
├── Config_Files/Client1_Ubuntu/etc/chrony/chrony.conf
├── Config_Files/Client2_CentOS/etc/chrony.conf
└── Evidence/service_status/chrony_status.txt

Phase 8 — User and Group Automation
├── Scripts/Linux_Users.CSV
├── Scripts/create_users.sh
├── Scripts/User_Creation_Logs/create_users.log
├── Evidence/users/department_groups.txt
├── Evidence/users/home_directory_listing.txt
└── Evidence/users/user_list_verification.txt

Phase 9 — SSH Hardening
├── Config_Files/Server1_Ubuntu/etc/ssh/sshd_config
├── Config_Files/Client1_Ubuntu/etc/ssh/ssh_config
├── Config_Files/Client2_CentOS/etc/ssh/sshd_config
├── Scripts/system_hardening.sh
└── Evidence/service_status/ssh_status.txt

Phase 10 — Postfix, Dovecot, and Roundcube Mail
├── Config_Files/Server1_Ubuntu/etc/postfix/main.cf
├── Config_Files/Server1_Ubuntu/etc/dovecot/conf.d/10-mail.conf
├── Evidence/service_status/postfix_status.txt
└── Evidence/service_status/dovecot_status.txt

Phase 11 — CUPS Printer Sharing
├── Config_Files/Server1_Ubuntu/etc/cups/cupsd.conf
└── Evidence/service_status/cups_status.txt

Phase 12 — Backup Automation
├── Scripts/backup_home.sh
├── Scripts/Testing/test_backup.sh
└── Evidence/logs/backup_log.txt

Phase 13 — Firewall Hardening
├── Config_Files/Server1_Ubuntu/etc/ufw/user.rules
├── Config_Files/Client2_CentOS/etc/firewalld/zones/public.xml
├── Evidence/firewall/ufw_status.txt
├── Evidence/firewall/firewalld_status.txt
└── Evidence/firewall/listening_ports.txt

Phase 14 — Nmap and Final Verification
├── Evidence/nmap_scans/server1-basic-scan.txt
├── Evidence/nmap_scans/server1-final-scan.txt
├── Evidence/nmap_scans/server1-udp-top20-scan.txt
├── Evidence/nmap_scans/client1-basic-scan.txt
└── Evidence/nmap_scans/client2-basic-scan.txt
```

---

# Technologies & Services Used

- Ubuntu Server
- Debian Linux
- Red Hat Linux
- Bash scripting
- ISC DHCP
- BIND9
- rsyslog
- Postfix
- Roundcube
- OpenSSH
- CUPS

---

# Author

Hreiðar Pétursson

