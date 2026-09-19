#!/bin/bash
set -e

echo "🚀 Starting deployment..."

# Pull latest code
echo "📥 Pulling latest code from git..."
git pull

# Install/update dependencies
echo "📦 Installing Elixir dependencies..."
mix deps.get --only prod

echo "📦 Installing Node dependencies..."
cd assets && npm ci && cd ..

# Build assets
echo "🎨 Building Tailwind CSS..."
MIX_ENV=prod mix tailwind urielm --minify

echo "🎨 Building JavaScript..."
cd assets && node build.js --deploy && cd ..

echo "🎨 Digesting static assets..."
MIX_ENV=prod mix phx.digest

# Restart service
echo "🔄 Restarting application..."
sudo systemctl restart urielm

echo "✅ Deployment complete!"
echo "📊 Checking service status..."
sudo systemctl status urielm --no-pager

echo ""
echo "🌐 Your app should now be live at https://urielm.dev"
