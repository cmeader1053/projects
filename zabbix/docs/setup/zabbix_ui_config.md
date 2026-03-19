# Zabbix Server — Configuration

This document covers post-install configuration in Zabbix UI, including authentication, alerting transport, and web frontend setup. 
For the initial install, see `zabbix-server-install.md`.
For SNMP setup and adding hosts to the Zabbix UI, see ``

---

## LDAP / Entra ID Authentication

Zabbix supports LDAP authentication natively. The following covers connecting it to Microsoft Entra ID (Azure AD) via LDAP.

### Configuration Path

Users > Authentication > LDAP Settings

### Settings

| Field | Value |
|---|---|
| LDAP Host | `ldaps://<your-entra-ldap-endpoint>` |
| Port | `636` |
| Base DN | `DC=<domain>,DC=<tld>` |
| Search Attribute | `userPrincipalName` |
| Bind DN | `<service-account-upn>` |
| Bind Password | *(service account password)* |

### Known Issue — Silent Auth Failures

If LDAP logins stop working without any obvious error, the most common cause is an **expired service account password**. 
Entra ID doesn't notify Zabbix when the password expires — it just stops authenticating. Check the bind account first before digging into anything else.

> Make sure the service account used for LDAP bind has a non-expiring password or that rotation is tracked and updated in Zabbix before it lapses.

---

## Alerting

For this project, I used a previously setup O365 Relay to email an internal distribution group that was previously created in Active Directory. 
ZAbbix also offers SMTP configuration if that works better. The below steps shows my setup for the O365 Relay. 

### Media Type Configuration

Alerts > Media Types > Create Media Type

| Field | Value |
|---|---|
| Type | Email |
| Email Provider | `O365 Relay` |
| Email | `<sender-email-for-alerts>'
| Authentication | None |
| Message Format | `HTML` |

You can set message templates during the configuration of the media type. This is where you can setup what the alert looks like when its received via email. 
In my case, I used HTML to setup problem, updates to problems and problem recovery alerts. Below is an example of that setup:

```html
<b>Alert Overview:</b><br>
Device: {HOST.NAME}<br>
Status: {TRIGGER.STATUS}<br>
Severity: {TRIGGER.SEVERITY}<br>
<br>
<b>Alert Details:</b><br>
Event ID: {EVENT.ID}<br>
Event Name: {EVENT.NAME}<br>
Event time: {EVENT.TIME} {EVENT.DATE}<br>
Item: {ITEM.NAME}<br>
Value: {ITEM.VALUE}<br>
Description: {TRIGGER.DESCRIPTION}<br>
<br>
Alert Acknowledged: {EVENT.ACK.STATUS}<br>
```

### User Media Assignment

Each user that should receive alerts needs a **Media** entry under their profile pointing to this media type with the appropriate recipient address 
(or distribution group address).

> If a user has no media configured, they will receive no alerts — even if they're in the right user group and the trigger fires correctly.

---

## Alert Actions

Alerts > Actions > Trigger Actions

An action ties a trigger event to a notification. Key settings:

- **Conditions** — Set the severity filter to match what your triggers actually use. A mismatch here (e.g., action set to "High" but trigger is "Warning") means alerts fire but no notification is sent.
- **Operations** — Add a "Send message" operation targeting the user or user group with the media type configured above.

### Common Misconfiguration

The severity filter in the action conditions is a frequent source of "alerts not sending" issues. If a trigger fires but no email arrives, check that the action's severity condition includes the trigger's severity level.

---

## Nginx — FQDN Access

If Zabbix is only accessible by IP by default, update `/etc/zabbix/nginx.conf` to include the server's FQDN:

```nginx
server {
    listen          80;
    server_name     <your-zabbix-fqdn>;

    root    /usr/share/zabbix;
    index   index.php;

    # ... rest of config
}
```

Reload Nginx after any changes:

```bash
systemctl reload nginx
```

If using HTTPS, add a separate `listen 443 ssl;` block and reference your certificate and key files.

---

## zabbix_server.conf — Key Settings Reference

Below are the settings most likely to need attention in a fresh deployment. The full config file is well-commented and worth reading through.

```ini
# Database
DBName=zabbix
DBUser=zabbix
DBPassword=<password>

# CRITICAL — uncomment this or alerts will never fire
StartAlerters=3

# Tune based on host count and polling interval
StartPollers=10
StartTrappers=5
StartPingers=5

# Cache — increase if you see cache full warnings in the log
CacheSize=32M
HistoryCacheSize=16M
TrendCacheSize=4M

# Log
LogFile=/var/log/zabbix/zabbix_server.log
LogFileSize=10
DebugLevel=3
```

> Full path: `/etc/zabbix/zabbix_server.conf`

---

## User Permissions — Quick Reference

Zabbix has a layered permission model that catches people off guard:

- Users belong to **User Groups**
- User Groups have access to **Host Groups**
- Hosts belong to **Host Groups**
- Alerts are only sent to users whose group has at least **Read** access to the host group containing the affected host

If a user isn't receiving alerts for a specific host, trace the chain: User > User Group > Host Group > Host.
