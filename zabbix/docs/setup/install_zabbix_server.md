# Zabbix Server — Installation Guide
 
This document covers the installation of the Zabbix server on Ubuntu LTS with MySQL as the backend database. 
Steps are based on a deployment to an AWS EC2 instance but apply equally to any Ubuntu server.

You can find a complete installation guide for other OS's and stacks here:  https://www.zabbix.com/download
 
---
 
## Prerequisites
 
- Ubuntu Server LTS (22.04 or 24.04)
- Sudo or root access
- Inbound ports open: `80/443` (web UI), `10051` (Zabbix trapper), `10050` (agent, if running locally)
- DNS or a static IP assigned to the server
 
---
 
## 1. Install the Zabbix Repository
 
Always pull the repo package directly from Zabbix's official release page to ensure you're getting the right version for your Ubuntu release.
 
```bash
wget https://repo.zabbix.com/zabbix/7.4/release/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.4+ubuntu24.04_all.deb
dpkg -i zabbix-release_latest_7.4+ubuntu24.04_all.deb
apt update
```
 
> Adjust the filename above to match your Ubuntu version if not on 24.04.
 
---
 
## 2. Install Zabbix Server, Frontend, and Agent
 
```bash
apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-nginx-conf zabbix-sql-scripts zabbix-agent
```
 
---
 
## 3. Install and Configure MySQL
 
```bash
apt install -y mysql-server
mysql_secure_installation
```
Ensure that MySQL is running prior. If not, start MySQL

```bash
systemctl status mysql # check status of mysql

systemctl start mysql # start mysql if it is not currently running
```
 
Create the Zabbix database and user:
 
```sql
CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE USER 'zabbix'@'localhost' IDENTIFIED BY '<strong-password>';
GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';
FLUSH PRIVILEGES;
```
 
Import the initial schema:
 
```bash
zcat /usr/share/zabbix/sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -p zabbix
```
 
---
 
## 4. Configure the Zabbix Server
 
Edit `/etc/zabbix/zabbix_server.conf`

```bash
cd /etc/zabbix/
nano zabbix_server.conf
```

set the following at minimum:
 
```ini
DBPassword=<strong-password>
 
# Make sure this is uncommented — it defaults to 0 (disabled) and alerts will silently not fire
StartAlerters=3
```
 
> **Important:** `StartAlerters` is commented out by default. If it stays that way, alert actions will never execute — no errors, no indication anything is wrong. Uncomment it and set a value of at least 1.
 
Other values worth reviewing:
 
```ini
# Tune based on environment size
StartPollers=10
StartPingers=5
CacheSize=32M
HistoryCacheSize=16M
```
 
---
 
## 5. Configure Nginx
Navigate to `/etc/zabbix/nginx.conf`
```bash
cd /etc/zabbix/
nano nginx.conf
```
 
```nginx
listen 80; # set whatever port meets your environment requirements
server_name <your-zabbix-fqdn>;
```
 
If you need HTTPS (recommended), set up a certificate and configure SSL in this file or a separate Nginx server block. 
For internal deployments, a self-signed cert or an internal CA cert both work.
 
---
 
## 6. Start and Enable Services
 
```bash
systemctl restart zabbix-server zabbix-agent nginx php8.3-fpm
systemctl enable zabbix-server zabbix-agent nginx php8.3-fpm
```
 
---
 
## 7. Complete the Web Setup
 
Navigate to `http://<your-server>:<listening-port>/` in a browser. You should be directed to the Zabbix UI setup wizard

The setup wizard will walk through:
 
1. Pre-installation checks (PHP settings, extensions)
2. Database connection details
3. Server details (name, timezone)
4. Summary and finish
 
Log in with the default credentials (`Admin` / `zabbix`) and change the password immediately.
 
---
