# zabbix_server.conf — Tuning & Performance Reference

This document supplements the base config reference (`zabbix_server.conf.md`) with guidance on tuning the Zabbix server as the monitored environment grows. Settings here go beyond the defaults needed for initial setup.

---

## When to Tune

The Zabbix dashboard under **Reports > System Information** will surface most performance issues before they become a problem:

- **Cache hit rate below 90%** — increase the relevant cache size
- **Busy process percentages above 75%** — increase the relevant process count
- **Database slow query warnings** — review indexing or consider partitioning the history tables

Check this page periodically, especially after adding a significant number of new hosts or items.

---

## Process Counts

These control how many parallel worker processes run for each function. More hosts and shorter polling intervals generally require higher values.

```ini
# Pollers handle standard SNMP and agent checks
StartPollers=10

# Unreachable pollers handle devices that aren't responding
StartPollersUnreachable=2

# Trappers receive passive data (agent active checks, traps)
StartTrappers=5

# Pingers handle ICMP availability checks
StartPingers=5

# HTTP pollers handle web monitoring items
StartHTTPPollers=2

# Discovery processes run LLD rules
StartDiscoverers=2

# Alert processes — MUST be set or no notifications fire
StartAlerters=3

# Timer handles time-based trigger functions
StartTimers=2

# Escalators handle alert escalation chains
StartEscalators=2
```

> Increase a process count if its "busy" percentage in System Information consistently exceeds 75%. There's no benefit to setting counts higher than needed — idle processes consume memory.

---

## Cache Sizes

All cache sizes must be specified with a suffix: `K`, `M`, or `G`.

```ini
# Main configuration cache — stores hosts, items, triggers
# Increase if you see "Zabbix configuration cache is low" in logs
CacheSize=32M

# History write cache — buffers incoming values before DB write
HistoryCacheSize=16M

# History index cache — speeds up history queries
HistoryIndexCacheSize=4M

# Trend cache — buffers trend data before DB write
TrendCacheSize=4M

# Value cache — speeds up trigger evaluation
# Increase if trigger processing is slow on a large deployment
ValueCacheSize=8M
```

---

## Timeouts

```ini
# Global check timeout in seconds
# Increase for devices on high-latency links (e.g., overseas sites over VPN)
Timeout=10

# How long to wait for an unreachable host before marking it down
UnreachablePeriod=45

# How often to retry an unreachable host (seconds)
UnreachableDelay=15

# How long before a host is considered unavailable (seconds)
UnavailableDelay=60
```

---

## History & Trend Retention

These control how long data is kept in the database. Longer retention means more disk usage. Adjust based on storage capacity and reporting requirements.

These are configured in the Zabbix UI, not in `zabbix_server.conf`:

Administration > General > Housekeeping

| Setting | Default | Notes |
|---|---|---|
| History storage period | 90 days | How long raw item values are kept |
| Trend storage period | 365 days | How long hourly aggregates are kept |
| Events storage period | 365 days | How long trigger events are kept |

> For a growing deployment, consider enabling **partitioning** on the history and trends tables in MySQL. This significantly improves housekeeping performance at scale. This is a DBA-level change — document it separately if implemented.

---

## Log Settings

```ini
LogFile=/var/log/zabbix/zabbix_server.log
LogFileSize=10

# Debug levels:
# 0 = none, 1 = critical, 2 = error, 3 = warning (default), 4 = debug, 5 = trace
# Set to 4 temporarily when troubleshooting, then back to 3
DebugLevel=3
```

To watch the log in real time:
```bash
tail -f /var/log/zabbix/zabbix_server.log
```

To filter for errors only:
```bash
grep -i "error\|warning\|cannot" /var/log/zabbix/zabbix_server.log
```

---

## Applying Changes

Always test the config before restarting:

```bash
zabbix_server --config /etc/zabbix/zabbix_server.conf -R config_cache_reload
```

Or simply restart the service:

```bash
systemctl restart zabbix-server
tail -f /var/log/zabbix/zabbix_server.log
```

Watch the log for a few seconds after restart to confirm it came up without errors.
