# Zero Downtime Deployment for Laravel with GitHub Actions

# This guide will help you set up a zero downtime deployment for your Laravel application using GitHub Actions on a VPS. The setup includes Nginx, PHP-FPM, and MariaDB, along with proper configurations for security and performance.

## What is Zero Downtime Deployment?
Zero downtime deployment means updating your app without users noticing any interruption — the site stays online and responsive while the new version is being deployed.

## 0. Create User (optional—you can use your non-root user)

```bash
# Create user with proper primary group
sudo adduser deployer --ingroup www-data
sudo usermod -aG sudo deployer

# Secure sudo access
echo "deployer ALL=(ALL) NOPASSWD: /usr/bin/supervisorctl, /usr/bin/systemctl restart php8.3-fpm, /usr/bin/systemctl restart nginx" | sudo tee /etc/sudoers.d/deployer-services

# Fix home directory permissions
sudo chmod 711 /home/deployer
```

## 1. Initial Server Setup
### 1.1 Installation required packages
```bash
# Update the system
sudo apt update

sudo apt install -y nginx php-fpm mariadb-server ufw fail2ban acl supervisor
sudo apt install -y php8.3-{cli,common,curl,xml,mbstring,zip,mysql,gd,intl,bcmath,redis,imagick,opcache,tokenizer,dom,fileinfo}
sudo systemctl restart php8.3-fpm
```
### 1.2 Install Node + PM2 for SSR (optional)
```
# Download and install nvm:
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

# in lieu of restarting the shell
\. "$HOME/.nvm/nvm.sh"

# Download and install Node.js:
nvm install 22

# Install PM2
npm install -g pm2

# Configure PM2
pm2 startup
pm2 save
```

## 2. Configure Nginx

Create a new Nginx configuration file:

```bash
sudo nano /etc/nginx/sites-available/laravel
```

Add the following configuration:

```nginx configuration
server {
    listen 80;
    listen [::]:80;
    server_name __;
    root /home/deployer/laravel/current/public;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "strict-origin-when-cross-origin";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header Permissions-Policy "geolocation=(), midi=(), sync-xhr=(), microphone=(), camera=(), magnetometer=(), gyroscope=(), fullscreen=(self), payment=()";
    server_tokens off;

    index index.php;
    charset utf-8;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    client_max_body_size 100M;

     # Cache static files
    location ~* \.(?:ico|css|js|gif|jpe?g|png|woff2?|eot|ttf|svg|otf)$ {
        expires 1y;
        access_log off;
        add_header Cache-Control "public, no-transform";
        add_header X-Content-Type-Options "nosniff";
        try_files $uri =404;
    }

    # Cache fonts
    location ~* \.(woff2?|eot|ttf|otf)$ {
        expires 1y;
        access_log off;
        add_header Cache-Control "public, no-transform";
        add_header X-Content-Type-Options "nosniff";
        try_files $uri =404;
    }

    # Cache images
    location ~* \.(jpg|jpeg|png|gif|ico|webp)$ {
        expires 1y;
        access_log off;
        add_header Cache-Control "public, no-transform";
        add_header X-Content-Type-Options "nosniff";
        try_files $uri =404;
    }
    
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ ^/index\.php(/|$) {
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
        
        fastcgi_buffer_size 128k;
        fastcgi_buffers 4 256k;
        fastcgi_busy_buffers_size 256k;
        fastcgi_read_timeout 300;
        
        fastcgi_hide_header X-Powered-By;
    }

    location ~ /\.(?!well-known).* {
        deny all;
        access_log off;
        log_not_found off;
    }

    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml application/json application/javascript application/xml+rss application/atom+xml image/svg+xml;
    gzip_min_length 1024;
    gzip_buffers 16 8k;
    gzip_disable "MSIE [1-6]\.";
}
```

Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/laravel /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

## 3. Update PHP-FPM Configuration

```bash
# Run
sudo nano /etc/php/8.3/fpm/pool.d/www.conf
```
### Replace it with the following configuration and restart PHP-FPM:
```ini
[www]
user = deployer
group = www-data

listen = /var/run/php/php8.3-fpm.sock
listen.owner = www-data
listen.group = www-data
listen.mode = 0660

pm = dynamic
pm.max_children = 20
pm.start_servers = 4
pm.min_spare_servers = 2
pm.max_spare_servers = 6
pm.process_idle_timeout = 10s
pm.max_requests = 500

php_admin_value[open_basedir] = /home/deployer/laravel/current/:/home/deployer/laravel/releases/:/home/deployer/laravel/shared/:/tmp/:/var/lib/php/sessions/
php_admin_value[disable_functions] = "exec,passthru,shell_exec,system,proc_open,popen"
php_admin_flag[expose_php] = off
php_admin_value[memory_limit] = 256M
php_admin_value[max_execution_time] = 120

php_admin_value[realpath_cache_size] = 4096K
php_admin_value[realpath_cache_ttl] = 600
php_admin_value[opcache.enable] = 1
php_admin_value[opcache.memory_consumption] = 128
```

## 4. Update PHP Configuration
```bash
# Run
sudo nano /etc/php/8.3/fpm/php.ini
```
### Replace it with the following configuration:
```ini
[PHP]
expose_php = Off
max_execution_time = 30
max_input_time = 60
memory_limit = 256M
error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT
display_errors = Off
display_startup_errors = Off
log_errors = On
error_log = /var/log/php8.3-fpm.log

opcache.enable=1
opcache.memory_consumption=256
opcache.interned_strings_buffer=32
opcache.max_accelerated_files=20000
opcache.validate_timestamps=0
opcache.revalidate_freq=0
opcache.enable_cli=0
opcache.jit_buffer_size=256M
opcache.jit=1235

realpath_cache_size=4096K
realpath_cache_ttl=600

session.gc_probability=1
session.gc_divisor=100
session.gc_maxlifetime=1440
session.save_handler = redis
session.save_path = "tcp://127.0.0.1:6379"

upload_max_filesize = 64M
post_max_size = 64M
file_uploads = On

max_input_vars = 5000
request_order = "GP"
variables_order = "GPCS"

[Date]
date.timezone = Europe/Warsaw
```

## 5. Set Up Directory Structure

```bash
# Create structure with proper permissions
sudo mkdir -p /home/deployer/laravel/{releases,shared}
sudo chown -R deployer:www-data /home/deployer/laravel
sudo chmod -R 2775 /home/deployer/laravel

# Shared folders setup
sudo mkdir -p /home/deployer/laravel/shared/storage/{app,framework,logs}
sudo mkdir -p /home/deployer/laravel/shared/storage/framework/{cache,sessions,views}
sudo chmod -R 775 /home/deployer/laravel/shared
sudo chmod -R 775 /home/deployer/laravel/shared/storage
sudo chown -R deployer:www-data /home/deployer/laravel/shared/storage

# Set ACL for future files
sudo setfacl -Rdm g:www-data:rwx /home/deployer/laravel
```

## 6. Set Up SSH Key for GitHub Actions (as deployer user)

```bash
# Create SSH directory
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Generate SSH key
ssh-keygen -t rsa -b 4096 -C "github-actions-deploy"

# Add public key to authorized_keys
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Display the private key
cat ~/.ssh/id_rsa
```

## 7. Add GitHub Secrets

Add the following secrets to your GitHub repository:

- `SSH_HOST`: Your VPS IP address or domain
- `SSH_USER`: Your VPS username
- `SSH_KEY`: The private SSH key generated above
- `SSH_PORT`: The SSH port (default is 22)

Add variable for .env production file
- `ENV_FILE`: The contents of your .env file
## 8. Configure Supervisor (queue, cron, etc.)

```bash
# Create Supervisor configuration file
sudo nano /etc/supervisor/conf.d/laravel.con
```

### Replace it with the following configuration:
```ini
[program:laravel-worker]
command=/usr/bin/php /home/deployer/laravel/current/artisan queue:work --timeout=3600 --tries=3 --sleep=3 --stop-when-empty
autostart=true
autorestart=true
user=deployer
numprocs=1
stdout_logfile=/home/deployer/laravel/shared/storage/logs/laravel-worker.log
stderr_logfile=/home/deployer/laravel/shared/storage/logs/laravel-worker.log

[program:laravel-cron]
command=/usr/bin/php /home/deployer/laravel/current/artisan schedule:run
autostart=true
autorestart=true
user=deployer
numprocs=1
stdout_logfile=/home/deployer/laravel/shared/storage/logs/laravel-cron.log
stderr_logfile=/home/deployer/laravel/shared/storage/logs/laravel-cron.log
```

```bash
# Start Supervisor
sudo supervisorctl start all
```

## 9. Set Up SSL with Let's Encrypt (Optional but Recommended)

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Obtain SSL certificate
sudo certbot --nginx -d your-domain.com

# Set up auto-renewal
sudo systemctl status certbot.timer
```

## 10. Install Redis (Optional)

```bash
# Install Redis
sudo apt install -y redis-server
sudo systemctl enable redis-server
sudo systemctl start redis-server
```

## 11. Final Steps

1. Push your code to the `main` branch to trigger the deployment.
2. Monitor the GitHub Actions workflow to ensure it completes successfully.
3. Check your website to verify the deployment.

## Troubleshooting

- **Permission Issues**: Ensure all directories have the correct ownership and permissions.
- **Nginx Errors**: Check the Nginx error logs with `sudo tail -f /var/log/nginx/error.log`.
- **PHP-FPM Errors**: Check the PHP-FPM error logs with `sudo tail -f /var/log/php8.3-fpm.log`.
- **Deployment Failures**: Check the GitHub Actions logs for detailed error messages.

## Conclusion
This guide provides a comprehensive setup for deploying Laravel applications on a VPS with zero downtime. By following these steps, you can ensure a smooth and efficient deployment process.
