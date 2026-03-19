# FortiGate SNMP — OID Quick Reference

Quick reference for OIDs used in this deployment. All FortiGate-specific OIDs are under the Fortinet enterprise branch: `1.3.6.1.4.1.12356`.

For full context on how these are used in Zabbix, see `docs/setup/fortigate-snmp-setup.md`.

---

## Standard SNMP (All Devices)

| Item | OID |
|---|---|
| System description | `1.3.6.1.2.1.1.1.0` |
| System uptime | `1.3.6.1.2.1.1.3.0` |
| System name | `1.3.6.1.2.1.1.5.0` |
| Interface name | `1.3.6.1.2.1.2.2.1.2.<index>` |
| Interface admin status | `1.3.6.1.2.1.2.2.1.7.<index>` |
| Interface oper status | `1.3.6.1.2.1.2.2.1.8.<index>` |
| Interface in bytes | `1.3.6.1.2.1.2.2.1.10.<index>` |
| Interface out bytes | `1.3.6.1.2.1.2.2.1.16.<index>` |

---

## FortiGate System

| Item | OID |
|---|---|
| FortiOS version | `1.3.6.1.4.1.12356.101.4.1.1.0` |
| Serial number | `1.3.6.1.4.1.12356.101.4.1.2.0` |
| CPU usage (%) | `1.3.6.1.4.1.12356.101.4.1.3.0` |
| Memory usage (%) | `1.3.6.1.4.1.12356.101.4.1.4.0` |
| HA member state | `1.3.6.1.4.1.12356.101.13.2.1.11` |

---

## Hardware Sensors

| Item | OID |
|---|---|
| Sensor name | `1.3.6.1.4.1.12356.101.13.2.1.2.<index>` |
| Sensor value | `1.3.6.1.4.1.12356.101.13.2.1.3.<index>` |
| Sensor type | `1.3.6.1.4.1.12356.101.13.2.1.4.<index>` |
| Sensor alarm state | `1.3.6.1.4.1.12356.101.13.2.1.5.<index>` |

**Sensor type values:**

| Value | Type |
|---|---|
| `1` | Fan (RPM) |
| `2` | Temperature (°C) |
| `3` | Voltage |
| `4` | Power supply |

Walk to discover all sensors and their indexes:
```bash
snmpwalk -v2c -c <community> <firewall-ip> 1.3.6.1.4.1.12356.101.13.2.1
```

> Indexes differ between models. Always walk before configuring items — don't copy indexes from another device.

---

## VPN Tunnels

Base table: `1.3.6.1.4.1.12356.101.12.2.2.1`

| Item | OID |
|---|---|
| Tunnel name | `...12.2.2.1.3.<index>` |
| Local proxy ID | `...12.2.2.1.7.<index>` |
| Remote proxy ID | `...12.2.2.1.8.<index>` |
| Tunnel status | `...12.2.2.1.20.<index>` |
| Incoming bytes | `...12.2.2.1.12.<index>` |
| Outgoing bytes | `...12.2.2.1.13.<index>` |

**Tunnel status values:**

| Value | State |
|---|---|
| `1` | Up |
| `2` | Down |

Walk to get tunnel names and indexes:
```bash
snmpwalk -v2c -c <community> <firewall-ip> 1.3.6.1.4.1.12356.101.12.2.2.1.3
```

---

## WiFi / SSID Status

SSIDs appear as entries in the standard `ifTable`. Use interface name to identify the right index.

| Item | OID |
|---|---|
| Interface/SSID name | `1.3.6.1.2.1.2.2.1.2.<index>` |
| Oper status | `1.3.6.1.2.1.2.2.1.8.<index>` |

Walk to find SSID indexes:
```bash
# Standard walk
snmpwalk -v2c -c <community> <firewall-ip> 1.3.6.1.2.1.2.2.1.2

# Over VPN — use -Cr5 to avoid fragmentation
snmpbulkwalk -v2c -c <community> -Cr5 <firewall-ip> 1.3.6.1.2.1.2.2.1.2
```

---

## Useful Walk Commands

```bash
# Check basic connectivity
snmpwalk -v2c -c <community> <firewall-ip> sysDescr

# Full Fortinet MIB walk
snmpwalk -v2c -c <community> <firewall-ip> 1.3.6.1.4.1.12356

# Walk over VPN (limit bulk rows)
snmpbulkwalk -v2c -c <community> -Cr5 <firewall-ip> 1.3.6.1.4.1.12356

# Get a single OID value
snmpget -v2c -c <community> <firewall-ip> 1.3.6.1.4.1.12356.101.4.1.3.0
```
