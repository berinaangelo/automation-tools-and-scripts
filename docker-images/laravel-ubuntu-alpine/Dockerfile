# syntax=docker/dockerfile:1

# ---- Frontend build stage --------------------------------------------------
# node:20-slim (Debian/glibc), not node:20-alpine — avoids the npm optional-
# dependency bug (npm/cli#4828) where esbuild/rollup's musl-native binaries
# don't always resolve when the lockfile was generated on a non-musl machine.
# Discarded after `npm run build`, so it has no effect on the final image.
FROM node:20-slim AS frontend

WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

# ---- PHP application stage --------------------------------------------------
FROM php:8.4-fpm-alpine AS app

RUN apk add --no-cache \
        nginx \
        supervisor \
        sqlite \
        sqlite-dev \
        libzip-dev \
        libpng-dev \
        libjpeg-turbo-dev \
        freetype-dev \
        icu-dev \
        oniguruma-dev \
        libxml2-dev \
    && apk add --no-cache --virtual .build-deps $PHPIZE_DEPS linux-headers \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" \
        pdo_mysql \
        pdo_sqlite \
        gd \
        zip \
        intl \
        bcmath \
        mbstring \
        xml \
        dom \
        simplexml \
        opcache \
        pcntl \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del .build-deps

WORKDIR /var/www/html

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --optimize-autoloader

COPY . .
COPY --from=frontend /app/public/build ./public/build

RUN composer dump-autoload --no-dev --optimize \
    && mkdir -p storage/framework/cache storage/framework/sessions storage/framework/views storage/logs bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache database \
    && chmod -R ug+rwx storage bootstrap/cache database

COPY docker/php/local.ini /usr/local/etc/php/conf.d/local.ini
COPY docker/nginx/ /etc/nginx/axiom/
COPY docker/supervisor/ /etc/supervisor/axiom/
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 80 8080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
