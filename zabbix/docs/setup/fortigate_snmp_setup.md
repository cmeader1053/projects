# FortiGate SNMP — Configuration & Zabbix Setup

This document covers enabling SNMPv2 and disabling SNMPv1 on FortiGate firewalls. This document also walks through setting up Zabbix to begin to monitor those hosts

---

## Prerequisites
1. ssh or GUI access to firewalls/devices
2. Permissions to set configurations on firewalls (either from GUI or CLI)
3. ssh access to Zabbix server

---

## 1. Enable SNMP on FortiGate

### Via GUI

System > SNMP > SNMPv2 (or SNMPv3) > Create New

| Field | Value |
|---|---|
| Community Name | `<your-snmp-community>` |
| Hosts | `<zabbix-server-ip>` |
| Queries | Enable on port `161` |
| Traps | Optional — enable if using trap-based alerting |

> Restrict the allowed hosts to your Zabbix server IP only. Don't leave it open to `0.0.0.0`.

### Via CLI

```bash
config system snmp community
    edit 1
        set name "<your-community-string>"
        config hosts
            edit 1
                set ip <zabbix-server-ip>/32
            next
        end
        set query-v1-status disable
	    	set trap-v1-status disable
        set events cpu-high mem-low, ...... # Include all events you wish monitor for the host
    next
end

config system snmp sysinfo
    set status enable
    set description "<device-description>"
    set location "<site-name>"
    set append-index enable
end
```

---

## 2. Verify SNMP from the Zabbix Server

Before building anything in Zabbix, confirm SNMP is reachable from the monitoring server. SSH to the Zabbix server and run the following commands:

```bash
# Basic connectivity check
snmpwalk -v2c -c <community-string> <firewall-ip> sysDescr

# Walk the full FortiGate MIB
snmpwalk -v2c -c <community-string> <firewall-ip> 1.3.6.1.4.1.12356

# For devices behind a VPN — limit bulk rows to avoid fragmentation
snmpbulkwalk -v2c -c <community-string> -Cr5 <firewall-ip> 1.3.6.1.4.1.12356
```

> If walking over a VPN tunnel and getting incomplete results or timeouts, the `-Cr5` flag limits the rows per bulk request and usually resolves fragmentation-related issues.

---
## 3. Add the Host in Zabbix

> Note that these steps could differ depending on the version of Zabbix that you are running. In this project, version 7.4 was installed.

Data Collection > Hosts > Create Host

| Field | Value |
|---|---|
| Host Name | `<device-hostname>` |
| Visible Name | `<friendly-name>` |
| Groups | *(assign to appropriate host group)* | 
| Interfaces | SNMP — IP: `<firewall-ip>`, Port: `161` |

Under the **SNMP interface**, set:

| Field | Value |
|---|---|
| SNMP Version | SNMPv2 |
| Community | `{$SNMP_COMMUNITY}` (use a macro) |
| Bulk Requests | Enabled (disable if over VPN and experiencing issues) |

### Using a Macro for the Community String

Define the community string as a macro at the host or global level rather than hardcoding it:

Administration > Macros

| Macro | Value |
|---|---|
| `{$SNMP_COMMUNITY}` | `<your-community-string>` |

This makes it easy to update without touching every host individually.

---

## 4. Import the FortiGate SNMP Template

Zabbix's template library includes FortiGate templates. Import the appropriate one for your firmware version and link it to the host.

Data Collection > Templates > Import (upload the `.xml` file)

Then link it to the host:

Data Collection > Hosts > *select host* > Templates > Link new template

> OID indexes vary between FortiGate models — even within the same product family. After linking the template, do a live SNMP walk on the device and verify that the indexes in the template items match what the device is actually reporting. Items returning "no data" are almost always an index mismatch.

---

## 5. Monitored Items — OID Reference

### Hardware Sensors

These OIDs are under the Fortinet enterprise MIB (`1.3.6.1.4.1.12356`). Index numbers vary by model — always walk first.

| Item | OID (base) |
|---|---|
| CPU usage | `1.3.6.1.4.1.12356.101.4.1.3` |
| Memory usage | `1.3.6.1.4.1.12356.101.4.1.4` |
| Sensor name | `1.3.6.1.4.1.12356.101.13.2.1.2` |
| Sensor value | `1.3.6.1.4.1.12356.101.13.2.1.3` |
| Sensor type | `1.3.6.1.4.1.12356.101.13.2.1.4` |

Sensor types returned by the type OID:

| Value | Type |
|---|---|
| `1` | Fan (RPM) |
| `2` | Temperature |
| `3` | Voltage |
| `4` | Power supply |

Walk the sensor table to get the indexes for a specific device:

```bash
snmpwalk -v2c -c <community> <firewall-ip> 1.3.6.1.4.1.12356.101.13.2.1
```

---

### VPN Tunnel Status

| Item | OID |
|---|---|
| Tunnel name | `1.3.6.1.4.1.12356.101.12.2.2.1.3` |
| Tunnel status | `1.3.6.1.4.1.12356.101.12.2.2.1.20` |
| Incoming bytes | `1.3.6.1.4.1.12356.101.12.2.2.1.12` |
| Outgoing bytes | `1.3.6.1.4.1.12356.101.12.2.2.1.13` |

The tunnel status OID returns a numeric value. Configure a **Value Map** in Zabbix to make it readable:

| Value | Label |
|---|---|
| `1` | Up |
| `2` | Down |

Walk to get current tunnel indexes:

```bash
snmpwalk -v2c -c <community> <firewall-ip> 1.3.6.1.4.1.12356.101.12.2.2.1.3
```

> **Ghost proxy ID issue:** If you're seeing continuous tunnel renegotiations in the logs (and possibly false-positive alerts), the likely cause is an extra phase 2 proxy ID with an overly broad subnet selector (e.g., `192.168.0.0/16`). The tunnel isn't actually down — it's constantly trying to negotiate a child SA it doesn't need. Check the phase 2 selectors on both ends before assuming a tunnel problem.

---

### WiFi SSID Status

SSID operational status is pulled via `ifTable` — SSIDs appear as interfaces on the firewall.

| Item | OID |
|---|---|
| Interface name | `1.3.6.1.2.1.2.2.1.2` |
| Operational status | `1.3.6.1.2.1.2.2.1.8` |
| Admin status | `1.3.6.1.2.1.2.2.1.7` |

Operational status values:

| Value | Meaning |
|---|---|
| `1` | Up |
| `2` | Down |
| `3` | Testing |

Walk the interface table to find SSID indexes:

```bash
snmpwalk -v2c -c <community> <firewall-ip> 1.3.6.1.2.1.2.2.1.2
```

Look for entries that match your SSID names. The index for each will map to the corresponding status OID.

> When walking interface tables over a VPN, use `-Cr5` with `snmpbulkwalk` if you're getting truncated results.

---

### Device Uptime

Standard SNMP uptime — no FortiGate-specific MIB needed.

| Item | OID |
|---|---|
| System uptime | `1.3.6.1.2.1.1.3.0` |

This is included in most base SNMP templates. The value is returned in TimeTicks (hundredths of a second) and Zabbix will handle the conversion to a readable format if the item type is set correctly.

---

## 6. Triggers — Recommended Baseline

These are starting points — tune thresholds to match your environment.

| Trigger | Condition | Severity |
|---|---|---|
| VPN tunnel down | Tunnel status = Down for 5 min | High |
| CPU usage high | CPU > 85% for 10 min | Warning |
| CPU usage critical | CPU > 95% for 5 min | High |
| Fan sensor alarm | Fan RPM = 0 | High |
| Temperature high | Temp sensor > threshold | Warning |
| Device unreachable | No SNMP response for 5 min | High |
| SSID down | ifOperStatus = Down | Average |

---

## Troubleshooting SNMP

**No data on items after setup**
Walk the device directly from the Zabbix server and compare the OID indexes against what's configured in the template. Index mismatch is the most common cause.

**Bulk walk timing out or returning partial results**
Disable bulk requests on the SNMP interface in Zabbix, or if walking manually, add `-Cr5` to limit rows per request. This is especially common when polling over a VPN tunnel.

**SNMP reachable from server CLI but not returning data in Zabbix**
Check that the host interface IP is correct and that the SNMP community macro is set. Also confirm the Zabbix server's outbound traffic to port 161 isn't being blocked.

**Items showing "Not supported"**
Usually means the OID doesn't exist on that device or the index is wrong. Walk the relevant MIB branch manually and compare.
