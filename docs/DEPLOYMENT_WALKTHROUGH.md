# Phoenix + Svelte Deployment Walkthrough - Digital Ocean + Cloudflare

Complete record of deploying urielm.dev to Digital Ocean with Cloudflare DNS/SSL.

**⚠️ Note:** This guide covers the **systemd-based deployment**. For the **Docker-based deployment** (recommended), see [DOCKER_DEPLOYMENT.md](./DOCKER_DEPLOYMENT.md).

**Stack:**
- Phoenix 1.8.1 + LiveView 1.1.0
- Svelte 5.18
- Elixir 1.17.3
- Ubuntu 22.04 on Digital Ocean
- Cloudflare for DNS/SSL/CDN

## Deployment Methods

This project supports two deployment approaches:

1. **Docker + docker-compose** (recommended) - See [DOCKER_DEPLOYMENT.md](./DOCKER_DEPLOYMENT.md)
   - Consistent environment
   - Easy rollbacks
   - No dependency management on server
   - Portable across platforms

2. **Systemd service** (documented below) - Traditional deployment
   - Smaller disk footprint
   - Direct code access
   - Familiar to sysadmins

## Prerequisites

- Digital Ocean account
- Domain managed by Cloudflare
- SSH key pair (`~/.ssh/tacit7`)
- Local git repository

## Part 1: Create Droplet

1. **Create Digital Ocean Droplet:**
   - Image: Ubuntu 22.04 LTS
   - Plan: Basic $12/month (2GB RAM)
   - Datacenter: Choose closest to users (we used SFO2)
   - Add SSH key (upload `~/.ssh/tacit7.pub`)
   - Create droplet
   - Note the IP: `167.172.194.233`

2. **Initial SSH setup:**
   ```bash
   # SSH as root first
   ssh -i ~/.ssh/tacit7 root@167.172.194.233

   # Create deploy user
   adduser deploy
   usermod -aG sudo deploy

   # Copy SSH key to deploy user
   mkdir -p /home/deploy/.ssh
   cp ~/.ssh/authorized_keys /home/deploy/.ssh/
   chown -R deploy:deploy /home/deploy/.ssh
   chmod 700 /home/deploy/.ssh
   chmod 600 /home/deploy/.ssh/authorized_keys

   # Test deploy user access
   exit
   ssh -i ~/.ssh/tacit7 deploy@167.172.194.233
   ```

## Part 2: Install Dependencies

**As deploy user on droplet:**

```bash
# System updates
sudo apt update && sudo apt upgrade -y

# Install Erlang & Elixir via RabbitMQ PPA (Erlang Solutions was dead)
sudo add-apt-repository ppa:rabbitmq/rabbitmq-erlang
sudo apt update
sudo apt install -y git elixir erlang

# Verify
elixir --version
# Elixir 1.17.3

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Verify
node --version  # v20.x.x
npm --version   # 10.x.x
```

## Part 3: Configure Digital Ocean Managed Database

### 3.1 Create Managed PostgreSQL Database

In Digital Ocean Dashboard:
1. **Databases** → **Create Database Cluster**
2. Choose PostgreSQL 18
3. Plan: Basic ($15/month minimum)
4. Datacenter: Same as droplet (SFO2)
5. Create database cluster

Note the connection details:
```
username = doadmin
password = [generated password]
host = db-postgresql-sfo2-xxxxx-do-user-xxxxx-0.l.db.ondigitalocean.com
port = 25060
database = defaultdb
sslmode = require
```

### 3.2 Download CA Certificate

1. In the database dashboard, go to **Connection Details**
2. Download the **CA Certificate** file (`ca-certificate.crt`)
3. Save it to your Desktop

### 3.3 Upload CA Certificate to Server

**From your Mac:**
```bash
# Upload certificate to server
scp -i ~/.ssh/tacit7 ~/Desktop/ca-certificate.crt deploy@167.172.194.233:~/
```

**On the server:**
```bash
ssh -i ~/.ssh/tacit7 deploy@167.172.194.233

# Move to system certificates directory
sudo mv ~/ca-certificate.crt /etc/ssl/certs/
sudo chmod 644 /etc/ssl/certs/ca-certificate.crt

# Verify
ls -la /etc/ssl/certs/ca-certificate.crt
```

### 3.4 Configure runtime.exs

Edit `config/runtime.exs` to include SSL certificate configuration:

```elixir
if config_env() == :prod do
  database_url = System.get_env("DATABASE_URL") ||
    raise "environment variable DATABASE_URL is missing."

  config :urielm, Urielm.Repo,
    url: database_url,
    # Point to uploaded CA certificate (Ubuntu path)
    ssl: [cacertfile: "/etc/ssl/certs/ca-certificate.crt"],
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: []

  # ... rest of config
end
```

**Important SSL Notes:**
- Digital Ocean managed databases require SSL with proper CA verification
- The `?sslmode=require` in the connection string is NOT enough
- Must point to CA certificate file using `ssl: [cacertfile: "path"]`
- Ubuntu/Debian path: `/etc/ssl/certs/ca-certificate.crt`
- Alpine path: `/etc/ssl/cert.pem` (if using Alpine Docker images)
- Do NOT use `verify: :verify_none` in production (disables security)

### 3.5 Running Migrations

**IMPORTANT:** Digital Ocean managed databases use `defaultdb` as the default database, NOT `postgres`.

**Do NOT run `mix ecto.create`** - it will fail because it tries to connect to the "postgres" admin database which doesn't exist in DO managed databases.

```bash
# ❌ DON'T DO THIS - will fail with "database postgres does not exist"
MIX_ENV=prod mix ecto.create

# ✅ DO THIS - run migrations directly since defaultdb already exists
MIX_ENV=prod mix ecto.migrate
```

The `defaultdb` database is automatically created when you provision the managed database cluster. Simply run migrations directly:

```bash
cd ~/new-urielm
MIX_ENV=prod mix ecto.migrate
```

If you see "Could not find migrations directory", that's normal if you haven't created any migrations yet. The database connection is working correctly.

## Part 4: Deploy Application

### 4.1 Get Code on Server

**Option A: Push to GitHub (recommended)**

On your Mac:
```bash
cd /Users/urielmaldonado/projects/urielm
git remote add origin https://github.com/YOUR_USERNAME/urielm.git
git push -u origin main
```

On droplet:
```bash
cd ~
git clone https://github.com/YOUR_USERNAME/urielm.git
cd urielm
```

**Option B: Use scp (for local Gitea)**
```bash
# On Mac
cd /Users/urielmaldonado/projects/urielm
tar czf urielm.tar.gz --exclude node_modules --exclude _build --exclude deps .
scp -i ~/.ssh/tacit7 urielm.tar.gz root@167.172.194.233:/tmp/

# On droplet
mkdir -p /home/deploy/urielm
cd /home/deploy/urielm
tar xzf /tmp/urielm.tar.gz
chown -R deploy:deploy /home/deploy/urielm
```

### 4.2 Build Application

```bash
cd ~/urielm

# Install Hex and Rebar
mix local.hex --force
mix local.rebar --force

# Install dependencies
mix deps.get --only prod
cd assets && npm install && cd ..

# Build assets
MIX_ENV=prod mix tailwind urielm --minify
cd assets && node build.js --deploy && cd ..
MIX_ENV=prod mix phx.digest
```

### 4.3 Generate Secrets

```bash
# Generate secret key base
mix phx.gen.secret
# Save this output: ***REMOVED***
```

Create production secrets (optional, but good practice):
```bash
nano config/prod.secret.exs
```

```elixir
import Config

secret_key_base = "***REMOVED***"

config :urielm, UrielmWeb.Endpoint,
  secret_key_base: secret_key_base,
  server: true
```

## Part 5: Configure Systemd Service

### 5.1 Create Service File

```bash
sudo nano /etc/systemd/system/urielm.service
```

**IMPORTANT:** Must include all three environment variables:

```ini
[Unit]
Description=Urielm Phoenix App
After=network.target

[Service]
Type=simple
User=deploy
Group=deploy
WorkingDirectory=/home/deploy/urielm
Environment=MIX_ENV=prod
Environment=PORT=4000
Environment=SECRET_KEY_BASE="***REMOVED***"
Environment=PHX_HOST="urielm.dev"
ExecStart=/usr/bin/mix phx.server
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

**Critical environment variables:**
- `SECRET_KEY_BASE` - Required by config/runtime.exs
- `PHX_HOST` - Required for `check_origin` validation (defaults to "example.com" if not set)
- `PORT` - Phoenix port (4000)

### 5.2 Start Service

```bash
sudo systemctl daemon-reload
sudo systemctl enable urielm
sudo systemctl start urielm
sudo systemctl status urielm
```

Should show: `Active: active (running)`

### 5.3 Verify Locally

```bash
# Check logs
sudo journalctl -u urielm -f

# Should see:
# "Running UrielmWeb.Endpoint with Bandit 1.8.0 at :::4000 (http)"
# "Access UrielmWeb.Endpoint at https://urielm.dev"

# Test locally
curl http://localhost:4000
# Should return HTML

# Verify Phoenix is listening on all interfaces
sudo ss -tlnp | grep 4000
# Should show: LISTEN 0 1024 *:4000 *:*
```

## Part 6: Configure Cloudflare

### 6.1 DNS Records

In Cloudflare dashboard → urielm.dev → DNS → Records:

```
Type    Name    Content              Proxy status
A       @       167.172.194.233      Proxied (orange cloud)
A       www     167.172.194.233      Proxied (orange cloud)
```

### 6.2 SSL/TLS Settings

**SSL/TLS** → **Overview**:
- Set encryption mode to: **Flexible**
- This means:
  - Browser → Cloudflare: HTTPS
  - Cloudflare → Origin: HTTP port 4000

**Why Flexible?**
- Phoenix doesn't have SSL configured
- Cloudflare handles SSL for visitors
- Connection between Cloudflare and origin is HTTP

**Don't use "Full" mode** - it will cause Error 521 because Cloudflare tries HTTPS but Phoenix only speaks HTTP.

### 6.3 Origin Rules (CRITICAL)

Cloudflare needs to connect to port 4000, not default port 80.

**Rules** → **Origin Rules** → **Create rule**:

- **Rule name:** `phx-origin`
- **When incoming requests match:** All incoming requests
- **Then... Set origin parameters:**
  - **Destination Port:** Rewrite to `4000`
  - **Host Header:** Preserve
- **Place at:** First

Save and deploy the rule.

### 6.4 Verify

```bash
# Check DNS propagation
dig urielm.dev
# Should show Cloudflare IPs (104.21.x.x, 172.67.x.x)

# Wait 30 seconds for origin rule to activate

# Visit site
open https://urielm.dev
```

## Troubleshooting

### Error 521: Web server is down

**Causes:**
1. ❌ Phoenix not running → Check `systemctl status urielm`
2. ❌ Wrong SSL mode → Must be "Flexible", not "Full"
3. ❌ No origin rule → Cloudflare connects to port 80 by default
4. ❌ Missing PHX_HOST → Phoenix rejects requests with wrong host

**Fix checklist:**
```bash
# 1. Verify Phoenix is running
sudo systemctl status urielm
curl http://localhost:4000

# 2. Check Phoenix is on all interfaces (not just 127.0.0.1)
sudo ss -tlnp | grep 4000
# Must show: *:4000 or :::4000

# 3. Verify environment variables
cat /etc/systemd/system/urielm.service | grep Environment
# Must have: SECRET_KEY_BASE and PHX_HOST

# 4. Check Cloudflare SSL mode
# Must be "Flexible"

# 5. Check origin rule exists and port is 4000
```

### Service won't start

```bash
# Check logs
sudo journalctl -u urielm -n 50

# Common errors:
```

**"environment variable SECRET_KEY_BASE is missing"**
- Add `Environment=SECRET_KEY_BASE="..."` to systemd service
- Don't forget closing quote!

**"environment variable PHX_HOST is missing"** (not an error, but uses "example.com")
- Add `Environment=PHX_HOST="urielm.dev"` to systemd service
- Critical for `check_origin` validation

### Assets not loading

```bash
# Rebuild assets
cd ~/urielm
MIX_ENV=prod mix assets.deploy
sudo systemctl restart urielm
```

### Firewall issues

```bash
# Check UFW status
sudo ufw status

# If active, allow port 4000
sudo ufw allow 4000/tcp

# Check Digital Ocean firewall
# Networking → Firewalls → Allow inbound 4000
```

## Key Lessons Learned

1. **Erlang Solutions repository was down** - Used RabbitMQ PPA instead
2. **Must set PHX_HOST environment variable** - Defaults to "example.com" causing check_origin failures
3. **Must set SECRET_KEY_BASE as environment variable** - config/runtime.exs requires it
4. **Cloudflare SSL mode matters** - "Full" fails because Phoenix uses HTTP, not HTTPS
5. **Origin rule is required** - Cloudflare connects to port 80 by default, not 4000
6. **No Nginx needed** - Cloudflare handles SSL, CDN, compression; Phoenix serves directly on port 4000
7. **Digital Ocean managed database SSL requires CA certificate** - Must upload DO's CA cert to `/etc/ssl/certs/` and configure `ssl: [cacertfile: "/etc/ssl/certs/ca-certificate.crt"]` in Repo config. The `?sslmode=require` connection string parameter alone is not sufficient for Postgrex.
8. **Skip `mix ecto.create` with Digital Ocean managed databases** - DO uses `defaultdb` as the default database, not `postgres`. Running `ecto.create` fails with "database postgres does not exist". The `defaultdb` is pre-created, so just run `mix ecto.migrate` directly.

## Useful Commands

### Service Management
```bash
# Restart
sudo systemctl restart urielm

# View logs (follow)
sudo journalctl -u urielm -f

# View recent logs
sudo journalctl -u urielm -n 100 --no-pager

# Check status
sudo systemctl status urielm
```

### Testing
```bash
# Test locally
curl http://localhost:4000

# Test from outside
curl http://167.172.194.233:4000

# Check what's listening on port 4000
sudo ss -tlnp | grep 4000
sudo lsof -i :4000
```

### Deployment Updates
```bash
cd ~/urielm
git pull
mix deps.get --only prod
cd assets && npm install && node build.js --deploy && cd ..
MIX_ENV=prod mix tailwind urielm --minify
MIX_ENV=prod mix phx.digest
sudo systemctl restart urielm
```

## Architecture Summary

```
User Browser
    ↓ HTTPS (443)
Cloudflare Proxy
    ↓ HTTP (4000)
Phoenix/Bandit
    ↓
Svelte Components
```

**Flow:**
1. User visits https://urielm.dev
2. DNS resolves to Cloudflare IP
3. Cloudflare terminates SSL
4. Cloudflare forwards HTTP request to 167.172.194.233:4000
5. Phoenix serves LiveView page with Svelte components
6. Cloudflare caches static assets

**No Nginx needed because:**
- Cloudflare handles SSL certificates
- Cloudflare handles compression
- Cloudflare handles static asset caching
- Phoenix Bandit is production-ready
- Single server, no load balancing needed

## Final Checklist

- ✅ Erlang, Elixir, Node.js installed
- ✅ Application cloned and built
- ✅ Assets compiled and digested
- ✅ Secret key generated
- ✅ Systemd service created with SECRET_KEY_BASE and PHX_HOST
- ✅ Service enabled and running
- ✅ Phoenix listening on *:4000 (all interfaces)
- ✅ Cloudflare DNS records (A @ and www)
- ✅ Cloudflare SSL mode: Flexible
- ✅ Cloudflare origin rule: port 4000
- ✅ Site accessible at https://urielm.dev

---

**Deployment Date:** December 3, 2025
**Droplet IP:** 167.172.194.233
**Domain:** urielm.dev
**Phoenix Version:** 1.8.1
**Elixir Version:** 1.17.3
