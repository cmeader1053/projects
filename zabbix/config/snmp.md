# SNMP — Polling Configuration Reference

This document covers SNMP polling configuration as it relates to the Zabbix server — timeouts, bulk request behavior, and per-host interface settings. For OID references, see `fortigate-oid-reference.md`. For FortiGate-side SNMP setup, see `docs/setup/fortigate-snmp-setup.md`.

---

## Zabbix Host SNMP Interface Settings

These settings are configured per host under:

Configuration > Hosts > *select host* > Interfaces (SNMP)

| Setting | Recommended Value | Notes |
|---|---|---|
| IP Address | `<device-ip>` | Use IP, not DNS, for reliability |
| Port | `161` | Standard SNMP UDP port |
| SNMP Version | SNMPv2c | Used across this deployment |
| Community | `{$SNMP_COMMUNITY}` | Use the macro, not a hardcoded string |
| Use bulk requests | Enabled (default) | Disable if polling over VPN |
| Max repetitions | `10` | Reduce if seeing timeouts |

### Bulk Requests Over VPN

SNMP bulk requests send multiple OID values in a single response packet. Over a VPN tunnel, these packets can exceed the tunnel's MTU and get fragmented or dropped, resulting in missing data or "not supported" items.

**If polling a device over VPN:**
- Disable **Use bulk requests** on the host's SNMP interface, or
- Reduce **Max repetitions** to `5` or lower and test

---

## Zabbix Server SNMP Timeout

The global SNMP timeout is set in `zabbix_server.conf`:

```ini
# Default is 3 seconds — increase for devices on slow or high-latency links
Timeout=10
```

This applies to all checks, not just SNMP. If specific hosts on VPN links are timing out, increasing this value gives them more time to respond without affecting LAN devices.

After changing:
```bash
systemctl restart zabbix-server
```

---

## SNMP Community String — Macro Setup

The community string is stored as a global macro so it doesn't need to be set individually on every host.

Administration > General > Macros

| Macro | Value |
|---|---|
| `{$SNMP_COMMUNITY}` | `<your-community-string>` |

To override for a specific host (e.g., a device using a different community):

Configuration > Hosts > *select host* > Macros tab

Add the same macro name with the host-specific value. Zabbix resolves host-level macros before global ones.

---

## Manual SNMP Testing — Quick Reference

Run these from the Zabbix server to test SNMP connectivity before configuring items.

```bash
# Basic connectivity — should return system description
snmpwalk -v2c -c <community> <device-ip> sysDescr

# Walk the full Fortinet MIB
snmpwalk -v2c -c <community> <device-ip> 1.3.6.1.4.1.12356

# Walk over VPN — limit bulk rows to avoid fragmentation
snmpbulkwalk -v2c -c <community> -Cr5 <device-ip> 1.3.6.1.4.1.12356

# Get a single OID value
snmpget -v2c -c <community> <device-ip> <oid>

# Walk with numeric OIDs only (useful for index discovery)
snmpwalk -v2c -c <community> -On <device-ip> 1.3.6.1.4.1.12356.101.13.2.1
```

---

## SNMP Packages (Ubuntu)

If SNMP tools aren't installed on the Zabbix server:

```bash
apt install -y snmp snmp-mibs-downloader
```

To enable MIB resolution (translates OIDs to names in walk output):

```bash
# Edit /etc/snmp/snmp.conf and comment out or remove the mibs line
# mibs :
```

Or pass `-m ALL` to snmpwalk to load all available MIBs for that session:

```bash
snmpwalk -v2c -c <community> -m ALL <device-ip> sysDescr
```
