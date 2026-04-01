# Quickstart 1: nginx-hello

Static nginx site — no containers, no secrets.

## What This Demonstrates

| Tool | Role |
|------|------|
| **hery** | Stores and queries the entity definitions |
| **lay** | Installs the `nginx` package via the system package manager |
| **weaver** | Generates `nginx-hello.conf` from the template + webserver entity |

## Entities

```
entities/
  package.hery       # _type: package — installs nginx
  webserver.hery     # _type: application/webserver — server config (port 8080, document root)
  template.hery      # _type: template — tells weaver to render nginx config
```

## Dependency Graph

```
package.hery (install nginx)
    ↑
webserver.hery (configure nginx)    ← _requires package
    ↑
template.hery (render config)       ← _requires webserver
```

`amadla run` resolves this via topological sort: package → webserver → template.

## Pipeline

```bash
# What amadla does under the hood:
# 1. lay reads package.hery → apt install nginx
# 2. weaver reads template.hery + webserver.hery → generates nginx-hello.conf
# 3. Copy static/index.html to /var/www/nginx-hello/

amadla run --config tools.hery entities/
```

## Manual Steps (without amadla)

```bash
# Install nginx
lay < entities/package.hery

# Generate nginx config
cat entities/webserver.hery | weaver render --template templates/nginx-hello.conf.tmpl > /etc/nginx/sites-available/nginx-hello.conf

# Deploy static content
mkdir -p /var/www/nginx-hello
cp static/index.html /var/www/nginx-hello/

# Enable and reload
ln -s /etc/nginx/sites-available/nginx-hello.conf /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

# Verify
curl http://localhost:8080
```

## Test (DAG resolution only)

```bash
# Verify the dependency graph resolves correctly
amadla run --dry-run --config tools.hery entities/
# Expected output:
#   1. amadla.org/entity/package@v1.0.0
#   2. amadla.org/entity/application/webserver@v1.0.0
#   3. amadla.org/entity/template@v1.0.0
```
