# Ubuntu Black Screen & Interface Recovery Guide

> Use this file when VMware Ubuntu boots to a black screen or network interfaces appear DOWN after reboot.

---

# 1. Problem Types

Common problems seen in this project:

- Ubuntu black screen after login.
- Ubuntu greeter appears but desktop stays black after login.
- Interface shows DOWN after reboot.
- DHCP lease does not appear immediately after boot.
- `networkd-wait-online` failure during boot.

These issues are usually VMware/guest startup timing problems, not lost configuration.

Your files remain saved:

```text
/etc/netplan/00-installer-config.yaml
/etc/dhcp/dhcpd.conf
/etc/default/isc-dhcp-server
/etc/rsyslog.d/10-ddp-server.conf
/etc/rsyslog.d/10-ddp-client.conf
/etc/systemd/journald.conf
/etc/hosts
/etc/hostname
```

---

# 2. Black Screen Recovery

## Step 1 — Switch to TTY

Press:

```text
CTRL + ALT + F3
```

Login with your Linux username and password.

---

## Step 2 — Restart GDM

```bash
sudo systemctl restart gdm3
```

Purpose:
- Restarts GNOME Display Manager.
- Usually restores the graphical login screen.

---

## Step 3 — Restart display manager if needed

```bash
sudo systemctl restart display-manager
```

Purpose:
- Generic display manager restart command.
- Use if `gdm3` restart alone does not fully fix the session.

---

## Step 4 — Login again

Return to the graphical login and sign in again.

If black screen continues:
- reboot the VM once
- start server1 before clients
- wait 20–30 seconds before starting clients

---

# 3. Interface Recovery — server1

Current server1 interface mapping:

| Interface | Purpose |
|---|---|
| ens37 | NAT/WAN |
| ens33 | Internal LAN |

Bring both interfaces up:

```bash
sudo ip link set ens37 up
sudo ip link set ens33 up
```

Apply Netplan:

```bash
sudo netplan apply
```

Verify:

```bash
ip -br addr
```

Expected internal address:

```text
ens33  ...  192.168.100.10/24
```

Expected NAT/WAN:

```text
ens37  ...  VMware NAT DHCP address
```

---

# 4. Interface Recovery — client1 Ubuntu

Current client1 interface:

| Interface | Purpose |
|---|---|
| ens33 | Internal LAN DHCP |

Bring interface up:

```bash
sudo ip link set ens33 up
```

Apply Netplan:

```bash
sudo netplan apply
```

Verify:

```bash
ip -br addr
```

Expected lease:

```text
ens33 ... 192.168.100.100/24
```

If it does not lease immediately, wait a few seconds and run:

```bash
ip -br addr
ip route
resolvectl status
```

---

# 5. Interface Recovery — client2 CentOS

Current client2 interface:

| Interface | Purpose |
|---|---|
| ens160 | Internal LAN DHCP |

Restart NetworkManager:

```bash
sudo systemctl restart NetworkManager
```

Verify:

```bash
ip -br addr
ip route
cat /etc/resolv.conf
```

Expected lease:

```text
ens160 ... 192.168.100.101/24
```

---

# 6. DHCP Server Verification After Reboot

On server1:

```bash
systemctl status isc-dhcp-server --no-pager
```

Expected:

```text
Active: active (running)
```

Check lease file:

```bash
sudo cat /var/lib/dhcp/dhcpd.leases
```

Expected active leases:

```text
lease 192.168.100.100
lease 192.168.100.101
```

Watch live DHCP events:

```bash
sudo journalctl -fu isc-dhcp-server
```

Expected event types:

```text
DHCPDISCOVER
DHCPOFFER
DHCPREQUEST
DHCPACK
```

---

# 7. Recommended Boot Order

Use this boot order to avoid DHCP/network timing problems:

1. Start `server1`.
2. Wait 20–30 seconds.
3. Start `client1`.
4. Start `client2`.

Why:
- DHCP server starts before clients request leases.
- Syslog server starts before clients send logs.
- DNS will be ready first after BIND9 is configured.

---

# 8. Quick Recovery Checklist

Run on server1:

```bash
sudo ip link set ens37 up
sudo ip link set ens33 up
sudo netplan apply
ip -br addr
systemctl status isc-dhcp-server --no-pager
```

Run on client1:

```bash
sudo ip link set ens33 up
sudo netplan apply
ip -br addr
ip route
resolvectl status
```

Run on client2:

```bash
sudo systemctl restart NetworkManager
ip -br addr
ip route
cat /etc/resolv.conf
```

---

# 9. When NOT To Panic

Do not assume work is lost if:

- interface says DOWN
- DHCP lease takes a few seconds
- `networkd-wait-online` failed
- Ubuntu black screen appears

These usually do not erase files or configs. They are startup/display/network timing issues.
