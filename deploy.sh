#!/bin/bash

set -e
set -o pipefail

APP_USER="deployer"
APP_GROUP="www-data"
APP_BASE="/home/$APP_USER/laravel"
RELEASES_DIR="$APP_BASE/releases"
SHARED_DIR="$APP_BASE/shared"
CURRENT_LINK="$APP_BASE/current"
NOW=$(date +%Y-%m-%d-%H%M%S)-$(openssl rand -hex 3)
RELEASE_DIR="$RELEASES_DIR/$NOW"
ARCHIVE_NAME="release.tar.gz"

# Load NVM and get current Node.js version
export NVM_DIR="/home/$APP_USER/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
NODE_VERSION=$(nvm current)
PM2="$NVM_DIR/versions/node/$NODE_VERSION/bin/pm2"

echo "▶️ Using Node.js version: $NODE_VERSION"
echo "▶️ PM2 path: $PM2"

# Verify PM2 exists
if [ ! -f "$PM2" ]; then
    echo "❌ PM2 not found at $PM2"
    exit 1
fi

echo "▶️ Create directories..."
mkdir -p "$RELEASES_DIR" "$SHARED_DIR/storage" "$SHARED_DIR/bootstrap_cache"

mkdir -p "$SHARED_DIR/storage/framework/"{views,cache,sessions}
mkdir -p "$SHARED_DIR/storage/logs"

echo "▶️ Unpacking release..."
mkdir -p "$RELEASE_DIR"
tar -xzf "$APP_BASE/$ARCHIVE_NAME" -C "$RELEASE_DIR"
rm -f "$APP_BASE/$ARCHIVE_NAME"

echo "▶️ Setting up symlinks..."
rm -rf "$RELEASE_DIR/storage"
ln -s "$SHARED_DIR/storage" "$RELEASE_DIR/storage"

rm -rf "$RELEASE_DIR/bootstrap/cache"
ln -s "$SHARED_DIR/bootstrap_cache" "$RELEASE_DIR/bootstrap/cache"

ln -sf "$SHARED_DIR/.env" "$RELEASE_DIR/.env"

echo "▶️ Optimizing application..."
cd "$RELEASE_DIR"
php artisan optimize:clear

# Reset opcache if available
if command -v opcache_reset &> /dev/null; then
    echo "▶️ Resetting OPcache..."
    php -r "opcache_reset();" || true
fi

# Reset Redis cache if available
if command -v redis-cli &> /dev/null; then
    echo "▶️ Flushing Redis cache..."
    redis-cli FLUSHALL || true
fi

php artisan optimize
php artisan storage:link

echo "▶️ Running database migrations..."
php artisan migrate --force

echo "▶️ Managing SSR server with PM2..."
# Stop current SSR server gracefully
$PM2 stop laravel 2>/dev/null || echo "No previous SSR server to stop"

# Update symlink first
echo "▶️ Updating current symlink..."
ln -sfn "$RELEASE_DIR" "$CURRENT_LINK"

echo "▶️ Restarting PHP-FPM to apply new code..."
if sudo systemctl restart php8.3-fpm; then
    echo "✅ PHP-FPM restarted successfully"
else
    echo "❌ Failed to restart PHP-FPM!"
    exit 1
fi

# Start SSR server from new release
cd "$CURRENT_LINK"
echo "▶️ Starting SSR server..."
$PM2 delete laravel 2>/dev/null || true
$PM2 start ecosystem.config.json

# Save PM2 process list
$PM2 save

# Wait a moment for SSR to start
sleep 3

# Verify SSR is running
echo "▶️ Verifying SSR server..."
if ! $PM2 describe laravel &>/dev/null; then
    echo "❌ SSR server failed to start!"
    exit 1
fi

echo "▶️ Cleaning old releases (keeping 5 latest)..."
cd "$RELEASES_DIR"
ls -dt */ | tail -n +6 | xargs -r rm -rf

echo "▶️ Current deployment status:"
$PM2 list

echo "▶️ Restarting Supervisor services..."
sudo supervisorctl restart all

echo "▶️ Checking health status..."
curl http://localhost/health

echo "✅ Deployment successful: $NOW"
exit 0
