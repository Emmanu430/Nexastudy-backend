# Laravel on Render: PHP 8.4 with Apache
# (your config uses the Pdo\Mysql class, which needs PHP 8.4 or newer)
FROM php:8.4-apache

# 1. System packages + the PHP extensions Laravel needs that aren't built in
RUN apt-get update && apt-get install -y --no-install-recommends \
      git unzip libzip-dev \
    && docker-php-ext-install pdo_mysql zip bcmath \
    && a2enmod rewrite \
    && rm -rf /var/lib/apt/lists/*

# 2. Composer, copied from the official Composer image
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# 3. Apache setup
#    - serve Laravel's public/ folder, not the project root
#    - let public/.htaccess rewrite every URL to index.php
#    - listen on 10000, Render's default port
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf \
    && sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf \
    && sed -ri 's/Listen 80/Listen 10000/' /etc/apache2/ports.conf \
    && sed -ri 's/<VirtualHost \*:80>/<VirtualHost *:10000>/' /etc/apache2/sites-available/000-default.conf

WORKDIR /var/www/html

# 4. Install PHP packages first. Docker caches this layer, so rebuilds are fast
#    unless composer.json or composer.lock change.
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist --no-interaction

# 5. Copy the app, build the autoloader, make Laravel's writable folders writable
COPY . .
RUN composer dump-autoload --optimize --no-dev --no-scripts \
    && mkdir -p storage/framework/cache storage/framework/sessions storage/framework/views storage/logs bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache

EXPOSE 10000

# 6. On start: cache the config (this reads the environment variables you set in Render), then run Apache
CMD ["sh", "-c", "php artisan config:cache && apache2-foreground"]
