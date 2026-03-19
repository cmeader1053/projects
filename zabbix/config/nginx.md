# Nginx — Zabbix Web Frontend Configuration

This document covers the Nginx configuration used to serve the Zabbix web UI on an internal FQDN. The base config file is installed by the `zabbix-nginx-conf` package at `/etc/zabbix/nginx.conf` and is included by the main Nginx config.

> Note that these configs could differ in various environments. This is just an example of the config I used and how you could edit that file to fit your environment needs

---

## File Location

```
/etc/zabbix/nginx.conf
```

This file is included from `/etc/nginx/nginx.conf` or from a site config under `/etc/nginx/conf.d/`. Verify the file exists post-install:

```bash
grep -r "zabbix" /etc/nginx/
```

---

## HTTP Configuration (Internal)

Use this for internal-only deployments.

```nginx
server {
    listen          <your-listening-port>;
    server_name     <your-zabbix-fqdn>;

    root    /usr/share/zabbix;
    index   index.php;

    access_log  /var/log/nginx/zabbix_access.log;
    error_log   /var/log/nginx/zabbix_error.log;

    location = /favicon.ico {
        log_not_found   off;
    }

    location / {
        try_files $uri $uri/ =404;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|woff|woff2)$ {
        expires         10d;
        access_log      off;
        add_header      Cache-Control "public";
    }

    location ~ \.php$ {
        fastcgi_pass    unix:/var/run/php/php8.3-fpm.sock;
        fastcgi_index   index.php;
        fastcgi_param   SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include         fastcgi_params;
        fastcgi_param   HTTP_HOST $host;
        fastcgi_buffers 8 32k;
        fastcgi_buffer_size 64k;
    }

    location ~ /\.ht {
        deny all;
    }
}
```

> Replace `<your-zabbix-fqdn>` with the actual hostname being used to access the UI. Without this, Nginx will only respond to IP-based requests.
> Replace `<your-listening-port>` with the actual port used. Default is port 80 but this can be whatever fits your environment.

---

## HTTPS Configuration (Recommended)

Use this if TLS is being terminated on the Zabbix server itself.

```nginx
# Redirect HTTP to HTTPS
server {
    listen      80;
    server_name <your-zabbix-fqdn>;
    return      301 https://$host$request_uri;
}

server {
    listen          443 ssl;
    server_name     <your-zabbix-fqdn>;

    ssl_certificate     /etc/ssl/certs/<your-cert>.crt;
    ssl_certificate_key /etc/ssl/private/<your-cert>.key;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    root    /usr/share/zabbix;
    index   index.php;

    access_log  /var/log/nginx/zabbix_access.log;
    error_log   /var/log/nginx/zabbix_error.log;

    location = /favicon.ico {
        log_not_found   off;
    }

    location / {
        try_files $uri $uri/ =404;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|woff|woff2)$ {
        expires         10d;
        access_log      off;
        add_header      Cache-Control "public";
    }

    location ~ \.php$ {
        fastcgi_pass    unix:/var/run/php/php8.3-fpm.sock;
        fastcgi_index   index.php;
        fastcgi_param   SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include         fastcgi_params;
        fastcgi_param   HTTP_HOST $host;
        fastcgi_buffers 8 32k;
        fastcgi_buffer_size 64k;
    }

    location ~ /\.ht {
        deny all;
    }
}
```

---

## Applying Changes

After editing the config, test it before reloading:

```bash
nginx -t
```

If the test passes, reload Nginx:

```bash
systemctl reload nginx
```

If the test fails, the output will point to the line causing the issue. Make necessary corrections and retest.

---

## Notes

- The PHP socket path (`/var/run/php/php8.3-fpm.sock`) should match the PHP-FPM version installed. Verify with:
  ```bash
  ls /var/run/php/
  ```
- If using a self-signed certificate for internal access, browsers will show a warning. Add the cert to the trusted store on managed machines to suppress it.
- For AWS deployments, if the instance sits behind an ALB handling TLS termination, the HTTP-only config is sufficient on the instance itself. Restrict port 80 on the security group to the ALB only.
