# ============================
# Stage 1 – Node Build (Vite)
# ============================
FROM node:20-alpine AS node-builder

WORKDIR /app

COPY package*.json ./
RUN npm install --legacy-peer-deps

COPY . .

# Vite build
RUN npm run build


# ============================
# Stage 2 – PHP + Laravel
# ============================
FROM php:8.2-fpm-alpine

WORKDIR /var/www

# Required packages
RUN apk add --no-cache \
  git curl zip unzip nodejs npm libpng-dev libzip-dev

# PHP extensions
RUN docker-php-ext-install pdo pdo_mysql zip

# Copy project
COPY . .

# Copy Vite build from stage 1
COPY --from=node-builder /app/public/build ./public/build

# Composer install
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-dev --optimize-autoloader

# Permissions
RUN chmod -R 775 storage bootstrap/cache

EXPOSE 10000

CMD php artisan migrate --force && \
  php artisan config:cache && \
  php artisan route:cache && \
  php artisan serve --host=0.0.0.0 --port=10000


# example
RUN apt-get update && apt-get install -y libpq-dev \
  && docker-php-ext-install pdo_pgsql
