# ============================
# Stage 1: Node build (Vite assets)
# ============================
FROM node:20 AS node-builder

WORKDIR /var/www

# Install build tools for esbuild
RUN apt-get update && apt-get install -y python3 build-essential libc6-dev

# Copy package files
COPY package*.json ./
COPY vite.config.js ./

# Copy resources for build
COPY resources ./resources

# Install node dependencies
RUN npm install

# Build Vite assets
RUN npm run build

# ============================
# Stage 2: PHP + Laravel
# ============================
FROM php:8.2-fpm

WORKDIR /var/www

# Install PHP extensions for Laravel + PostgreSQL
RUN apt-get update && apt-get install -y \
  libpq-dev \
  unzip \
  git \
  curl \
  libzip-dev \
  zip \
  && docker-php-ext-install pdo pdo_pgsql zip

# Copy Laravel files
COPY . .

# Copy built assets from node stage
COPY --from=node-builder /var/www/public/build ./public/build

# Set permissions
RUN chown -R www-data:www-data /var/www \
  && chmod -R 775 storage bootstrap/cache

# Install composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader

# Create empty SQLite (if needed)
RUN touch database/database.sqlite

# Expose port and start PHP-FPM
EXPOSE 9000
CMD ["php-fpm"]
