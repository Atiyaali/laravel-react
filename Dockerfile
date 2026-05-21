# ---------- Builder Stage ----------
FROM php:7.4-fpm AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    git zip unzip curl nodejs npm \
    libzip-dev libpng-dev libonig-dev libicu-dev libxml2-dev \
    libjpeg-dev libfreetype6-dev \
 && docker-php-ext-configure gd --with-jpeg --with-freetype \
 && docker-php-ext-install -j$(nproc) \
        pdo_mysql mbstring exif pcntl bcmath gd intl zip \
 && rm -rf /var/lib/apt/lists/*

# Composer
COPY --from=composer:2.6 /usr/bin/composer /usr/bin/composer

WORKDIR /app

# ======================
# 1. DEPENDENCIES ONLY
# ======================
COPY composer.json composer.lock ./
# Also copy any classmap directories used by composer autoload
COPY database/seeders ./database/seeders
COPY database/factories ./database/factories
RUN composer install \
    --no-dev \
    --prefer-dist \
    --no-scripts \
    --no-interaction \
    --no-progress \
    --optimize-autoloader

COPY package.json package-lock.json ./
RUN npm install --legacy-peer-deps

# ======================
# 2. FULL SOURCE CODE
# ======================
COPY . .

# ======================
# 3. BUILD FRONTEND
# ======================
RUN npm run dev || npm run production

# ---------- Final Stage (final)) ----------
# ---------- Final Stage (testing) ----------
FROM php:7.4-fpm

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    netcat-traditional \
    libzip-dev libpng-dev libonig-dev libicu-dev libxml2-dev \
    libjpeg-dev libfreetype6-dev \
 && docker-php-ext-configure gd --with-jpeg --with-freetype \
 && docker-php-ext-install -j$(nproc) \
        pdo_mysql mbstring exif pcntl bcmath gd intl zip \
 && docker-php-ext-enable gd intl \
 && rm -rf /var/lib/apt/lists/*
# ---------- Final Stage (testing) ----------
WORKDIR /app

COPY --from=builder /app /app

# Entrypoint
COPY .docker/install-php.sh /usr/local/bin/install-php.sh
RUN sed -i 's/\r$//' /usr/local/bin/install-php.sh \
    && chmod +x /usr/local/bin/install-php.sh

RUN sed -i 's|listen = 127.0.0.1:9000|listen = 9000|' /usr/local/etc/php-fpm.d/www.conf

# Permissions
RUN chown -R www-data:www-data /app \
 && chmod -R 775 /app/storage \
 && chmod -R 775 /app/bootstrap/cache

EXPOSE 9000

USER www-data

ENTRYPOINT ["/usr/local/bin/install-php.sh"]
CMD ["php-fpm"]