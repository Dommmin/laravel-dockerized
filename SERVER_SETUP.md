# VPS Server Setup Guide

This guide will help you set up your VPS for Laravel deployment with zero downtime.
## 0. Create User (optional—you can use your non-root user)

```bash
# Create user with proper primary group
sudo adduser deployer --ingroup www-data
sudo usermod -aG sudo deployer

# Secure sudo access
echo "deployer ALL=(ALL:ALL) ALL" | sudo tee /etc/sudoers.d/deployer
echo 'Defaults:deployer !requiretty' | sudo tee -a /etc/sudoers.d/deployer  

# Fix home directory permissions
sudo chmod 711 /home/deployer
```

## 1. Initial Server Setup

```bash
# Update the system
apt update
sudo apt install -y nginx php-fpm mariadb-server ufw fail2ban acl
sudo apt install -y php8.3-{cli,common,curl,xml,mbstring,zip,mysql,gd,intl,bcmath,redis,imagick,opcache,tokenizer,dom,fileinfo}
sudo systemctl restart php8.3-fpm
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
    server_name your-domain.com;
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

    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot|webp)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
        log_not_found off;
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
nano /etc/php/8.3/fpm/pool.d/www.conf
```
### Replace with the following configuration:
```ini
[www]
user = deployer
group = www-data

listen = /var/run/php/php8.3-fpm.sock
listen.owner = www-data
listen.group = www-data
listen.mode = 0660

php_admin_value[open_basedir] = /home/deployer/laravel/current/:/home/deployer/laravel/releases/:/home/deployer/laravel/shared/:/tmp/:/var/lib/php/sessions/
php_admin_value[disable_functions] = "exec,passthru,shell_exec,system,proc_open,popen"
php_admin_flag[expose_php] = off
```

## 4. Update PHP Configuration
```bash
# Run
nano /etc/php/8.3/fpm/php.ini
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

Add variable for .env production file
- `ENV_FILE`: The contents of your .env file

## 8. Set Up SSL with Let's Encrypt (Optional but Recommended)

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Obtain SSL certificate
sudo certbot --nginx -d your-domain.com

# Set up auto-renewal
sudo systemctl status certbot.timer
```

## 9. Final Steps

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
