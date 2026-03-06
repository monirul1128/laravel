# =====================================================
# Stage 1: Node Build (Vite Assets)
# =====================================================
FROM node:20-bullseye AS node-builder

WORKDIR /var/www

# Install system tools for node build
RUN apt-get update && apt-get install -y python3 build-essential

# Copy package files
COPY package*.json ./
COPY vite.config.js ./

# Install dependencies
RUN npm install --legacy-peer-deps

# Copy source code for build
COPY resources ./resources
COPY public ./public

# Build assets
RUN npm run build


# =====================================================
# Stage 2: PHP + Laravel (Production)
# =====================================================
FROM php:8.2-fpm-bullseye

WORKDIR /var/www

# Install required system packages
RUN apt-get update && apt-get install -y \
  git \
  curl \
  unzip \
  libpq-dev \
  libzip-dev \
  zip \
  && docker-php-ext-install pdo pdo_pgsql zip

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copy application
COPY . .

# Copy built assets from node stage
COPY --from=node-builder /var/www/public/build ./public/build

# Install Laravel dependencies
RUN composer install --no-dev --optimize-autoloader

# Fix permissions
RUN chmod -R 775 storage bootstrap/cache

# Generate optimized config
RUN php artisan config:cache \
  && php artisan route:cache \
  && php artisan view:cache

# Expose port (Render auto detects)
EXPOSE 10000

CMD php artisan serve --host=0.0.0.0 --port=10000
