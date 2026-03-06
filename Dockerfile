# Stage 1: Build Node assets
FROM node:20 AS node-builder

WORKDIR /var/www

COPY package*.json ./
COPY vite.config.js ./
COPY resources ./resources

RUN npm install
RUN npm run build

# Stage 2: PHP + Laravel
FROM php:8.2-fpm

WORKDIR /var/www

# Install system dependencies
RUN apt-get update && apt-get install -y \
  git \
  unzip \
  libzip-dev \
  zip \
  libpq-dev \
  curl \
  && docker-php-ext-install pdo pdo_pgsql pdo_mysql zip \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Install composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy Laravel app
COPY . .

# Copy built frontend assets from node-builder
COPY --from=node-builder /var/www/public/build ./public/build

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader

# Optimize Laravel
RUN php artisan config:clear
RUN php artisan cache:clear
RUN php artisan route:clear
RUN php artisan view:clear
RUN php artisan optimize

# Fix permissions
RUN chmod -R 775 storage bootstrap/cache

# Optional: SQLite if you use it
RUN touch database/database.sqlite

# Expose port for Render
EXPOSE 10000

# Start PHP-FPM + Laravel server
CMD php artisan serve --host=0.0.0.0 --port=10000
