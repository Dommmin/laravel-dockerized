#!/bin/bash
set -eo pipefail

if [ "$(id -u)" = "0" ]; then
    chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache
fi

if [ ! -d "node_modules" ] && [ -f "package.json" ]; then
    echo "Installing Node dependencies..."
    npm install
fi

echo "Starting Supervisor..."
exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
