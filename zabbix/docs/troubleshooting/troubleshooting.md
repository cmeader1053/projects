# Troubleshooting Guide

This document consolidates known issues, common misconfigurations, and fixes encountered in this Zabbix deployment. If something is broken, start here before digging through logs.

---

## Zabbix Server

### Alerts Not Firing At All

The most common cause of a completely silent alerting setup is `StartAlerters` being commented out in `zabbix_server.conf`. This is the default — if it was never explicitly set, no alert processes are running.

**Fix:**
```ini
# /etc/zabbix/zabbix_server.conf
StartAlerters=3
```
Restart the service after changing:
```bash
systemctl restart zabbix-server
```

### Alerts Firing But No Email Delivered

Work through this in order:

1. **Severity filter mismatch** — The alert action's condition filter may be set to a higher severity than the trigger. Check Configuration > Actions > *action* > Conditions. Set severity to `>= Warning` to catch everything.
2. **User has no media entry** — Go to Administration > Users > *user* > Media. If it's empty, there's no delivery path.
3. **User group lacks host group access** — The user's group needs at least Read access to the host group containing the affected host. Check Administration > User Groups > *group* > Host Group Permissions.
4. **Action log** — Administration > Audit > Action Log shows every action attempt and result. This is the fastest way to confirm whether the action ran and why it may have failed.

### Zabbix Web UI Not Accessible via FQDN

If the UI is only reachable by IP and not by hostname, the Nginx config needs updating.

**Fix:** Edit `/etc/zabbix/nginx.conf` and set the `server_name` directive:
```nginx
server_name <your-zabbix-fqdn>;
```
Reload Nginx:
```bash
systemctl reload nginx
```

### LDAP Authentication Failures

If LDAP logins stop working without an obvious error, the bind service account password has most likely expired. Entra ID doesn't notify Zabbix when this happens — it just silently rejects authentication.

**Fix:** Reset or update the service account password, then update it in Zabbix under Administration > Authentication > LDAP Settings > Bind Password.

> Prevent recurrence by setting the service account password to non-expiring, or by tracking the expiry date and updating Zabbix before it lapses.

---

## SNMP & FortiGate

### SNMP Items Returning No Data

The most common cause is an OID index mismatch. Indexes are not consistent across FortiGate models — a sensor or tunnel that's at index `.1` on one device may be at `.3` on another.

**Fix:** Walk the device directly from the Zabbix server and compare indexes against what's configured in the template items:
```bash
snmpwalk -v2c -c <community> <firewall-ip> 1.3.6.1.4.1.12356.101.13.2.1
```
Update the item OIDs in Zabbix to match the actual indexes on the device.

### Items Showing "Not Supported"

Means the OID doesn't exist on the device or the index is wrong. Same resolution as above — walk first, then fix the item.

### SNMP Bulk Walk Returning Incomplete Results

Usually fragmentation over a VPN tunnel. The bulk response packets are too large and get dropped in transit.

**Fix — Zabbix host interface:**
Disable **Use bulk requests** on the host's SNMP interface in Zabbix.

**Fix — manual walk:**
Use `-Cr5` to limit rows per request:
```bash
snmpbulkwalk -v2c -c <community> -Cr5 <firewall-ip> 1.3.6.1.4.1.12356
```

### SNMP Reachable from CLI But No Data in Zabbix

- Confirm the host interface IP in Zabbix matches the device's actual IP
- Confirm `{$SNMP_COMMUNITY}` macro is set correctly at the host or global level
- Confirm port 161 UDP outbound from the Zabbix server isn't being blocked by a firewall rule or security group

### VPN Tunnel Alerts With No Actual Outage

If the tunnel shows as flapping or continuously renegotiating but traffic is passing normally, the likely cause is a ghost proxy ID with an overly broad subnet selector (e.g., `192.168.0.0/16`). The firewall keeps trying to negotiate a child SA for that selector, which generates events that Zabbix picks up as tunnel state changes.

**Fix:** Review the phase 2 proxy ID configuration on both ends of the tunnel. Remove or correct any selectors that don't match actual traffic requirements. This requires a change review before touching production tunnels.

---

## Templates & Items

### Template Changes Not Reflecting on Hosts

Changes to a template propagate to linked hosts automatically but may take a polling cycle or two. If changes still aren't showing after a few minutes, unlink and re-link the template on the host. Use **Unlink** (not **Unlink and clear**) to preserve historical data.

### Discovery Rules Not Finding Sensors or Tunnels

1. Confirm SNMP is reachable with a manual walk
2. Check the discovery rule's OID — confirm it returns data on the device
3. Check the LLD filter conditions — an overly strict filter may be excluding valid results
4. Check the discovery interval — if it was recently added, wait for the next discovery cycle

### WiFi SSIDs Not Appearing in Discovery

The base FortiGate template does not auto-discover SSIDs. They need to be added as manual items using `ifTable` OIDs. Walk the interface table to find the SSID indexes:
```bash
snmpwalk -v2c -c <community> <firewall-ip> 1.3.6.1.2.1.2.2.1.2
```
See `docs/setup/fortigate-snmp-setup.md` for full item configuration details.

---

## Email / Alerting

### Test Email from Media Type Failing

- Verify credentials — if the M365 account has MFA, a standard password won't work for SMTP. Use an app password or exclude the account from MFA via Conditional Access.
- Verify SMTP AUTH is enabled for the sending account in Exchange Online:
```powershell
Get-CASMailbox -Identity <mailbox@domain.com> | Select SmtpClientAuthenticationDisabled
```
If `True`, enable it:
```powershell
Set-CASMailbox -Identity <mailbox@domain.com> -SmtpClientAuthenticationDisabled $false
```
- Confirm the account has **Send As** rights on the shared mailbox if sending from a shared mailbox address.

### HTML Email Rendering as Raw Markup

The media type message format must be set to **HTML**. Check Administration > Media Types > *Email (M365)* > Message Format.

### Recovery Email Not Sending

Confirm a **Recovery operation** is added under the alert action. Problem and recovery notifications are separate operations — adding one does not automatically create the other.

---

## General Tips

- **Reports > System Information** in the Zabbix UI surfaces most common server-level issues — cache usage, process counts, database performance. Check here first when something feels off.
- **Administration > Audit > Action Log** is the first place to look when alerts aren't delivering. It shows exactly what ran, when, and whether it succeeded.
- After any change to `zabbix_server.conf`, restart the service and tail the log to confirm it came up cleanly:
```bash
systemctl restart zabbix-server && tail -f /var/log/zabbix/zabbix_server.log
```
