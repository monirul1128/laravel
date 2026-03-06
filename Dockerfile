# ============================
# Stage 1: Node build (Vite assets)
# ============================
FROM node:20 AS node-builder

WORKDIR /var/www

# Install build tools for esbuild (Python + build-essential)
RUN apt-get update && apt-get install -y python3 build-essential libc6-dev

# Copy only package files first for caching
COPY package*.json ./
COPY vite.config.js ./

# Copy resources needed for build
COPY resources ./resources

# Install dependencies & build
RUN npm install --legacy-peer-deps
RUN npm run build

# ============================
# Stage 2: PHP + Laravel
# ============================
FROM php:8.2-fpm

WORKDIR /var/www

# Install system dependencies & PHP extensions
RUN apt-get update && apt-get install -y \
  libpq-dev \
  unzip \
  git \
  curl \
  libzip-dev \
  zip \
  && docker-php-ext-install pdo pdo_pgsql zip

# Copy Laravel project files
COPY . .

# Copy built Vite assets from Node stage
COPY --from=node-builder /var/www/public/build ./public/build

# Set permissions for storage & cache
RUN chown -R www-data:www-data /var/www \
  && chmod -R 775 storage bootstrap/cache

# Install composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader

# Optional: Create SQLite file if your app uses it
RUN touch database/database.sqlite

# Expose PHP-FPM port
EXPOSE 9000

# Start PHP-FPM
CMD ["php-fpm"]
