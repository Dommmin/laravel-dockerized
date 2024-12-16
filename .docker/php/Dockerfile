FROM php:8.2-fpm-alpine

WORKDIR /var/www

ARG UID=1000
ARG GID=1000

RUN apk update && apk add --no-cache \
    build-base \
    autoconf \
    git \
    curl \
    libpng-dev \
    libjpeg-turbo-dev \
    libwebp-dev \
    libzip-dev \
    freetype-dev \
    imagemagick-dev \
    linux-headers \
    postgresql-dev \
    nodejs \
    npm \
    shadow \
    bash

RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install pdo pdo_mysql zip bcmath pcntl

RUN pecl install redis imagick \
    && docker-php-ext-enable redis imagick

RUN usermod -u ${UID} www-data \
    && groupmod -g ${GID} www-data \
    && chown -R www-data:www-data /var/www

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

COPY . /var/www
COPY ./.docker/php/php-dev.ini /usr/local/etc/php/conf.d/php.ini

RUN composer install --prefer-dist --no-scripts --no-progress --no-suggest --optimize-autoloader \
    && chmod -R 775 /var/www/storage /var/www/bootstrap/cache

RUN npm install

COPY ./.docker/php/start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

USER www-data

CMD ["/usr/local/bin/start.sh"]
