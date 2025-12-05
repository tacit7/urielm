# Docker Deployment Guide - urielm.dev

Complete guide for deploying the Phoenix + Svelte app using Docker on Digital Ocean.

**Stack:**
- Phoenix 1.8.1 + LiveView 1.1.0 + Svelte 5.18
- Docker + docker-compose
- Digital Ocean Managed PostgreSQL 18
- Digital Ocean Droplet (Ubuntu 22.04)
- Cloudflare for DNS/SSL/CDN

## Prerequisites

- Digital Ocean account with:
  - Droplet (Ubuntu 22.04, 2GB RAM minimum)
  - Managed PostgreSQL database
- Domain managed by Cloudflare
- SSH key pair (`~/.ssh/tacit7`)
- Git repository (tacit7/urielm.git)
- Docker installed locally (for testing)

## Part 1: Server Setup

### 1.1 Install Docker on Droplet

```bash
# SSH to server
ssh -i ~/.ssh/tacit7 deploy@167.172.194.233

# Install Docker
curl -fsSL https://get.docker.com | sh

# Add deploy user to docker group
sudo usermod -aG docker deploy

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Exit and SSH back in for group changes
exit
ssh -i ~/.ssh/tacit7 deploy@167.172.194.233

# Verify installation
docker --version        # Docker v29.1.2
docker-compose --version # Docker Compose v5.0.0
docker ps               # Should show empty list
```

### 1.2 Create Application Directory

```bash
mkdir -p /home/deploy/urielm
cd /home/deploy/urielm
```

### 1.3 Clone Repository

```bash
git clone https://github.com/tacit7/urielm.git .
```

### 1.4 Create Environment File

```bash
nano .env
```

Paste (replace with your actual credentials):
```bash
SECRET_KEY_BASE=your_secret_key_here
DATABASE_URL=postgresql://doadmin:PASSWORD@db-host:25060/defaultdb?sslmode=require
PHX_HOST=urielm.dev
MIX_ENV=prod
PORT=4000
```

Save (`Ctrl+X`, `Y`, `Enter`) and set permissions:
```bash
chmod 600 .env
```

## Part 2: Database Setup

### 2.1 Create Digital Ocean Managed PostgreSQL

1. Digital Ocean Dashboard → Databases → Create Database
2. PostgreSQL 18
3. Same datacenter as droplet (SFO2)
4. Note connection details

### 2.2 Download CA Certificate

1. Database dashboard → Connection Details
2. Download CA Certificate (`ca-certificate.crt`)
3. This file is needed for SSL verification

**Note:** The CA certificate is already baked into the Docker image via the Dockerfile. You don't need to manually upload it to the server.

### 2.3 Update config/runtime.exs

Ensure your `config/runtime.exs` includes:

```elixir
if config_env() == :prod do
  database_url = System.get_env("DATABASE_URL") ||
    raise "environment variable DATABASE_URL is missing."

  config :urielm, Urielm.Repo,
    url: database_url,
    ssl: [cacertfile: "/etc/ssl/certs/ca-certificate.crt"],
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: []

  # ... rest of config
end
```

### 2.4 Database Migrations

**Important:** Digital Ocean managed databases use `defaultdb` as the default database, NOT `postgres`.

❌ **Don't run:** `mix ecto.create` (will fail with "database postgres does not exist")

✅ **Do run:** `mix ecto.migrate` (defaultdb already exists)

## Part 3: Docker Configuration

### 3.1 Dockerfile

The multi-stage Dockerfile is located at project root:

```dockerfile
# Build stage
FROM elixir:1.17-alpine AS builder

RUN apk add --no-cache build-base npm git python3
WORKDIR /app

# Install Elixir dependencies
RUN mix local.hex --force && mix local.rebar --force
ENV MIX_ENV=prod

COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
RUN mix deps.compile

# Install and build assets
COPY assets/package*.json assets/
RUN cd assets && npm ci --production=false

COPY . .
RUN cd assets && node build.js --deploy
RUN mix tailwind urielm --minify
RUN mix phx.digest

# Build release
RUN mix compile
RUN mix release

# Runtime stage - MUST match build stage for OpenSSL compatibility
FROM elixir:1.17-alpine

RUN apk add --no-cache openssl ncurses-libs
WORKDIR /app

# Copy release from builder
COPY --from=builder /app/_build/prod/rel/urielm ./

# Create non-root user
RUN addgroup -g 1000 urielm && \
    adduser -D -u 1000 -G urielm urielm && \
    chown -R urielm:urielm /app

USER urielm

ENV HOME=/app
ENV MIX_ENV=prod
ENV PORT=4000

EXPOSE 4000

CMD ["bin/urielm", "start"]
```

**Key Points:**
- **Runtime image MUST be `elixir:1.17-alpine`** - Using `alpine:3.18` causes OpenSSL/crypto library errors
- Multi-stage build keeps image reasonably sized (~150MB)
- Non-root user for security
- Assets built during Docker build (npm, esbuild, tailwind)

### 3.2 docker-compose.yml

```yaml
version: '3.8'

services:
  web:
    image: urielm:latest
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "4000:4000"
    environment:
      - MIX_ENV=prod
      - PORT=4000
      - SECRET_KEY_BASE=${SECRET_KEY_BASE}
      - DATABASE_URL=${DATABASE_URL}
      - PHX_HOST=${PHX_HOST:-urielm.dev}
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:4000"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

### 3.3 Release Module for Migrations

Create `lib/urielm/release.ex`:

```elixir
defmodule Urielm.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix installed.
  """
  @app :urielm

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
```

## Part 4: Deployment Workflow

### 4.1 Initial Deployment

```bash
# On server
cd /home/deploy/urielm
git pull origin main

# Build and start container
docker-compose up -d --build

# Check logs
docker-compose logs -f

# Wait for container to be healthy, then run migrations
docker-compose exec -T web bin/urielm eval "Urielm.Release.migrate()"

# Verify container is running
docker-compose ps
```

Expected output:
```
NAME                IMAGE               COMMAND                  SERVICE   CREATED         STATUS                   PORTS
urielm-web-1        urielm:latest       "bin/urielm start"      web       2 minutes ago   Up 2 minutes (healthy)   0.0.0.0:4000->4000/tcp
```

### 4.2 Testing Locally

Before deploying to production, test the Docker build locally:

```bash
# On your Mac
cd /Users/urielmaldonado/projects/urielm

# Build image
docker build -t urielm:test .

# Run container
docker run -d -p 4000:4000 \
  --name urielm-test \
  -e MIX_ENV=prod \
  -e SECRET_KEY_BASE="your_secret_key" \
  -e DATABASE_URL="postgresql://user:pass@host:25060/defaultdb?sslmode=require" \
  -e PHX_HOST="urielm.dev" \
  urielm:test

# Check logs
docker logs urielm-test -f

# Test at http://localhost:4000
open http://localhost:4000

# Clean up
docker stop urielm-test
docker rm urielm-test
```

### 4.3 Future Deployments

```bash
# SSH to server
ssh -i ~/.ssh/tacit7 deploy@167.172.194.233
cd /home/deploy/urielm

# Pull latest code
git pull origin main

# Rebuild and restart
docker-compose up -d --build

# Run migrations
docker-compose exec -T web bin/urielm eval "Urielm.Release.migrate()"
```

### 4.4 Rollback

```bash
# List available images
docker images | grep urielm

# Stop current container
docker-compose down

# Run specific version (if you tagged it)
docker run -d -p 4000:4000 --env-file .env urielm:20241204_120345

# Or rebuild from a previous git commit
git checkout <previous-commit-hash>
docker-compose up -d --build
git checkout main
```

## Part 5: Cloudflare Configuration

Cloudflare configuration remains the same as systemd deployment:

### 5.1 DNS Records

```
Type    Name    Content              Proxy status
A       @       167.172.194.233      Proxied (orange cloud)
A       www     167.172.194.233      Proxied (orange cloud)
```

### 5.2 SSL/TLS Settings

- Encryption mode: **Flexible**
- Browser → Cloudflare: HTTPS
- Cloudflare → Origin: HTTP port 4000

### 5.3 Origin Rules

**Rules** → **Origin Rules** → **phx-origin**:
- When: All incoming requests
- Then: Set origin port to `4000`
- Host Header: Preserve

## Part 6: Monitoring & Maintenance

### 6.1 View Logs

```bash
# Follow logs
docker-compose logs -f

# View recent logs
docker-compose logs --tail=100

# View logs for specific service
docker-compose logs web
```

### 6.2 Container Status

```bash
# List running containers
docker-compose ps

# Check health
docker-compose exec web bin/urielm rpc "IO.puts(:erlang.system_info(:system_version))"
```

### 6.3 Restart Container

```bash
docker-compose restart
```

### 6.4 Stop/Start

```bash
# Stop
docker-compose down

# Start
docker-compose up -d
```

### 6.5 Database Console

```bash
docker-compose exec web bin/urielm remote
```

Or connect directly to managed database:
```bash
PGPASSWORD='password' psql \
  -h db-postgresql-sfo2-18861-do-user-4084462-0.l.db.ondigitalocean.com \
  -p 25060 \
  -U doadmin \
  -d defaultdb
```

## Troubleshooting

### Container won't start

```bash
# Check logs for errors
docker-compose logs

# Common errors:
```

**"Unable to load crypto library"**
- **Cause:** Runtime image doesn't match build image
- **Fix:** Use `elixir:1.17-alpine` for both build and runtime stages

**"environment variable DATABASE_URL is missing"**
- **Cause:** .env file not present or incorrect permissions
- **Fix:** Check `.env` exists in `/home/deploy/urielm/` and `chmod 600 .env`

**"database postgres does not exist"**
- **Cause:** Trying to run `mix ecto.create` with Digital Ocean managed database
- **Fix:** Skip `ecto.create`, run only `ecto.migrate`

**"TLS client: Unknown CA"**
- **Cause:** Missing or incorrect SSL certificate configuration
- **Fix:** Ensure `config/runtime.exs` has `ssl: [cacertfile: "/etc/ssl/certs/ca-certificate.crt"]`

### Port already in use

```bash
# Check what's using port 4000
sudo ss -tlnp | grep 4000

# If old systemd service is still running
sudo systemctl stop urielm
sudo systemctl disable urielm

# Then restart Docker container
docker-compose up -d
```

### Database connection issues

```bash
# Test database connection from container
docker-compose exec web bin/urielm eval "Urielm.Repo.query!(\"SELECT 1\")"
```

### Rebuild from scratch

```bash
# Remove containers and images
docker-compose down
docker rmi urielm:latest

# Rebuild
docker-compose up -d --build
```

## Key Lessons Learned

1. **Runtime image must match build image** - Using different Alpine versions causes OpenSSL/crypto NIF errors
2. **Digital Ocean uses defaultdb not postgres** - Skip `mix ecto.create`, run migrations directly
3. **SSL certificate required** - Must configure `cacertfile` in runtime.exs, connection string `?sslmode=require` alone is not enough
4. **Migrations in releases** - Need Release module with `Urielm.Release.migrate()` since Mix isn't available in production builds
5. **.env file security** - Use `chmod 600` to protect environment variables
6. **Health checks** - Docker compose health checks help ensure container is ready before routing traffic

## Image Size Evolution

- **Target:** alpine:3.18 runtime (61MB) ❌ Failed with crypto errors
- **With openssl-dev:** Still failed ❌
- **Final:** elixir:1.17-alpine runtime (~150MB) ✅ Works

Trade-off: Larger image size for guaranteed compatibility.

## Comparison: Docker vs Systemd

**Docker Advantages:**
- Consistent environment (dev = prod)
- No dependency management on server
- Easy rollback (docker run previous tag)
- Portable across hosting platforms

**Docker Disadvantages:**
- Larger disk usage (~150MB per image)
- Slightly more complex troubleshooting
- Need to learn Docker concepts

**Systemd Advantages:**
- Smaller disk footprint
- Direct access to code
- Familiar to sysadmins

**Systemd Disadvantages:**
- Environment drift (local vs prod)
- Manual dependency management
- Harder rollbacks

## Production Checklist

- ✅ Docker and docker-compose installed on server
- ✅ deploy user in docker group
- ✅ Repository cloned to /home/deploy/urielm
- ✅ .env file created with all required variables
- ✅ .env file permissions set to 600
- ✅ CA certificate in Dockerfile (if using DO managed database)
- ✅ config/runtime.exs configured with SSL certificate path
- ✅ lib/urielm/release.ex exists for migrations
- ✅ Cloudflare DNS records point to droplet IP
- ✅ Cloudflare SSL mode set to Flexible
- ✅ Cloudflare origin rule rewrites port to 4000
- ✅ Container built and started via docker-compose
- ✅ Migrations run successfully
- ✅ Site accessible at https://urielm.dev
- ✅ Old systemd service stopped (if migrating from systemd)

## Next Steps

1. Set up automated deployments via GitHub Actions
2. Implement image tagging strategy (git commit hash or timestamp)
3. Set up container monitoring (Prometheus + Grafana)
4. Configure automated backups for database
5. Set up log aggregation (ELK stack or similar)
6. Implement blue-green deployment for zero downtime

---

**Deployment Date:** December 4, 2025
**Docker Version:** 29.1.2
**Docker Compose Version:** 5.0.0
**Image Size:** ~150MB
**Repository:** https://github.com/tacit7/urielm.git
