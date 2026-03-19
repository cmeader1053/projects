# Zabbix — Network Monitoring

This repository contains documentation, configuration references, and templates for a Zabbix monitoring deployment. All work has been sanitized of sensitive or
proprietary data. Currently the scope of this project is limited to only Fortinet firewalls of various models and the Zabbix server itself. The scope is intended to grow
to cover access points, switches and additional servers over time but those efforts have yet to be documented

---

## Environment Overview

Below is the quick overview of the various components that were installed and configured to bring this solution online. 

| Component | Details |
|---|---|
| Zabbix Version | 7.4 |
| Server OS | Ubuntu 22 |
| Database | MySQL |
| Cloud Provider | AWS |
| Authentication | LDAP / Entra ID |

Monitored infrastructure includes:

- **Firewalls** — FortiGate appliances across multiple physical sites and a virtual instance in AWS
- **Server** - Zabbix server hosted in AWS environment

---

## Repository Structure

```
├── docs/
│   ├── setup/              # Initial install and configuration guides
│   ├── templates/          # Notes on imported/custom Zabbix templates
│   ├── alerting/           # Alert action configs, media types, notification setup
│   └── troubleshooting/    # Common issues and fixes
├── configs/
│   ├── zabbix_server/      # Server config snippets (zabbix_server.conf notes)
│   ├── snmp/               # OID references, walk commands, index notes
│   └── nginx/              # Web frontend config (FQDN, TLS)
└── templates/
    └── zbx_export_*.xml    # Exported Zabbix templates
```

---

## Available Resources

### Monitoring Coverage

- **Hardware sensors** — CPU temperature, fan RPM, voltage and power supply via snmp
- **VPN tunnel status** — Monitored using the `fgVpnTunTable` OID branch with a custom value map for tunnel state.
- **WiFi SSID status** — Operational status pulled via `ifTable` OIDs. Includes a note on resolving SNMP fragmentation over VPN using bulk walk options.
- **Device status & uptime** - Availability monitoring and uptime tracking for firewalls across all sites.

### Alerting

Alerting is configured end-to-end with the following:

- **Transport** — O365 Relay
- **Recipients** — Previously setup distribution group in Active Directory (steps not included in this repo)
- **Format** — HTML email templates
- Documented gotchas include: `StartAlerters` being commented out by default in the server config, severity condition mismatches in trigger actions, and user permission gaps that silently block delivery.

### Authentication

LDAP authentication is configured against Entra ID. Documented failure mode: expired service account causes silent auth failures — check the bind account password first before digging further.

### Web Frontend

Nginx is configured to serve the Zabbix UI on an internal FQDN. Config snippet is in `configs/nginx/`.

---

## SNMP Notes

A few things worth knowing before you go down the SNMP rabbit hole:

- OID indexes are **not consistent across FortiGate models**. Always walk the device first and verify the index before building items/triggers.
- For bulk walks over a VPN tunnel, fragmentation can cause incomplete results. Use `-Cr5` (or similar) with `snmpbulkwalk` to limit rows per packet.
- Useful base OIDs are documented per-device in `docs/templates/`.

---

## Known Issues / Lessons Learned

This section exists so the next person doesn't spend two hours debugging something already figured out.

- **VPN tunnel alerts with no real outage** — Likely a ghost proxy ID with an overly broad subnet selector causing continuous child SA negotiations. Check phase 2 proxy ID configuration before assuming a real tunnel problem.
- **SNMP items returning no data** — Confirm the index with a live walk. Don't trust that it matches another device of the same model family.
- **Alerts not firing despite triggers being active** — Check: (1) `StartAlerters` in `zabbix_server.conf`, (2) user media permissions, (3) action severity filter matches the trigger severity.
- **LDAP login failures** — First thing to check is whether the service account password has expired.

---

## Contributing

If anyone has any suggestions on how to continue to scale this project or any tips or tricks for someone that is a first time Zabbix user I am all ears! I am learning as
I go so bear with me. 

---

## Notes on Sensitive Data

This repository is intended to be **public or shareable**. Do not commit:

- Hostnames, IP addresses, or FQDNs for internal infrastructure
- SNMP community strings or authentication credentials
- API keys, tokens, or passwords of any kind
- Usernames or service account names
- Any details that identify the organization's internal network topology

Generalize examples where specifics aren't necessary. Use placeholders like `<site-firewall>`, `<monitoring-server>`, or `10.x.x.x` in place of real values.
