#!/bin/bash
set -e

# Configuration
IMAGE="urielm"
TAG=$(date +%Y%m%d_%H%M%S)
SERVER="deploy@167.172.194.233"
SSH_KEY="$HOME/.ssh/tacit7"
REMOTE_PATH="/home/deploy/urielm"

echo "======================================"
echo "  Docker Deployment - urielm.dev"
echo "======================================"
echo ""

# Build image
echo "→ Building Docker image ${IMAGE}:${TAG}..."
docker build -t ${IMAGE}:${TAG} -t ${IMAGE}:latest .

echo "→ Saving image to tarball..."
docker save ${IMAGE}:${TAG} | gzip > /tmp/${IMAGE}_${TAG}.tar.gz

echo "→ Uploading image to server..."
scp -i ${SSH_KEY} /tmp/${IMAGE}_${TAG}.tar.gz ${SERVER}:/tmp/

echo "→ Loading image on server..."
ssh -i ${SSH_KEY} ${SERVER} << EOF
  set -e

  # Load new image
  gunzip -c /tmp/${IMAGE}_${TAG}.tar.gz | docker load
  docker tag ${IMAGE}:${TAG} ${IMAGE}:latest

  # Navigate to app directory
  cd ${REMOTE_PATH}

  # Stop old container
  docker-compose down || true

  # Start new container
  docker-compose up -d

  # Wait for container to be healthy
  echo "→ Waiting for container to start..."
  sleep 5

  # Run migrations
  echo "→ Running database migrations..."
  docker-compose exec -T web bin/urielm eval "Urielm.Release.migrate()"

  # Check status
  docker-compose ps

  # Cleanup
  rm /tmp/${IMAGE}_${TAG}.tar.gz

  # Prune old images (keep last 3)
  docker image prune -f
EOF

# Cleanup local tarball
rm /tmp/${IMAGE}_${TAG}.tar.gz

echo ""
echo "✓ Deployment complete!"
echo "  Image: ${IMAGE}:${TAG}"
echo "  URL: https://urielm.dev"
echo ""
echo "To rollback, run:"
echo "  ssh -i ${SSH_KEY} ${SERVER} 'cd ${REMOTE_PATH} && docker-compose down && docker run -d -p 4000:4000 --env-file .env ${IMAGE}:PREVIOUS_TAG'"
