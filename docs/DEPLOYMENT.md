# Deployment Guide - Digital Ocean Droplet

Complete guide to deploying urielm.dev Phoenix LiveView + Svelte app to Digital Ocean.

## Prerequisites

- Digital Ocean account
- Domain name (urielm.dev) managed by Cloudflare
- Git repository (Gitea at localhost:3000)

**Note:** This guide assumes you're using Cloudflare for DNS and SSL. Cloudflare's free tier provides SSL certificates, CDN, and DDoS protection automatically.

## Part 1: Create & Configure Droplet

### 1.1 Create Droplet

1. Log into Digital Ocean
2. Create → Droplets
3. Choose:
   - **Image:** Ubuntu 22.04 LTS
   - **Plan:** Basic ($12/month - 2GB RAM recommended for Phoenix)
   - **Datacenter:** Choose closest to your users
   - **Authentication:** SSH key (recommended) or password
4. Create Droplet
5. Note the IP address

### 1.2 Configure DNS

Point your domain to the Droplet:
```
A Record: @ → YOUR_DROPLET_IP
A Record: www → YOUR_DROPLET_IP
```

### 1.3 Initial Server Setup

SSH into your droplet:
```bash
ssh root@YOUR_DROPLET_IP
```

Create deploy user:
```bash
adduser deploy
usermod -aG sudo deploy
su - deploy
```

## Part 2: Install Dependencies

### 2.1 System Updates
```bash
sudo apt update && sudo apt upgrade -y
```

### 2.2 Install Erlang & Elixir
```bash
# Add Erlang Solutions repository
wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb
sudo dpkg -i erlang-solutions_2.0_all.deb
sudo apt update

# Install Erlang and Elixir
sudo apt install -y esl-erlang elixir

# Verify installation
elixir --version
```

### 2.3 Install Node.js (for asset building)
```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Verify
node --version
npm --version
```

## Part 3: Deploy Application

### 3.1 Clone Repository

Set up Git access to your Gitea server (or use HTTP with credentials):
```bash
cd ~
git clone http://uriel:PASSWORD@YOUR_GITEA_IP:3000/uriel/urielm.git
cd urielm
```

**Note:** Replace with your actual Gitea URL and credentials.

### 3.2 Install Dependencies
```bash
# Install Hex and Rebar
mix local.hex --force
mix local.rebar --force

# Install Elixir dependencies
mix deps.get --only prod

# Install Node dependencies
cd assets && npm install && cd ..
```

### 3.3 Build Assets
```bash
# Build Tailwind CSS
MIX_ENV=prod mix tailwind urielm --minify

# Build JavaScript
cd assets && node build.js --deploy && cd ..

# Digest static files
MIX_ENV=prod mix phx.digest
```

### 3.4 Generate Secret Key Base
```bash
mix phx.gen.secret
```
**Save this output** - you'll need it for the production config.

## Part 4: Production Configuration

### 4.1 Create Production Secrets

Create `/home/deploy/urielm/config/prod.secret.exs`:
```elixir
import Config

# Generate with: mix phx.gen.secret
secret_key_base = "YOUR_SECRET_KEY_BASE_HERE"

config :urielm, UrielmWeb.Endpoint,
  secret_key_base: secret_key_base,
  server: true
```

**Replace `YOUR_SECRET_KEY_BASE_HERE`** with the output from `mix phx.gen.secret`.

### 4.2 Update config/runtime.exs

The runtime.exs should already be configured, but verify it includes:
```elixir
if config_env() == :prod do
  # Import secrets file if it exists
  config_path = config_env_path(:prod)
  if File.exists?(config_path), do: import_config(config_path)

  config :urielm, UrielmWeb.Endpoint,
    url: [host: "urielm.dev", port: 443, scheme: "https"],
    http: [port: 4000],
    check_origin: ["https://urielm.dev", "https://www.urielm.dev"]
end
```

## Part 5: Systemd Service

### 5.1 Create Service File

Since we're using Cloudflare's proxy, Phoenix can run on port 4000. Cloudflare handles SSL and forwards to your server.

Create `/etc/systemd/system/urielm.service`:
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
ExecStart=/usr/bin/mix phx.server
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

### 5.2 Enable and Start Service
```bash
sudo systemctl daemon-reload
sudo systemctl enable urielm
sudo systemctl start urielm
sudo systemctl status urielm
```

## Part 6: Cloudflare Configuration

Since you're using Cloudflare with proxied DNS (orange cloud), SSL is handled automatically by Cloudflare. No need for Let's Encrypt or manual SSL certificates.

### 6.1 Cloudflare DNS Setup

In Cloudflare dashboard:
1. Go to **DNS** → **Records**
2. Add A records pointing to your Droplet IP:
   ```
   Type    Name    Content              Proxy status
   A       @       YOUR_DROPLET_IP      Proxied (orange cloud)
   A       www     YOUR_DROPLET_IP      Proxied (orange cloud)
   ```

### 6.2 Cloudflare SSL Settings

1. Go to **SSL/TLS** tab in Cloudflare
2. Set encryption mode to **Flexible** (Cloudflare ↔ Browser: HTTPS, Cloudflare ↔ Server: HTTP)
3. Cloudflare automatically provides free SSL certificate for visitors

### 6.3 Verify Configuration

```bash
# Test that Phoenix is responding on port 4000
curl http://localhost:4000

# Check DNS propagation
dig urielm.dev
```

Once DNS propagates (5-30 minutes), your site will be live at https://urielm.dev with automatic SSL.

## Part 7: Deployment Script

For future deployments, use the provided `deploy.sh` script:

```bash
cd /home/deploy/urielm
./deploy.sh
```

## Monitoring & Maintenance

### Check Service Status
```bash
sudo systemctl status urielm
```

### View Logs
```bash
sudo journalctl -u urielm -f
```

### Restart Service
```bash
sudo systemctl restart urielm
```

### Update Application
```bash
cd /home/deploy/urielm
git pull
mix deps.get --only prod
cd assets && npm install && node build.js --deploy && cd ..
MIX_ENV=prod mix tailwind urielm --minify
MIX_ENV=prod mix phx.digest
sudo systemctl restart urielm
```

## Troubleshooting

### Service won't start
```bash
# Check logs
sudo journalctl -u urielm -n 50

# Check if port is available
sudo lsof -i :4000

# Test manually
cd /home/deploy/urielm
MIX_ENV=prod mix phx.server
```

### Can't connect to site
```bash
# Verify Phoenix is running
sudo systemctl status urielm

# Test locally
curl http://localhost:4000

# Check firewall
sudo ufw status

# Verify Cloudflare DNS
dig urielm.dev
```

### Assets not loading
```bash
# Rebuild assets
cd /home/deploy/urielm
MIX_ENV=prod mix assets.deploy
sudo systemctl restart urielm
```

## Firewall Setup (UFW)

```bash
sudo ufw allow OpenSSH
sudo ufw allow 4000/tcp  # Phoenix server
sudo ufw enable
sudo ufw status
```

**Note:** Since Cloudflare proxies all traffic, only Cloudflare's IPs need access to port 4000. For added security, you could restrict port 4000 to Cloudflare IP ranges, but this is optional for a simple setup.

## Performance Tips

1. **Monitor memory usage**:
   ```bash
   free -h
   htop
   ```

2. **Enable gzip compression** - Already handled by Cloudflare's proxy

3. **Static asset caching** - Already handled by Cloudflare's CDN

## Estimated Costs

- **Droplet (2GB):** $12/month
- **Domain:** ~$10-15/year
- **Total:** ~$13/month

## Next Steps

1. Set up monitoring (optional): UptimeRobot, Pingdom
2. Set up backups (optional): Digital Ocean Snapshots
3. Configure custom error pages
4. Set up log rotation
5. Consider adding Redis for sessions (if needed)

---

**Your app will be live at:** https://urielm.dev

For questions or issues, refer to:
- Phoenix deployment guide: https://hexdocs.pm/phoenix/deployment.html
- Digital Ocean tutorials: https://www.digitalocean.com/community/tags/phoenix
