# zabbix_server.conf — Annotated Reference

This file documents the key settings in `zabbix_server.conf` that were changed from defaults in this deployment, along with notes on why. 
This is not a full config dump — just the parts that mattered during my install.

Full path on server: `/etc/zabbix/zabbix_server.conf`

---

## Database

```ini
DBHost=localhost
DBName=zabbix
DBUser=zabbix
DBPassword=<redacted>
DBPort=3306
```

---

## Alerting — Critical Setting

```ini
# DO NOT leave this commented out.
# The default (commented = 0) means no alert processes start,
# and no notifications will ever be sent — with no error to indicate why.
StartAlerters=3
```

---

## Poller Processes

These were tuned based on the number of monitored hosts and polling intervals. Increase if you see "busy" warnings in the Zabbix dashboard under Reports > System Information.

```ini
StartPollers=10
StartIPMIPollers=0
StartPollersUnreachable=2
StartTrappers=5
StartPingers=5
StartDiscoverers=2
StartHTTPPollers=2
```

---

## Cache

```ini
# Increase CacheSize if you see "Zabbix configuration cache is low" warnings
CacheSize=32M
HistoryCacheSize=16M
HistoryIndexCacheSize=4M
TrendCacheSize=4M
ValueCacheSize=8M
```

---

## Logging

```ini
LogFile=/var/log/zabbix/zabbix_server.log
LogFileSize=10
# DebugLevel 3 = warnings + errors. Set to 4 for verbose troubleshooting, then back to 3.
DebugLevel=3
```

---

## Timeouts

```ini
# Default is 3 — increase if SNMP polls are timing out on slow links (e.g., VPN)
Timeout=10
```

---

## Notes

- After any changes to this file, restart the service: `systemctl restart zabbix-server`
- Check the log after restart to confirm it came up cleanly: `tail -f /var/log/zabbix/zabbix_server.log`
- The Zabbix dashboard under **Reports > System Information** will surface most common misconfiguration issues (cache, process counts, etc.)
