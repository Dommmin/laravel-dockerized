FROM dommin/php-8.4-fpm:latest

COPY docker/php/php.ini /usr/local/etc/php/conf.d/custom.ini
COPY docker/php/www.conf /usr/local/etc/php-fpm.d/www.conf

COPY docker/start.sh /usr/local/bin/start.sh
COPY docker/supervisord.conf /etc/supervisor/supervisord.conf

USER root

ARG USER_ID=1000
ARG GROUP_ID=1000

RUN usermod -u ${USER_ID} www-data \
    && groupmod -g ${GROUP_ID} www-data \
    && chmod +x /usr/local/bin/start.sh \
    && mkdir -p /var/log/supervisor /var/run/supervisor \
    && chown -R www-data:www-data /var/www /var/log/supervisor /var/run/supervisor

WORKDIR /var/www
USER www-data

EXPOSE 9000
